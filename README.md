<a id="readme-top"></a>

[![PostgreSQL][postgresql-shield]][postgresql-url]
[![NTUA][ntua-shield]][ntua-url]
[![ECE][ece-shield]][ece-url]

<br />
<div align="center">
  <h2 align="center">Hospital "Ygeiopolis" - Database Management System</h2>
  <p align="center">
    Semester Project for the "Databases" course (6th Semester, ECE NTUA, 2025–2026)
    <br />
    <a href="#getting-started"><strong>Get Started »</strong></a>
    <br />
    <br />
    <a href="#queries">View Queries</a>
    &middot;
    <a href="#repository-structure">Repository Structure</a>
    &middot;
    <a href="#team">Team</a>
  </p>
</div>

---

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#database-features">Database Features</a></li>
    <li><a href="#assumptions">Assumptions</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#repository-structure">Repository Structure</a></li>
    <li><a href="#queries">Queries</a></li>
    <li><a href="#team">Team</a></li>
  </ol>
</details>

---

## About The Project

The **Hospital "Ygeiopolis" Database** is a full relational database system designed to emulate an operation management database of a general hospital. It stores and manages data for all entities involved in hospital operations: doctors with specialty and supervision hierarchies, nurses, administrative staff, patients, hospitalizations, ICD-10 diagnoses, KEN billing codes, drug prescriptions and allergies, surgical procedures, on-call shift scheduling, and patient reviews.

The database is optimized to query and analyze this data in an efficient manner, with carefully designed indexes, views, and triggers that enforce business rules automatically.

This repository contains all necessary files to set up and run the database from scratch.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Database Features

- **Staff Management**: Stores doctors (with specialty, rank, and supervision hierarchy), nurses, and administrative personnel with role and office information.
- **Patient & Hospitalization Tracking**: Manages patient records, emergency contacts, triage assessments, full hospitalization history, ICD-10 diagnoses, and KEN billing.
- **Shift Scheduling**: Organizes 3 daily on-call shifts per department with automatic enforcement of rest periods, monthly limits, and consecutive night shift restrictions.
- **Prescription & Drug Management**: Tracks prescriptions, active substances per drug (EMA Article 57), and patient allergies with partial substance matching.
- **Surgical Procedures**: Records operating room usage, all procedure participants, and lead surgeons per intervention.
- **Patient Reviews**: Patients can rate and review both their overall hospitalization experience and their attending doctors.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Assumptions

1. Each department operates 24/7, organized in three 8-hour shifts: morning (07:00–15:00), afternoon (15:00–23:00), and night (23:00–07:00).
2. Resident doctors must have a mandatory supervisor; Directors have no supervisor.
3. Circular supervision chains are forbidden and enforced via trigger.
4. A minimum rest period of 8 hours is required between any two consecutive shifts for the same staff member.
5. Maximum shifts per month: Doctors 15, Nurses 20, Administrative staff 25.
6. No staff member may work more than 3 consecutive night shifts.
7. Reference data (ICD-10, KEN, EMA drugs) is imported as-is from official sources. Allergy matching uses partial match (`LIKE`) on active substance names.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Getting Started

### Prerequisites

Install the following DBMS:

- **PostgreSQL 15+** *(recommended)* — https://www.postgresql.org/

> All scripts were written and tested on **PostgreSQL 15+**.

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/<username>/ntua_databases_project_26.git
   cd ntua_databases_project_26
   ```

2. Set up the database — choose one of the two methods below:

---

#### Method 1 — Interactive (psql shell)

Connect to PostgreSQL:

```bash
psql -U postgres
```

On Windows:

```cmd
cd "C:\Program Files\PostgreSQL\15\bin"
psql.exe -U postgres
```

Then, inside the psql shell, run:

```sql
CREATE DATABASE ygeiopolis;
\c ygeiopolis

\i sql/install.sql
\i sql/reference_data.sql
\i sql/load.sql
```

To run a query and save its output:

```sql
\o sql/Q01_out.txt
\i sql/Q01.sql
\o
```

---

#### Method 2 — Direct (command line flags)

Run everything directly from your terminal, without entering the psql shell:

```bash
psql -U postgres -c "CREATE DATABASE ygeiopolis;"

psql -U postgres -d ygeiopolis -f sql/install.sql
psql -U postgres -d ygeiopolis -f sql/reference_data.sql
psql -U postgres -d ygeiopolis -f sql/load.sql
```

To run a query and save its output:

```bash
psql -U postgres -d ygeiopolis -f sql/Q01.sql > sql/Q01_out.txt
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Repository Structure

```
ntua_databases_project_26/
│
├── README.md
├── diagrams/
│   ├── er.pdf                  ← Entity-Relationship diagram
│   └── relational.pdf          ← Relational schema diagram
│
├── sql/
│   ├── install.sql             ← Schema creation (tables, indexes, triggers, views)
│   ├── load.sql                ← Data loading script
│   ├── reference_data.sql      ← Official reference data (ICD-10, KEN, drugs)
│   ├── Q01.sql / Q01_out.txt
│   ├── ...
│   └── Q15.sql / Q15_out.txt
│
├── docs/
│   └── report.pdf              ← Report with screenshots (incl. EXPLAIN for Q04, Q06)
│
└── code/                       ← (Optional) Additional code
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Queries

| # | Description |
|---|---|
| Q01 | Total revenue per department and year, with KEN code breakdown and insurer distribution |
| Q02 | Doctors by specialty, on-call activity this year, and surgeries as lead surgeon |
| Q03 | Patients hospitalized more than 3 times in the same department, with total cost |
| Q04 ⚡ | Average patient review scores for a specific doctor *(+ EXPLAIN ANALYZE)* |
| Q05 | Young doctors (age < 35) with the most surgical procedures as lead surgeon |
| Q06 ⚡ | Full hospitalization history for a specific patient, with ICD-10 diagnoses and cost *(+ EXPLAIN ANALYZE)* |
| Q07 | Allergy counts per active substance and number of drugs containing it |
| Q08 | Staff with no scheduled shift on a given date and department |
| Q09 | *(see assignment specification)* |
| Q10 | Top-3 active substance pairs co-prescribed during the same hospitalization |
| Q11 | Doctors with at least 5 fewer procedures than the top surgeon in the current year |
| Q12 | Required staff per department and shift for a specific week, broken down by subclass |
| Q13 | Full supervision hierarchy per doctor, from direct supervisor to Director (Recursive CTE) |
| Q14 | ICD-10 categories with equal admission counts across two consecutive years (min. 5 cases each) |
| Q15 | Triage distribution by urgency level, average wait time, hospitalization rate, and referral breakdown |

> ⚡ Q04 and Q06 include an `EXPLAIN` / `EXPLAIN ANALYZE` comparison and an alternative version with index hints, as required by the assignment.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Team

| Name | Student ID |
|---|---|
| — | — |
| — | — |
| — | — |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

<!-- MARKDOWN LINKS -->
[postgresql-shield]: https://img.shields.io/badge/PostgreSQL-15%2B-336791?style=for-the-badge&logo=postgresql&logoColor=white
[postgresql-url]: https://www.postgresql.org/
[ntua-shield]: https://img.shields.io/badge/NTUA-ECE-003087?style=for-the-badge
[ntua-url]: https://www.ece.ntua.gr/
[ece-shield]: https://img.shields.io/badge/Databases-2025--2026-28a745?style=for-the-badge
[ece-url]: https://www.ece.ntua.gr/
