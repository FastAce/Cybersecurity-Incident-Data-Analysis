# Cybersecurity Incident Data Analysis – Power BI & Power Query Project

This repository contains a realistic, simulated dataset of cybersecurity incidents and a complete workflow to clean, analyze, and visualize the data with Power Query (ETL) and BI dashboards. The goal is to demonstrate an end-to-end Business + Data + IT skillset suitable for roles like IT Analyst, Security Analyst, or Data Analyst in IT Governance / Cyber Risk.

---

## 🎯 Objectives
- Perform ETL with Power Query on semi-structured IT/security data.
- Build key KPIs and interactive visuals in a BI dashboard.
- Deliver business-ready insights and prioritized recommendations for risk reduction and IT governance.
- Show a reproducible workflow: from raw incident logs to cleaned analytics dataset to management reporting.

---

## 📁 Repository Structure
```text
/data
  └── raw_cyber_incidents.csv          # Raw incident log (inconsistent formats, duplicates, missing data)
/powerquery
  └── PowerQuery_Cleaning_Steps.m      # Power Query M script used for data cleaning and normalization
/dashboard
  └── (optional) dashboard.pbix        # BI report (Power BI or equivalent)
/dashboard/screens
  └── (optional) *.png screenshots of main KPI views
README.md
.gitignore
```

All data is fully synthetic.

---

## 🧾 Dataset (Raw)
**File:** `data/raw_cyber_incidents.csv`  
**Rows:** ~300 + intentional duplicates  
**Columns include:**

| Column | Description |
| --- | --- |
| Incident_ID | Unique identifier for each incident |
| Date_Incident | Timestamp of detection or registration (various formats in raw data) |
| Region | Business region: Luxembourg, Belgium, France, Germany |
| Department_Affected | Impacted department (IT, Finance, HR, Operations, etc.) |
| Asset_Type | Asset category (Server, Workstation, Cloud Service, etc.) |
| Incident_Type | Phishing, Malware, Ransomware, Unauthorized Access, etc. (may include typos in raw data) |
| Severity | Low / Medium / High / Critical |
| Priority | P4 - Low .. P1 - Critical (in raw data: inconsistent labels like 'p1-critical', 'high (P2)', etc.) |
| Detection_Source | SIEM, User Report, IDS/IPS, EDR, Email Gateway, Audit, Threat Intel |
| Status | Contained, Eradicated, In Progress, False Positive, Resolved |
| Time_to_Detect_min | Minutes required to detect the incident (may be negative or tagged as '45 min' in raw data) |
| Time_to_Contain_min | Minutes to contain the threat |
| Time_to_Resolve_min | Minutes to fully resolve (MTTR baseline) |
| Business_Impact | None / Minor / Moderate / Major |
| Downtime_min | Minutes of business disruption |
| Estimated_Cost_EUR | Estimated financial impact, various formats ('€ 12000', '3000 EUR', '15 500', etc.) |
| Root_Cause | Social Engineering, Unpatched Vulnerability, Misconfiguration, etc. |
| Data_Sensitivity | Public / Internal / Confidential / Restricted |
| SLA_Breached | Yes / No (missing values also occur in the raw data) |
| Analyst | Assigned analyst handling the case |

---

## 🔧 ETL with Power Query
The file `powerquery/PowerQuery_Cleaning_Steps.m` contains the full cleaning pipeline. The key steps are:

1. **Standardize text fields**  
   - Trim leading/trailing whitespace.  
   - Normalize categories: e.g. `Phising` → `Phishing`, `Maleware` → `Malware`, etc.  
   - Normalize Priority values to one consistent scale: `P1 - Critical`, `P2 - High`, `P3 - Medium`, `P4 - Low`.

2. **Clean numeric columns**  
   - Convert strings like `"45 min"` → `45`.  
   - Remove invalid negative times in detection / containment / resolution / downtime.  
   - Extract digits from cost formats like `"€ 12 000"` or `"3000 EUR"` and convert to integer (`Estimated_Cost_EUR`).

3. **Parse timestamps**  
   - Convert multiple date/time formats (e.g. `2025-05-14 09:22:10`, `14/05/2025 09:22`, `14 May 2025 09:22`) into a proper `datetime` column.

4. **Fill missing values**  
   - Replace nulls in `Detection_Source`, `Data_Sensitivity`, `SLA_Breached`, etc. with `"Unknown"`.

5. **Type casting**  
   - Ensure all numeric fields are numbers, times are integers in minutes, cost is integer EUR, and `Date_Incident` is a proper datetime.

6. **Deduplicate incidents**  
   - If the same `Incident_ID` appears multiple times, keep only the most recent record by `Date_Incident` (SOC-style incident lifecycle).

7. **Derived columns for analytics**  
   - `Year` (incident year)  
   - `Month` (month name)  
   - `Resolve_Hours` = `Time_to_Resolve_min / 60`  
   - `Is_Critical` = 1 if Severity = "Critical", else 0  

8. **Enforce Priority from Severity**  
   - Critical → P1 - Critical  
   - High → P2 - High  
   - Medium → P3 - Medium  
   - Low → P4 - Low  

After ETL, export the cleaned table as `data/cleaned_cyber_incidents.csv` and use that file for dashboarding.

---

## 📈 Suggested KPIs
These KPIs can be implemented in Power BI, Tableau, Looker Studio, etc.:

- **Total Incidents** = count of rows  
- **% Critical Incidents** = (# where Severity = Critical) / (Total)  
- **MTTD (Mean Time To Detect)** = average of `Time_to_Detect_min`  
- **MTTC / MTTR** = averages of `Time_to_Contain_min` / `Time_to_Resolve_min`  
- **Total Estimated Cost (EUR)** = sum of `Estimated_Cost_EUR`  
- **Downtime (hours)** = sum of `Downtime_min` / 60  
- **SLA Breach Rate** = % of incidents with `SLA_Breached = "Yes"`  

Segment KPIs by:  
- `Incident_Type`  
- `Department_Affected`  
- `Region`  
- `Severity`  

---

## 📊 Dashboard Ideas
Recommended visuals for management reporting:

- **Executive Overview**  
  - Cards: Total Incidents, % Critical, Total Estimated Cost, SLA Breach Rate.

- **Incident Types vs Severity**  
  - Stacked column chart: `Incident_Type` on X, incident count split by `Severity`.

- **Trend Over Time**  
  - Line chart: incidents per month (use `Year` + `Month`).

- **MTTD / MTTR by Severity**  
  - Clustered bar or line: average detection / containment / resolution time per Severity.

- **By Department / Region**  
  - Bar chart of incidents by department.  
  - Map or bar chart by Region (Luxembourg, Belgium, France, Germany).

- **Top 10 Most Expensive Incidents**  
  - Table sorted by `Estimated_Cost_EUR`, include Severity, Business_Impact, Downtime_min.

---

## 🧩 Insights and Recommendations

### Key Findings
1. **Phishing** incidents are frequent (around ~28% of cases) but are typically Low/Medium severity. They rarely create long downtime, but they occur so often that they consume analyst time.  
2. **Ransomware** and **Data Exfiltration** are rare (<10% of incident count) but represent a disproportionate share of total estimated cost and have the longest resolution times (often > 48h).  
3. **IT and Finance** are the most exposed departments for High/Critical incidents, suggesting targeted attacks on sensitive systems and financial data.  
4. The **SLA breach rate (~25%)** is concentrated in High and Critical incidents, where containment and resolution take significantly longer. This is where business risk is highest.  
5. **Automated detection sources** (SIEM, IDS/IPS, EDR) are significantly faster than manual user reports — Mean Time To Detect is roughly 40% lower.  
6. A meaningful share of incidents (~15%) is driven by **Misconfiguration / Human error**, which means internal process maturity is as important as “external attackers”.

### Recommendations
1. **Security awareness and phishing simulations** to reduce incident volume caused by end users.  
2. **Backup and recovery drills** for ransomware: test restore times and backup integrity to reduce downtime and financial impact.  
3. **Extend automated detection coverage** (EDR/SIEM/IDS) especially on Finance and IT assets to reduce MTTD.  
4. **Improve configuration and patch management**:  
   - monthly vulnerability scans,  
   - privilege / access reviews,  
   - stricter change control in production.  
5. **Track MTTR (Time_to_Resolve_min)** per Incident_Type and Severity as an operational KPI for management.  
6. **Set 6‑month governance targets**:  
   - SLA breach rate < 15%,  
   - -20% average incident cost,  
   - fewer misconfiguration-related incidents via tighter process control.

### Future Work
- Add simple predictive modelling (e.g. decision tree) to flag incidents most likely to become Critical.  
- Track trends quarter-over-quarter to measure if actions are reducing risk.  
- Join with vulnerability scan data (CVE severity, open findings) to tie known weaknesses to realized business impact.

---

*All data in this repository is fully synthetic and generated for educational and portfolio demonstration purposes only.*
