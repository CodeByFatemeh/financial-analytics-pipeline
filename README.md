# Financial Analytics Pipeline

An end-to-end analytics project demonstrating how financial data can be transformed from raw source records into a structured analytical model for **credit risk, fraud detection, customer analysis, and business intelligence**.

The project uses **synthetic financial data** and implements a reproducible pipeline using **Python, PostgreSQL, SQL, dimensional modeling, Power BI, and DAX**.

> **Privacy Note:** This public repository contains no original client or institutional data. All records are synthetically generated specifically for portfolio demonstration.



## Project Overview

Financial risk and fraud analysis requires data from multiple business processes to be cleaned, standardized, modeled, validated, and transformed into reliable analytical datasets.

This project demonstrates that workflow through a layered analytics architecture:

**Synthetic Data → Bronze → Silver → Gold → Analytics**

The public dataset contains:

- **10,000 customers**
- **30,000 loan applications**
- **233,000 transactions**
- **15,000 devices**

The project focuses on:

- Credit risk segmentation
- Loan application analysis
- Fraud detection and investigation
- Customer risk analysis
- Transaction-level fraud patterns
- Device-related fraud signals
- Data quality and reconciliation
- Dimensional modeling for BI workloads



## Architecture

The pipeline follows a layered architecture designed to separate raw ingestion, data transformation, analytical modeling, and reporting.

![Project Architecture](docs/architecture.png)

### 1. Synthetic Data Generation

Python generates realistic synthetic datasets representing:

- Customers
- Loan applications
- Transactions
- Devices

Generated files are stored locally as CSV files and are excluded from version control.

### 2. Bronze Layer — Raw Ingestion

Synthetic CSV files are loaded into the PostgreSQL `bronze` schema.

The Bronze layer preserves the ingested structure with minimal transformation and acts as the raw landing layer for the pipeline.

### 3. Silver Layer — Cleaning & Standardization

SQL transformations create standardized analytical views in the `silver` schema.

Processing includes:

- Data-type handling
- Null and invalid-value filtering
- Text standardization
- Boolean/flag normalization
- Basic data-quality rules
- Preparation for downstream modeling

### 4. Gold Layer — Analytical Modeling

The Gold layer transforms cleaned data into query-ready analytical structures with explicitly defined grains.

Core analytical objects include:

- Customer dimension
- Application fact
- Transaction fact
- Application fraud features
- Transaction fraud features
- Portfolio-level summary metrics

### 5. Analytics & BI

The Gold layer is designed for consumption by **Power BI** and other analytical tools.

Reusable DAX measures demonstrate KPI development and filter-context analysis for credit-risk and fraud use cases.



## Dimensional Data Model

The analytical layer separates business events from descriptive dimensions to support efficient slicing, filtering, aggregation, and KPI calculation.

![Dimensional Data Model](docs/data-model.png)

Core analytical grains:

| Object | Grain |
|---|---|
| Customer Dimension | One row per customer |
| Application Fact | One row per loan application |
| Transaction Fact | One row per transaction |
| Application Fraud Features | One row per application |
| Transaction Fraud Features | One row per transaction |

This design helps prevent unintended many-to-many joins and aggregation fan-out while keeping analytical calculations understandable and reusable.



## Repository Structure

```text
credit-risk-fraud-analytics/
│
├── README.md
├── requirements.txt
├── .env.example
├── .gitignore
│
├── data/
│   └── generated/
│
├── src/
│   ├── generate_sample_data.py
│   ├── load_to_postgres.py
│   └── run_pipeline.py
│
├── sql/
│   ├── 01_bronze_schema.sql
│   ├── 02_silver_views.sql
│   ├── 03_gold_views.sql
│   └── 04_validation.sql
│
├── powerbi/
│   └── measures.dax
│
└── docs/
    ├── architecture.png
    └── data-model.png
```



## Synthetic Data Generation

The public repository does not distribute source financial records.

Instead, `src/generate_sample_data.py` creates synthetic datasets using a fixed random seed for reproducibility.

```bash
python src/generate_sample_data.py
```

The generator creates:

```text
customers.csv       10,000 rows
applications.csv    30,000 rows
transactions.csv   233,000 rows
devices.csv         15,000 rows
```

Generated CSV files are excluded from Git using `.gitignore`.



## Data Pipeline

The entire pipeline can be executed using:

```bash
python src/run_pipeline.py
```

The pipeline performs the following sequence:

```text
Generate Synthetic Data
        ↓
Load PostgreSQL Bronze Tables
        ↓
Create Silver Views
        ↓
Create Gold Analytical Model
        ↓
Validate Analytical Outputs
```

This makes the project reproducible without requiring access to any private source system.



## Analytical Features

### Credit Risk

Application-level modeling supports analysis of:

- Risk probability
- Risk bands
- Loan approval status
- Loan purpose
- Requested loan amount
- Interest rates
- Customer credit characteristics

### Fraud Analytics

Fraud-related features support analysis of:

- Suspected fraudulent applications
- Confirmed fraudulent transactions
- Fraud reasons
- High-value transactions
- Prior-device fraud signals
- Fraud rates under different analytical contexts

### Customer Analysis

Customer attributes support segmentation by:

- Age
- Income
- Region
- Employment
- Credit score
- Credit tier
- Default history



## Example DAX Measures

The repository includes reusable Power BI measures for application, transaction, and fraud analysis.

Examples include:

```DAX
Approval Rate =
DIVIDE(
    [Approved Applications],
    [Total Applications]
)
```

```DAX
Fraud Transaction Rate =
DIVIDE(
    [Fraudulent Transactions],
    [Total Transactions]
)
```

A more advanced example measures how strongly prior device fraud is associated with transaction fraud relative to the overall baseline:

```DAX
Prior Device Fraud Lift =
VAR ContextFraudRate =
    [Fraud Rate with Prior Device Fraud]

VAR BaselineFraudRate =
    CALCULATE(
        [Fraud Transaction Rate],
        REMOVEFILTERS(
            FactTransaction[device_has_prior_fraud_flag]
        )
    )

RETURN
    DIVIDE(
        ContextFraudRate,
        BaselineFraudRate
    )
```

Additional measures are available in:

```text
powerbi/measures.dax
```



## Data Validation

Data validation is treated as part of the analytical pipeline rather than as a final reporting step.

The validation suite includes checks for:

- Bronze-to-Gold row-count reconciliation
- Customer grain uniqueness
- Application grain uniqueness
- Transaction grain uniqueness
- Orphan customer references
- Fraud-rate sanity checks
- Application approval-rate validation
- Prior-device fraud analysis

Example grain validation:

```sql
SELECT
    application_id,
    COUNT(*) AS row_count
FROM gold.fact_application
GROUP BY application_id
HAVING COUNT(*) > 1;
```

Expected result:

```text
0 rows
```

Validation queries are available in:

```text
sql/04_validation.sql
```



## Technology Stack

| Area | Technology |
|---|---|
| Data Generation | Python, Pandas, NumPy |
| Database | PostgreSQL |
| Data Transformation | SQL |
| Data Architecture | Bronze / Silver / Gold |
| Data Modeling | Dimensional Modeling |
| Analytics | Power BI |
| Measures | DAX |
| Data Validation | SQL |
| Configuration | python-dotenv |
| Database Connectivity | SQLAlchemy, psycopg |



## Running the Project Locally

### 1. Clone the repository

```bash
git clone <repository-url>
cd credit-risk-fraud-analytics
```

### 2. Create a virtual environment

```bash
python -m venv .venv
```

Activate it on Windows:

```bash
.venv\Scripts\activate
```

On macOS/Linux:

```bash
source .venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Create the PostgreSQL database

```sql
CREATE DATABASE credit_risk_analytics;
```

### 5. Configure the connection

Create a `.env` file based on `.env.example`:

```env
DATABASE_URL=postgresql+psycopg://postgres:YOUR_PASSWORD@localhost:5432/credit_risk_analytics
```

The `.env` file is excluded from version control.

### 6. Run the pipeline

```bash
python src/run_pipeline.py
```

### 7. Run validation

Execute:

```text
sql/04_validation.sql
```

against the generated PostgreSQL database to validate grain, relationships, row counts, and analytical metrics.



## Data Privacy

This repository contains **no original client, institutional, or confidential financial data**.

All datasets in the public implementation are generated synthetically for portfolio demonstration.

The synthetic:

- Records
- Schema
- Segmentation rules
- Risk thresholds
- Fraud logic
- Analytical rules

are illustrative and are not intended to reproduce the proprietary data model, records, or business rules of any financial institution.

Generated datasets are excluded from version control and can be recreated locally using the provided Python generator.



## Skills Demonstrated

This project demonstrates practical experience with:

**SQL • PostgreSQL • Power BI • DAX • Python • Data Cleaning • ETL/ELT • Data Validation • Dimensional Modeling • Medallion Architecture • Credit Risk Analytics • Fraud Analytics • Business Intelligence**



## Author

**Tima Telgerdi**  
Data Analyst | Business Intelligence | Data Engineering

GitHub and LinkedIn are available through my profile.
