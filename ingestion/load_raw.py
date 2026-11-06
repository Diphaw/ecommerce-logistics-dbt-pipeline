"""Load raw Olist CSV files into PostgreSQL (the "EL" of ELT).

Design notes:
    * Every source column lands as ``TEXT``; typing and cleaning belong to dbt staging.
    * Loads are idempotent: each table is truncated and reloaded in a single transaction,
      so a failed load never leaves a half-populated table.
    * ``TRUNCATE`` (rather than ``DROP``) keeps dbt views that depend on the tables intact.
    * The CSV header is validated against the contract in ``config.py`` to fail fast on
      upstream schema drift.

Usage:
    python -m ingestion.load_raw                       # load every table
    python -m ingestion.load_raw --tables orders customers
"""

from __future__ import annotations

import argparse
import io
import logging
import sys
from collections.abc import Iterator, Sequence

import pandas as pd
import psycopg2
from psycopg2 import sql
from psycopg2.extensions import connection as PgConnection

from ingestion.config import CHUNK_SIZE, RAW_SCHEMA, SOURCE_TABLES, DbConfig, SourceTable

logger = logging.getLogger("ingestion")


class SchemaDriftError(RuntimeError):
    """Raised when a CSV header does not match its declared contract."""


def read_chunks(table: SourceTable) -> Iterator[pd.DataFrame]:
    return pd.read_csv(
        table.path,
        dtype=str,
        encoding="utf-8-sig",  # strips the BOM present in some Olist files
        keep_default_na=False,
        na_values=[""],
        chunksize=CHUNK_SIZE,
    )


def validate_header(table: SourceTable) -> None:
    header = pd.read_csv(table.path, nrows=0, encoding="utf-8-sig").columns.tolist()
    if tuple(header) != table.columns:
        raise SchemaDriftError(
            f"{table.file_name}: expected columns {list(table.columns)}, found {header}"
        )


def ensure_table(cur: psycopg2.extensions.cursor, table: SourceTable) -> None:
    columns = sql.SQL(", ").join(
        sql.SQL("{} TEXT").format(sql.Identifier(col)) for col in table.columns
    )
    cur.execute(
        sql.SQL(
            "CREATE TABLE IF NOT EXISTS {}.{} ({}, _loaded_at TIMESTAMPTZ NOT NULL DEFAULT now())"
        ).format(sql.Identifier(RAW_SCHEMA), sql.Identifier(table.name), columns)
    )


def copy_chunk(
    cur: psycopg2.extensions.cursor, table: SourceTable, chunk: pd.DataFrame
) -> None:
    buffer = io.StringIO()
    chunk.to_csv(buffer, index=False, header=False, na_rep="")
    buffer.seek(0)
    cur.copy_expert(
        sql.SQL("COPY {}.{} ({}) FROM STDIN WITH (FORMAT csv)")
        .format(
            sql.Identifier(RAW_SCHEMA),
            sql.Identifier(table.name),
            sql.SQL(", ").join(sql.Identifier(col) for col in table.columns),
        )
        .as_string(cur),
        buffer,
    )


def load_table(conn: PgConnection, table: SourceTable) -> int:
    if not table.path.exists():
        raise FileNotFoundError(f"Source file not found: {table.path}")
    validate_header(table)

    rows_read = 0
    with conn, conn.cursor() as cur:  # `with conn` commits on success, rolls back on error
        ensure_table(cur, table)
        cur.execute(
            sql.SQL("TRUNCATE TABLE {}.{}").format(
                sql.Identifier(RAW_SCHEMA), sql.Identifier(table.name)
            )
        )
        for chunk in read_chunks(table):
            copy_chunk(cur, table, chunk)
            rows_read += len(chunk)

        cur.execute(
            sql.SQL("SELECT count(*) FROM {}.{}").format(
                sql.Identifier(RAW_SCHEMA), sql.Identifier(table.name)
            )
        )
        rows_loaded = cur.fetchone()[0]
        if rows_loaded != rows_read:
            raise RuntimeError(
                f"{table.name}: row count mismatch (read={rows_read}, loaded={rows_loaded})"
            )
    return rows_loaded


def select_tables(names: Sequence[str] | None) -> list[SourceTable]:
    if not names:
        return list(SOURCE_TABLES)
    by_name = {t.name: t for t in SOURCE_TABLES}
    unknown = sorted(set(names) - by_name.keys())
    if unknown:
        raise SystemExit(f"Unknown table(s): {', '.join(unknown)}. Valid: {', '.join(by_name)}")
    return [by_name[name] for name in names]


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument(
        "--tables",
        nargs="+",
        metavar="TABLE",
        help="Subset of tables to load (default: all).",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)-7s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    args = parse_args(argv)
    tables = select_tables(args.tables)
    config = DbConfig.from_env()

    conn = psycopg2.connect(
        user=config.user,
        password=config.password,
        host=config.host,
        port=config.port,
        dbname=config.dbname,
    )
    try:
        with conn, conn.cursor() as cur:
            cur.execute(
                sql.SQL("CREATE SCHEMA IF NOT EXISTS {}").format(sql.Identifier(RAW_SCHEMA))
            )

        total = 0
        for table in tables:
            rows = load_table(conn, table)
            logger.info("Loaded %-30s %10s rows", f"{RAW_SCHEMA}.{table.name}", f"{rows:,}")
            total += rows
        logger.info("Done: %d tables, %s rows", len(tables), f"{total:,}")
    except Exception:
        logger.exception("Ingestion failed")
        return 1
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())

