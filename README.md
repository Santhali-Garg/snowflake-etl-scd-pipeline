# Snowflake ETL + SCD Type 2 Pipeline

A hands-on Snowflake ETL project demonstrating data ingestion, validation, transformation, CDC using Streams, and SCD Type 2 processing.

## Project Flow

```text
CSV File
   ↓
Snowflake Stage
   ↓
CUSTOMER_RAW
   ↓
Validation & Transformation
   ↓
CUSTOMER_STG
   ↓
Stream / CDC
   ↓
SCD Type 2 Processing
   ↓
CUSTOMER_DIM
```

## Snowflake Objects

| Object              | Purpose                                   |
| ------------------- | ----------------------------------------- |
| CUSTOMER_STAGE      | Landing area for incoming CSV files       |
| CUSTOMER_RAW        | Stores raw customer data                  |
| CUSTOMER_STG        | Stores cleaned/transformed data           |
| CUSTOMER_ERROR      | Stores records failing validation         |
| CUSTOMER_STG_STREAM | Captures changes in staging               |
| CITY_STATE          | Lookup table for city-to-state enrichment |
| CUSTOMER_DIM        | Final SCD Type 2 dimension                |
| CUSTOMER_SCD_TASK   | Automates SCD Type 2 processing           |

## SCD Type 2 Implementation

When a customer record changes:

1. The existing current record is identified.
2. The existing record is closed.
3. `END_DATE` is updated.
4. `IS_CURRENT` is changed to `FALSE`.
5. A new version of the customer is inserted.
6. The new record receives the current `EFFECTIVE_DATE`.
7. The new record remains current with `END_DATE = 9999-12-31`.

This preserves the customer's historical changes instead of overwriting previous records.

## CDC Using Snowflake Streams

The project uses a Snowflake Stream on `CUSTOMER_STG` to capture data changes.

The stream provides metadata such as:

* `METADATA$ACTION`
* `METADATA$ISUPDATE`

This change information is used by the SCD Type 2 processing logic.

## Data Enrichment

Customer city information is enriched with state information using the `CITY_STATE` lookup table.

Example:

```text
BANGALORE → Karnataka
DELHI     → Delhi
MUMBAI    → Maharashtra
```

## Technologies

* Snowflake
* Snowflake SQL
* Snowflake Streams
* Snowflake Tasks
* ETL
* CDC
* SCD Type 2
* SQL transformations
* Data validation
* Lookup joins

## Repository Structure

```text
snowflake-etl-scd-pipeline/
│
├── README.md
│
└── sql/
    ├── 01_create_tables.sql
    ├── 02_load_and_transform.sql
    └── 03_stream_scd_task.sql
```

## Key Learning

This project demonstrates a practical ETL pipeline in Snowflake with raw, staging and dimension layers, change data capture, data enrichment and historical tracking using SCD Type 2.
