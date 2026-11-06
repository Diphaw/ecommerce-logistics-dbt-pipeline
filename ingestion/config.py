"""Configuration and source-file contracts for the ingestion layer."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"
RAW_SCHEMA = "raw"
CHUNK_SIZE = 100_000


@dataclass(frozen=True)
class DbConfig:
    user: str
    password: str
    host: str
    port: int
    dbname: str

    @classmethod
    def from_env(cls) -> DbConfig:
        load_dotenv(PROJECT_ROOT / ".env")
        missing = [key for key in ("DB_USER", "DB_PASSWORD", "DB_NAME") if not os.getenv(key)]
        if missing:
            raise OSError(f"Missing required environment variables: {', '.join(missing)}")
        return cls(
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
            host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "5435")),
            dbname=os.environ["DB_NAME"],
        )


@dataclass(frozen=True)
class SourceTable:
    name: str
    file_name: str
    columns: tuple[str, ...]

    @property
    def path(self) -> Path:
        return RAW_DATA_DIR / self.file_name


# Source column names are kept exactly as delivered (including upstream typos such as
# ``product_name_lenght``). Renaming and typing happen in the dbt staging layer.
SOURCE_TABLES: tuple[SourceTable, ...] = (
    SourceTable(
        name="customers",
        file_name="olist_customers_dataset.csv",
        columns=(
            "customer_id",
            "customer_unique_id",
            "customer_zip_code_prefix",
            "customer_city",
            "customer_state",
        ),
    ),
    SourceTable(
        name="geolocation",
        file_name="olist_geolocation_dataset.csv",
        columns=(
            "geolocation_zip_code_prefix",
            "geolocation_lat",
            "geolocation_lng",
            "geolocation_city",
            "geolocation_state",
        ),
    ),
    SourceTable(
        name="order_items",
        file_name="olist_order_items_dataset.csv",
        columns=(
            "order_id",
            "order_item_id",
            "product_id",
            "seller_id",
            "shipping_limit_date",
            "price",
            "freight_value",
        ),
    ),
    SourceTable(
        name="order_payments",
        file_name="olist_order_payments_dataset.csv",
        columns=(
            "order_id",
            "payment_sequential",
            "payment_type",
            "payment_installments",
            "payment_value",
        ),
    ),
    SourceTable(
        name="order_reviews",
        file_name="olist_order_reviews_dataset.csv",
        columns=(
            "review_id",
            "order_id",
            "review_score",
            "review_comment_title",
            "review_comment_message",
            "review_creation_date",
            "review_answer_timestamp",
        ),
    ),
    SourceTable(
        name="orders",
        file_name="olist_orders_dataset.csv",
        columns=(
            "order_id",
            "customer_id",
            "order_status",
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ),
    ),
    SourceTable(
        name="products",
        file_name="olist_products_dataset.csv",
        columns=(
            "product_id",
            "product_category_name",
            "product_name_lenght",
            "product_description_lenght",
            "product_photos_qty",
            "product_weight_g",
            "product_length_cm",
            "product_height_cm",
            "product_width_cm",
        ),
    ),
    SourceTable(
        name="sellers",
        file_name="olist_sellers_dataset.csv",
        columns=(
            "seller_id",
            "seller_zip_code_prefix",
            "seller_city",
            "seller_state",
        ),
    ),
    SourceTable(
        name="product_category_translation",
        file_name="product_category_name_translation.csv",
        columns=(
            "product_category_name",
            "product_category_name_english",
        ),
    ),
)

