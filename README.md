# 🏥 Diabetic Patient Readmission Risk Analytics Pipeline  

## 📊 End-to-End Analytics for Hospital 30-Day Readmission Reduction

![Status](https://img.shields.io/badge/Python%20ETL-Complete-brightgreen)
![Status](https://img.shields.io/badge/BigQuery%20Views-Complete-brightgreen)
![Status](https://img.shields.io/badge/Excel%20KPI-Complete-brightgreen)
![Status](https://img.shields.io/badge/Power%20BI-WIP-yellow)

[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://python.org)
[![BigQuery](https://img.shields.io/badge/BigQuery-GCP-orange.svg)](https://cloud.google.com/bigquery)
[![Power BI](https://img.shields.io/badge/Power%20BI-Desktop-yellow.svg)](https://powerbi.microsoft.com)
[![Excel](https://img.shields.io/badge/Excel-2019+-green.svg)](https://microsoft.com/excel)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📋 Project Overview

This project addresses hospital 30-day readmission penalty risks and inpatient capacity constraints by engineering an **end-to-end data analytics pipeline** transforming raw clinical encounter data into executive decision tools.

### The Problem
- Hospitals face CMS penalties of up to **3% of Medicare billings** for excess readmissions
- **69,987** hospital encounters analyzed
- **6,285** readmissions identified (8.98% overall rate)
- CMS benchmark: **15.0%**

### ✅ Completed Phases
- ✅ **Python ETL**: Data cleaning, feature engineering, BigQuery upload
- ✅ **BigQuery Views**: 10 analytical SQL views for readmission analysis
- ✅ **Excel KPI Engine**: Automated data validation, CMS metrics, financial impact

### 🚧 In Progress
- 🚧 **Power BI Dashboard**: Star schema, DAX measures, 4-page interactive dashboard

---

## 🏗️ Pipeline Architecture


---

## 📊 Key Insights Discovered

### 1. Polypharmacy Risk Multiplier
| Medication Count | Readmission Rate |
|:---|:---|
| 1-10 Medications | 7.30% |
| 11-20 Medications | 9.26% |
| **21+ Medications** | **10.46%** |

### 2. Insulin Change Impact
| Insulin Change | Readmission Rate |
|:---|:---|
| Not Prescribed | 8.30% |
| Steady | 9.26% |
| Increased | 9.84% |
| **Reduced at Discharge** | **10.54%** |

### 3. Diagnosis Category Risk (RRI)
| Category | Readmission Rate | Relative Risk Index |
|:---|:---|:---|
| External/Supplementary | 13.49% | **1.50x** |
| Injury | 10.80% | 1.20x |
| Circulatory | 9.68% | 1.08x |
| Diabetes | 9.12% | 1.02x |

### 4. Prior Inpatient History
| Prior Visits | Readmission Rate |
|:---|:---|
| 0 visits | 8.13% |
| 1 visit | 12.88% |
| 2 visits | 18.52% |
| **3-5 visits** | **24.34%** |
| **6+ visits** | **41.58%** |

---

## 📈 Key Metrics

| Metric | Value |
|:---|:---|
| Total Encounters | 69,987 |
| Overall Readmission Rate | 8.98% |
| Total Readmissions | 6,285 |
| CMS Benchmark | 15.0% |
| Performance vs. Benchmark | **-6.02%** |
| Excess Readmissions Target | 1,257 |
| Estimated Annual Cost Savings | **$1.07M** |

---

## 🛠️ Technologies Used

### ✅ Completed
- **Python**: pandas, numpy, sqlalchemy, google-cloud-bigquery
- **BigQuery**: 10 analytical SQL views
- **Microsoft Excel**: Structured Tables, Pivot Tables, Advanced Formulas, Data Validation

### 🚧 In Progress
- **Microsoft Power BI**: Star Schema Modeling, DAX, Visual Analytics

### Environment
- **VS Code** / **Jupyter Notebooks**
- **Google Cloud Platform (GCP)**

---

## 📁 Repository Structure

---

## 🚀 Getting Started

### Prerequisites
1. **Python 3.9+** with pandas, numpy, google-cloud-bigquery
2. **Google Cloud Platform** account with BigQuery enabled
3. **Microsoft Power BI Desktop** (free)
4. **Microsoft Excel 2019+**

### Step 1: Clone the Repository
```bash
https://github.com/Leiyangamba/Diabetic-Patient-Readmission-Risk-Analytics-Pipeline.git
cd Diabetic-Patient-Readmission-Risk-Analytics-Pipeline





