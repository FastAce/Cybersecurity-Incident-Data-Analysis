# 🛡️ Cybersecurity Incident Data Analysis  
_End-to-end ETL & Analytics Pipeline (Power Query + Power BI)_

This project demonstrates a complete data workflow that an **IT Analyst / Cybersecurity Analyst** would typically manage:

- Data cleaning & standardization  
- ETL pipeline creation using Power Query  
- Incident normalization according to SOC/ITSM logic  
- BI-ready dataset generation  
- Dashboard planning & KPI design  
- Documentation & analytics methodology  

_All data is 100% synthetic and created for learning and portfolio purposes._

---

## 📁 Repository Structure

```
Cybersecurity-Incident-Data-Analysis/
├── data/
│   ├── raw_cyber_incidents.csv
│   └── clean_cyber_incidents.csv
│
├── powerquery/
│   └── PowerQuery_Cleaning_Steps.m
│
├── dashboard/                 ← (To Do)
│   ├── cybersecurity_dashboard.pbix
│   └── screenshots/
│
└── README.md
```

---

## 🧾 Dataset Description

The dataset simulates 50–300 cybersecurity incidents with fields commonly used in:

- SOC monitoring  
- Incident response workflows  
- ITSM ticketing  
- Internal audit / GRC processes  

Typical fields include:

- `Incident_ID` – Unique identifier  
- `Date_Incident` – Datetime of detection/logging  
- `Region` – e.g. LU, BE, FR, DE  
- `Department_Affected` – IT, Finance, HR, Operations…  
- `Asset_Type` – Server, Workstation, Network Device, Cloud Service…  
- `Incident_Type` – Phishing, Malware, Ransomware, Unauthorized Access, etc.  
- `Severity` – Low / Medium / High / Critical  
- `Priority` – P1–P4 (inconsistent in the raw data)  
- `Detection_Source` – SIEM, IDS/IPS, EDR, Email Gateway, User Report…  
- `Status` – Contained, Resolved, In Progress, False Positive…  
- `Time_to_Detect_min`, `Time_to_Contain_min`, `Time_to_Resolve_min`  
- `Downtime_min` – Business downtime in minutes  
- `Estimated_Cost_EUR` – Estimated financial impact  
- `Business_Impact` – None / Minor / Moderate / Major  
- `Root_Cause` – Misconfiguration, Vulnerability, Social Engineering, etc.  
- `Data_Sensitivity` – Public / Internal / Confidential / Restricted  
- `SLA_Breached` – Yes / No  
- `Analyst` – Assigned SOC analyst  

---

## 🧹 Power Query ETL Pipeline

The full ETL logic is implemented in:

- `powerquery/PowerQuery_Cleaning_Steps.m`

It transforms:

`data/raw_cyber_incidents.csv` ➜ `data/clean_cyber_incidents.csv`

### 🔧 Main Transformations  
_(directly aligned with the M-script)_

- **Trim & normalize text fields**  
  - Remove leading/trailing whitespace from Region, Department, Asset_Type, Incident_Type, Severity, Priority, Detection_Source, Status, Business_Impact, Root_Cause, Data_Sensitivity, SLA_Breached, Analyst.
- **Standardize incident types**  
  - `Phising`, `Phshing` → `Phishing`  
  - `Maleware`, `Mal-ware` → `Malware`  
  - `Ransomeware`, `Ransom-ware` → `Ransomware`  
  - `DDOS`, `Ddos` → `DDoS`  
  - Other small spelling variants are normalized as well.
- **Normalize priority levels (P1–P4)**  
  - Map free-text formats to a clean scale:  
    - Contains “p1” or “critical” → `P1 - Critical`  
    - Contains “p2” or “high” → `P2 - High`  
    - Contains “p3” or “medium” → `P3 - Medium`  
    - Contains “p4” or “low” → `P4 - Low`
- **Enforce consistency from Severity**  
  - If `Severity = "Critical"` → `Priority = "P1 - Critical"`  
  - If `Severity = "High"` → `P2 - High`  
  - If `Severity = "Medium"` → `P3 - Medium`  
  - Else → `P4 - Low`
- **Convert durations to numeric values**  
  - Remove `" min"` suffix from `Time_to_*_min` and `Downtime_min`  
  - Convert to numeric (handling errors and invalid formats)  
  - Replace negative values with `null`
- **Extract numeric cost**  
  - Keep only digits in `Estimated_Cost_EUR`  
  - Cast to integer
- **Parse dates**  
  - Convert `Date_Incident` to `datetime` (with a `try ... otherwise null` pattern)
- **Handle missing values**  
  - Replace `null` in `Detection_Source`, `Root_Cause`, `Data_Sensitivity`, `SLA_Breached` with `"Unknown"`
- **Sort & deduplicate**  
  - Sort by `Incident_ID` and `Date_Incident` (descending)  
  - Deduplicate on `Incident_ID` and keep the latest incident record
- **Derived fields**  
  - `Year` – Year from `Date_Incident`  
  - `Month` – Month name from `Date_Incident`  
  - `Resolve_Hours` – `Time_to_Resolve_min / 60` (rounded)  
  - `Is_Critical` – 1 if `Severity = "Critical"`, else 0

---

## 📘 Data Dictionary (Key Fields)

| Field                  | Description                                        |
|------------------------|----------------------------------------------------|
| `Incident_ID`          | Unique incident identifier                         |
| `Date_Incident`        | Datetime of incident detection/logging             |
| `Region`               | Region or country                                  |
| `Department_Affected`  | Impacted department                                |
| `Asset_Type`           | Type of impacted asset                             |
| `Incident_Type`        | Normalized incident category                       |
| `Severity`             | Low / Medium / High / Critical                     |
| `Priority`             | Standardized P1–P4 priority                        |
| `Time_to_Detect_min`   | Minutes to detect                                  |
| `Time_to_Contain_min`  | Minutes to contain                                 |
| `Time_to_Resolve_min`  | Minutes to fully resolve                           |
| `Resolve_Hours`        | Derived resolution time in hours                   |
| `Downtime_min`         | Total business downtime in minutes                 |
| `Estimated_Cost_EUR`   | Estimated cost in EUR (integer)                    |
| `Business_Impact`      | Business impact level                              |
| `Root_Cause`           | Underlying cause of incident                       |
| `Data_Sensitivity`     | Data classification level                          |
| `SLA_Breached`         | SLA breach flag (Yes/No/Unknown)                   |
| `Is_Critical`          | 1 if Severity = Critical, else 0                   |
| `Year`                 | Year extracted from `Date_Incident`                |
| `Month`                | Month name extracted from `Date_Incident`          |

---

## 🧩 Architecture Diagram (Pipeline)

Below is a high-level view of the data pipeline from raw CSV to BI-ready dataset and dashboard.

```mermaid
flowchart LR
    A[Raw CSV<br/>data/raw_cyber_incidents.csv] --> B[Power Query ETL<br/>(PowerQuery_Cleaning_Steps.m)]
    B --> C[Cleaned CSV<br/>data/clean_cyber_incidents.csv]
    C --> D[Power BI Model<br/>(Fact table)]
    D --> E[Dashboards<br/>Executive / Operational / Risk]
```

**Stages:**

1. **Source** — Synthetic incidents stored as a flat CSV.  
2. **ETL (Power Query)** — All cleaning, normalization and enrichment applied.  
3. **Cleaned Layer** — Single fact-like table ready for BI tools.  
4. **Analytics Layer (Power BI)** — Visual dashboards (KPIs, trends, cost, risk).  

---

## 📊 Power BI Dashboard — Planned (To Do)

### 🟦 Page 1 — Executive Overview
- Total number of incidents  
- % Critical incidents  
- SLA breach rate  
- Total estimated cost (EUR)  
- Incident trend by month & year  

### 🟨 Page 2 — Operational Insights
- Incidents by type and severity  
- MTTR (Mean Time To Resolve) by severity  
- MTTD (Mean Time To Detect) / MTTC (Mean Time To Contain)  
- Detection source breakdown (tool vs user-reported)  
- Top 10 costliest incidents  

### 🟥 Page 3 — Risk & Governance
- Business impact distribution by department/region  
- Downtime vs severity / incident type  
- SLA breaches vs priority / severity  
- Critical incident clustering / patterns  

**Dashboard files (To Do):**

- `dashboard/cybersecurity_dashboard.pbix`  
- `dashboard/screenshots/` (key visual exports)

---

## 💡 Insights & Recommendations (Conceptual)

These insights are examples of what the cleaned dataset and future Power BI dashboard are designed to surface. They illustrate how this pipeline can support IT / security decision-making:

### Example Insights (based on typical patterns)

- **Critical incidents are often linked to specific incident types**  
  e.g. Ransomware, Data Exfiltration or Unauthorized Access drive a disproportionate share of `Critical` severity cases.

- **User-reported incidents tend to have higher MTTD**  
  Incidents detected via “User Report” usually take longer to detect compared to SIEM/EDR, which can increase SLA breach risk.

- **A small number of incidents may drive most of the cost**  
  Top 5–10 incidents (by `Estimated_Cost_EUR`) often represent a significant share of the total impact (Pareto-style pattern).

- **Some departments or regions are repeatedly over-represented**  
  Higher incident counts or critical incidents might cluster in specific departments (e.g. Operations / Finance) or regions.

- **Configuration and patching issues can be recurring root causes**  
  “Misconfiguration” or “Unpatched Vulnerability” may appear frequently in `Root_Cause`, especially for high-cost incidents.

### Recommendations (conceptual)

- **Improve early detection**  
  - Strengthen SIEM / EDR rules for top incident types (e.g. phishing, malware).  
  - Reduce reliance on user-only reports for critical incident types.

- **Focus on high-impact segments**  
  - Prioritize hardening and awareness in departments/regions with repeated high-severity incidents.  
  - Define targeted training for users in high-risk areas.

- **Reduce SLA breaches**  
  - Monitor MTTD and MTTR for P1/P2 to ensure they stay within defined thresholds.  
  - Implement playbooks to accelerate containment and resolution for critical categories.

- **Use this dataset as a template**  
  - Extend the model with real logs and ITSM exports (e.g. ServiceNow, Jira, etc.).  
  - Add more tables (assets, vulnerabilities, controls) for deeper risk analysis.

---

## 🗂️ Kanban-Style To Do / Done

| Status | Item | Details |
|--------|------|---------|
| ✅ Done | Synthetic raw dataset | Generated `data/raw_cyber_incidents.csv` |
| ✅ Done | ETL via Power Query | Implemented in `powerquery/PowerQuery_Cleaning_Steps.m` |
| ✅ Done | Cleaned dataset | Exported `data/clean_cyber_incidents.csv` |
| ✅ Done | Repo documentation | This README (ETL, structure, roadmap) |
| ⏳ To Do | Build Power BI dashboard | Create `dashboard/cybersecurity_dashboard.pbix` |
| ⏳ To Do | Add screenshots | Save key visuals in `dashboard/screenshots/` |
| ⏳ To Do | Insights & recommendations (final) | Refine based on actual dashboard metrics |
| ⏳ To Do | Optional Python validation | Add a notebook to validate ETL with pandas |

---

## 🔮 Roadmap

- [x] Generate synthetic raw dataset  
- [x] Build Power Query ETL pipeline  
- [x] Export cleaned dataset  
- [x] Document ETL, data dictionary and architecture  
- [ ] Build Power BI dashboard (3 pages)  
- [ ] Add screenshots of key visuals  
- [ ] Write final “Insights & Recommendations” based on actual visuals  
- [ ] (Optional) Add Python notebook to validate metrics and spot-check data  

---

## 📅 Update Log

**2025-11-16**  
- Added cleaned dataset (`data/clean_cyber_incidents.csv`)  
- Normalized data folder structure  
- Documented ETL pipeline, data dictionary & architecture  
- Added dashboard plan, insights section & Kanban-style roadmap  

**2025-10-25**  
- Initial commit (`raw_cyber_incidents.csv` + Power Query script)

---

## 📄 License  

MIT License  

---

🟣 _All data in this repository is synthetic and intended solely for training, portfolio building, and interview preparation (no real incidents or sensitive information)._



