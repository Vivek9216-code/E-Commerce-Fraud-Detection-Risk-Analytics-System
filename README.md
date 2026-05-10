# E-Commerce Fraud Detection & Risk Scoring System
### End-to-End Data Analytics Portfolio Project

---

## Problem Statement
E-commerce companies lose billions annually to fraudulent transactions.
This project builds a complete fraud detection pipeline — from raw data to a
live risk scoring system and executive dashboard.

---

## Project Structure
```
fraud_project/
|-- data/
|   |-- transactions.csv         # 50,000 synthetic transactions
|   |-- test_with_scores.csv     # Risk scores for test set
|
|-- models/
|   |-- fraud_model.pkl          # Trained Gradient Boosting model
|   |-- feature_list.csv         # Feature names
|
|-- outputs/
|   |-- plots/
|   |   |-- 01_eda_overview.png
|   |   |-- 02_risk_signals.png
|   |   |-- 03_correlation.png
|   |   |-- 04_model_evaluation.png
|   |   |-- 05_executive_dashboard.png
|   |   |-- 06_merchant_scorecard.png
|   |-- reports/
|       |-- Fraud_Detection_Report.pdf
|
|-- 01_data_generation.py        # Synthetic dataset generator
|-- 02_eda_analysis.py           # EDA & visualizations
|-- 03_model_training.py         # Feature engineering + ML models
|-- 04_sql_queries.sql           # SQL fraud analysis queries
|-- 05_dashboard.py              # Executive dashboards
|-- 06_report.py                 # PDF business report
|-- run_all.py                   # Run entire pipeline
|-- requirements.txt
|-- README.md
```

---

## Tech Stack
| Tool         | Usage                              |
|--------------|------------------------------------|
| Python       | Core language                      |
| Pandas/NumPy | Data manipulation & feature eng.   |
| Scikit-learn | ML models (RF, GBM, LR)            |
| Imbalanced-learn | SMOTE for class imbalance      |
| Matplotlib/Seaborn | Visualizations               |
| DuckDB       | In-process SQL analytics           |
| FPDF2        | PDF report generation              |
| Joblib       | Model serialization                |

---

## Key Results
| Metric               | Value      |
|----------------------|------------|
| Dataset Size         | 50,000 txns|
| Fraud Rate           | 5.5%       |
| Best Model           | Gradient Boosting |
| AUC Score            | **0.9800** |
| Fraud Recall         | **83%**    |
| Fraud Precision      | 69%        |
| Net Annual Saving    | ~INR 1.03 Crore |

---

## Risk Scoring System
Every transaction gets a Risk Score (0-100):
- **0-30 (Low)**     : Auto-approve
- **31-60 (Medium)** : Trigger 2FA / OTP
- **61-80 (High)**   : Manual review queue
- **81-100 (Critical)**: Auto-block + instant alert

---

## Feature Engineering Highlights
1. **Velocity Check** - Orders per user in last 1 hour
2. **Amount Deviation** - Transaction vs user's own historical average
3. **Merchant Risk Score** - Historical fraud rate per merchant
4. **Composite Rule Score** - Weighted combination of 9 risk signals
5. **Behavioral Flags** - IP mismatch, device mismatch, failed attempts

---

## How to Run
```bash
pip install -r requirements.txt
python run_all.py
```

---

## Business Impact
- Catches 83% of fraud before financial loss occurs
- Saves an estimated INR 62+ Lakhs/year in fraud losses
- Reduces false positives with precision-focused thresholding
- Scalable to real-time scoring via REST API deployment

---

## Author
Portfolio Project - Data Analytics | Fraud & Risk Detection
Tools: Python, SQL, Power BI, Advance Excel
