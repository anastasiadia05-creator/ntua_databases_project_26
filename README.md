
# ntua_databases_project_26

### Γενικό Νοσοκομείο «Υγειόπολης» — Σύστημα Διαχείρισης Βάσης Δεδομένων

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-336791?logo=postgresql&logoColor=white)
![ECE NTUA](https://img.shields.io/badge/ECE-NTUA-003087?logo=academia&logoColor=white)
![Course](https://img.shields.io/badge/Βάσεις%20Δεδομένων-2025--2026-28a745)
![Semester](https://img.shields.io/badge/6ο%20Εξάμηνο-ΣΗΜΜΥ-orange)

---

### Περιγραφή

## 🇬🇷 Ελληνικά

Εξαμηνιαία εργασία για το μάθημα **Βάσεις Δεδομένων** (6ο εξάμηνο, ΣΗΜΜΥ ΕΜΠ, 2025-2026).

Σχεδιάσαμε και υλοποιήσαμε μια πλήρη βάση δεδομένων για το **Γενικό Νοσοκομείο «Υγειόπολης»**, ένα σύστημα που διαχειρίζεται:

- **Προσωπικό** — ιατροί (με ιεραρχία εποπτείας), νοσηλευτές, διοικητικό προσωπικό
- **Τμήματα & Κλίνες** — 15+ τμήματα, κλίνες με τύπο και κατάσταση
- **Ασθενείς & Νοσηλείες** — πλήρες ιστορικό, triage, διαγνώσεις ICD-10, ΚΕΝ κωδικοί
- **Φάρμακα & Συνταγογράφηση** — δραστικές ουσίες, αλλεργίες, αλληλεπιδράσεις
- **Χειρουργεία & Ιατρικές Πράξεις** — αίθουσες, συμμετέχοντες, ΚΕΝ χρεώσεις
- **Εφημερίες & Βάρδιες** — 3 βάρδιες/ημέρα, περιορισμοί ανάπαυσης, μηνιαία όρια
- **Αξιολογήσεις** — ασθενείς αξιολογούν ιατρούς και νοσηλείες

## 🇬🇧 English

### Description

Semester project for the **Databases** course (6th Semester, ECE NTUA, 2025-2026).

We designed and implemented a full relational database for **General Hospital "Ygeiopolis"**, a hospital management system covering staff, patients, hospitalizations, on-call scheduling, and billing.

This repository contains all necessary files to set up and run the **Hospital Database**, including schema creation, reference data loading, and 15 optimized SQL queries.

---

###  Χαρακτηριστικά Υλοποίησης

- **Σχεσιακή ΒΔ** με πλήρεις περιορισμούς ακεραιότητας (PK, FK, CHECK, UNIQUE)
- **Indexes** βελτιστοποιημένα για τα 15 ερωτήματα
- **Views** για σύνθετες συνοπτικές απόψεις δεδομένων
- **Triggers** για αυτόματους ελέγχους (π.χ. κυκλική εποπτεία, όρια βαρδιών)
- **Δεδομένα αναφοράς** από επίσημες πηγές: ICD-10, ΚΕΝ, EMA Article 57

---

### Δομή Αρχείων

```
ntua_databases_project_26/
│
├── README.md
│
├── diagrams/
│   ├── er.pdf                ← Διάγραμμα Οντοτήτων-Συσχετίσεων (E/R)
│   └── relational.pdf        ← Σχεσιακό Διάγραμμα
│
├── sql/
│   ├── install.sql           ← Δημιουργία σχήματος (CREATE TABLE, indexes, triggers, views)
│   ├── load.sql              ← Φόρτωση δεδομένων (INSERT)
│   ├── reference_data.sql    ← Δεδομένα αναφοράς (ICD-10, ΚΕΝ, φάρμακα)
│   ├── Q01.sql / Q01_out.txt
│   ├── Q02.sql / Q02_out.txt
│   ├── ...
│   └── Q15.sql / Q15_out.txt
│
├── docs/
│   └── report.pdf            ← Αναφορά με screenshots (περιλαμβάνει EXPLAIN για Q04, Q06)
│
└── code/                     ← (Προαιρετικά) Επιπλέον κώδικας
```

---

### Προαπαιτούμενα

Απαιτείται εγκατεστημένη μία από τις παρακάτω βάσεις δεδομένων:

| DBMS | Έκδοση | Σύνδεσμος |
|---|---|---|
| **PostgreSQL**  *(προτείνεται)* | 15+ | https://www.postgresql.org/ |
| MySQL | 8+ | https://www.mysql.com/ |
| MariaDB | 10.6+ | https://mariadb.org/ |

>  Τα scripts έχουν γραφτεί και δοκιμαστεί σε **PostgreSQL 15+**. Δεν χρησιμοποιούνται enums, arrays, JSON ή XML.

---

###  Εγκατάσταση & Εκτέλεση

#### Βήμα 1 — Κλωνοποίηση αποθετηρίου

```bash
git clone https://github.com/<username>/ntua_databases_project_26.git
cd ntua_databases_project_26
```

#### Βήμα 2 — Σύνδεση με PostgreSQL

```bash
psql -U postgres
```

> **Windows** (standalone PostgreSQL):
> ```cmd
> cd "C:\Program Files\PostgreSQL\15\bin"
> psql.exe -U postgres
> ```

#### Βήμα 3 — Δημιουργία βάσης & εκτέλεση scripts

Μέσα στο `psql`:

```sql
CREATE DATABASE ygeiopolis;
\c ygeiopolis

\i sql/install.sql
\i sql/reference_data.sql
\i sql/load.sql
```

> ✅ Η βάση είναι έτοιμη!

#### Εκτέλεση ερωτημάτων

```sql
-- Εκτέλεση μεμονωμένου ερωτήματος
\i sql/Q01.sql

-- Αποθήκευση αποτελέσματος σε αρχείο
\o sql/Q01_out.txt
\i sql/Q01.sql
\o
```

---

### 📊 Ερωτήματα SQL (Q01–Q15)

| # | Περιγραφή |
|---|---|
| Q01 | Συνολικά έσοδα ανά τμήμα/έτος, ανάλυση ΚΕΝ & ασφαλιστικός φορέας |
| Q02 | Ιατροί ανά ειδικότητα, εφημερίες τρέχοντος έτους & επεμβάσεις ως κύριοι χειρουργοί |
| Q03 | Ασθενείς με >3 νοσηλείες στο ίδιο τμήμα & συνολικό κόστος |
| Q04 ⚡ | Μέσος όρος αξιολογήσεων συγκεκριμένου ιατρού *(+ EXPLAIN ANALYZE)* |
| Q05 | Νέοι ιατροί (<35 ετών) με τις περισσότερες χειρουργικές επεμβάσεις |
| Q06 ⚡ | Ιστορικό νοσηλειών ασθενή, διαγνώσεις ICD-10, κόστος *(+ EXPLAIN ANALYZE)* |
| Q07 | Κατανομή αλλεργιών ανά δραστική ουσία & αριθμός φαρμάκων που την περιέχουν |
| Q08 | Προσωπικό χωρίς προγραμματισμένη εφημερία σε συγκεκριμένη ημερομηνία/τμήμα |
| Q09 | *(βλ. εκφώνηση)* |
| Q10 | Top-3 ζεύγη δραστικών ουσιών που συνταγογραφήθηκαν ταυτόχρονα |
| Q11 | Ιατροί με ≥5 λιγότερες επεμβάσεις από τον πρώτο (τρέχον έτος) |
| Q12 | Απαιτούμενο προσωπικό ανά τμήμα/βάρδια για συγκεκριμένη εβδομάδα |
| Q13 | Ιεραρχία εποπτείας κάθε ιατρού (Recursive CTE) |
| Q14 | ICD-10 κατηγορίες με ίδιο αριθμό εισαγωγών σε δύο συνεχόμενα έτη (≥5 περιστατικά) |
| Q15 | Κατανομή triage ανά επίπεδο επείγοντος, μέσος χρόνος αναμονής & ποσοστό νοσηλείας |

> ⚡ Τα Q04 και Q06 περιλαμβάνουν σύγκριση `EXPLAIN` / `EXPLAIN ANALYZE` και εναλλακτική έκδοση με index hint.

---

### 🗂️ Επισκόπηση Σχήματος

| Κατηγορία | Πίνακες |
|---|---|
| Προσωπικό | `staff`, `doctor`, `nurse`, `admin_staff`, `doctor_specialty` |
| Τμήματα | `department`, `department_beds`, `department_specialty`, `doctor_department` |
| Ασθενείς | `patient`, `emergency_contact`, `patient_allergy`, `triage` |
| Νοσηλείες | `hospitalization`, `hospitalization_staff`, `hospitalization_procedure`, `hospitalization_lab` |
| Χειρουργεία | `operating_room`, `procedure_participant`, `medical_procedure` |
| Φάρμακα | `drug`, `active_substance`, `drug_substance`, `prescription` |
| Βάρδιες | `shifts`, `shift_staff`, `duty_assignment` |
| Αξιολογήσεις | `patient_hospitalization_review`, `patient_doctor_review` |
| Αναφορά | `icd10_code`, `ken_code`, `insurer`, `country` |

---

### 📐 Παραδοχές

1. Τα δεδομένα αναφοράς (ICD-10, ΚΕΝ, φάρμακα EMA) εισάγονται **ως έχουν** από επίσημες πηγές.
2. Για αλλεργίες χρησιμοποιείται **partial match** (`LIKE`) στις δραστικές ουσίες.
3. Οι ειδικευόμενοι ιατροί έχουν **υποχρεωτικά επόπτη** · οι Διευθυντές **δεν έχουν** επόπτη.
4. **Κυκλική αλυσίδα εποπτείας απαγορεύεται** (επιβάλλεται μέσω trigger).
5. Κάθε μέλος προσωπικού έχει ελάχιστο **διάστημα ανάπαυσης 8 ωρών** μεταξύ βαρδιών.
6. Μέγιστα όρια βαρδιών/μήνα: Ιατροί **15**, Νοσηλευτές **20**, Διοικητικό **25**.
7. Κανένας δεν μπορεί να συμμετέχει σε περισσότερες από **3 συνεχόμενες νυχτερινές** βάρδιες.

---

### 👥 Ομάδα

| Όνομα | Αριθμός Μητρώου |
|---|---|
| — | — |
| — | — |
| — | — |

---
---

## 🇬🇧 English

### 📋 Description

Semester project for the **Databases** course (6th Semester, ECE NTUA, 2025-2026).

We designed and implemented a full relational database for **General Hospital "Ygeiopolis"** — a realistic hospital management system covering staff, patients, hospitalizations, on-call scheduling, and billing.

This repository contains all necessary files to set up and run the **Hospital Database**, including schema creation, reference data loading, and 15 optimized SQL queries.

---

### ✨ Features

- **Full relational schema** with integrity constraints (PK, FK, CHECK, UNIQUE, domain)
- **Optimized indexes** tailored to all 15 queries
- **Views** for complex aggregated data perspectives
- **Triggers** for business rule enforcement (e.g. circular supervision prevention, shift limits)
- **Official reference data**: ICD-10 diagnoses, KEN billing codes, EMA Article 57 drug substances

---

### 📁 Repository Structure

```
ntua_databases_project_26/
│
├── README.md
│
├── diagrams/
│   ├── er.pdf                ← Entity-Relationship diagram
│   └── relational.pdf        ← Relational schema diagram
│
├── sql/
│   ├── install.sql           ← Schema creation (CREATE TABLE, indexes, triggers, views)
│   ├── load.sql              ← Data loading script (INSERT)
│   ├── reference_data.sql    ← Reference data (ICD-10, KEN codes, drugs)
│   ├── Q01.sql / Q01_out.txt
│   ├── Q02.sql / Q02_out.txt
│   ├── ...
│   └── Q15.sql / Q15_out.txt
│
├── docs/
│   └── report.pdf            ← Report with screenshots (incl. EXPLAIN for Q04, Q06)
│
└── code/                     ← (Optional) Additional application code
```

---

### ⚙️ Prerequisites

One of the following DBMS must be installed:

| DBMS | Version | Link |
|---|---|---|
| **PostgreSQL** ✅ *(recommended)* | 15+ | https://www.postgresql.org/ |
| MySQL | 8+ | https://www.mysql.com/ |
| MariaDB | 10.6+ | https://mariadb.org/ |

> ⚠️ All scripts were written and tested on **PostgreSQL 15+**. No enums, arrays, JSON, or XML are used.

---

### 🚀 Setup & Run

#### Step 1 — Clone the repository

```bash
git clone https://github.com/<username>/ntua_databases_project_26.git
cd ntua_databases_project_26
```

#### Step 2 — Connect to PostgreSQL

```bash
psql -U postgres
```

> **Windows** (standalone PostgreSQL):
> ```cmd
> cd "C:\Program Files\PostgreSQL\15\bin"
> psql.exe -U postgres
> ```

#### Step 3 — Create database & run scripts

Inside `psql`:

```sql
CREATE DATABASE ygeiopolis;
\c ygeiopolis

\i sql/install.sql
\i sql/reference_data.sql
\i sql/load.sql
```

> ✅ The database is ready!

#### Running queries

```sql
-- Run a single query
\i sql/Q01.sql

-- Save output to file
\o sql/Q01_out.txt
\i sql/Q01.sql
\o
```

---

### 📊 SQL Queries (Q01–Q15)

| # | Description |
|---|---|
| Q01 | Total revenue per department/year, KEN code breakdown & insurer distribution |
| Q02 | Doctors by specialty, on-call status this year & surgeries as lead surgeon |
| Q03 | Patients with >3 hospitalizations in the same department & total cost |
| Q04 ⚡ | Average patient reviews for a specific doctor *(+ EXPLAIN ANALYZE)* |
| Q05 | Young doctors (<35 y.o.) with the most surgical procedures as lead surgeon |
| Q06 ⚡ | Hospitalization history for a patient, ICD-10 diagnoses, cost *(+ EXPLAIN ANALYZE)* |
| Q07 | Allergy distribution per active substance & number of drugs containing it |
| Q08 | Staff with no scheduled shift on a given date and department |
| Q09 | *(see assignment specification)* |
| Q10 | Top-3 active substance pairs co-prescribed during the same hospitalization |
| Q11 | Doctors with ≥5 fewer procedures than the top surgeon (current year) |
| Q12 | Required staff per department/shift for a specific week, broken down by subclass |
| Q13 | Full supervision hierarchy for each doctor (Recursive CTE) |
| Q14 | ICD-10 categories with the same admission count across two consecutive years (≥5 cases) |
| Q15 | Triage distribution by urgency level, avg. wait time & hospitalization rate |

> ⚡ Q04 and Q06 include `EXPLAIN` / `EXPLAIN ANALYZE` comparison and an index-hint alternative version.

---

### 🗂️ Schema Overview

| Category | Tables |
|---|---|
| Staff | `staff`, `doctor`, `nurse`, `admin_staff`, `doctor_specialty` |
| Departments | `department`, `department_beds`, `department_specialty`, `doctor_department` |
| Patients | `patient`, `emergency_contact`, `patient_allergy`, `triage` |
| Hospitalizations | `hospitalization`, `hospitalization_staff`, `hospitalization_procedure`, `hospitalization_lab` |
| Surgery | `operating_room`, `procedure_participant`, `medical_procedure` |
| Medications | `drug`, `active_substance`, `drug_substance`, `prescription` |
| Shifts | `shifts`, `shift_staff`, `duty_assignment` |
| Reviews | `patient_hospitalization_review`, `patient_doctor_review` |
| Reference Data | `icd10_code`, `ken_code`, `insurer`, `country` |

---

### 📐 Assumptions

1. Reference data (ICD-10, KEN, EMA drugs) is imported **as-is** from official sources.
2. Drug allergy matching uses **partial match** (`LIKE`) on active substance names.
3. Resident doctors must have a **mandatory supervisor**; Directors have **no supervisor**.
4. **Circular supervision chains are forbidden** (enforced via trigger).
5. A minimum **8-hour rest period** is required between consecutive shifts for all staff.
6. Maximum shifts per month: Doctors **15**, Nurses **20**, Admin staff **25**.
7. No staff member may work more than **3 consecutive night shifts**.

---

### 👥 Team

| Name | Student ID |
|---|---|
| — | — |
| — | — |
| — | — |

---

*NTUA — School of Electrical & Computer Engineering | Databases Lab 2025-2026 | M. Koniaris*
