ROLLBACK;
-- install.sql
-- Γενικό Νοσοκομείο «Υγειόπολης» — Πλήρες schema βάσης δεδομένων
-- NTUA | Βάσεις Δεδομένων 2025-2026
-- PostgreSQL 15+

SET app.hospital_founded = '2000-01-01';

BEGIN;

-- ΜΕΡΟΣ Α: DROP TABLES

-- ΕΝΟΤΗΤΑ 11: MEDIA
DROP TABLE IF EXISTS image CASCADE;
-- ΕΝΟΤΗΤΑ 10: REVIEWS
DROP TABLE IF EXISTS patient_doctor_review CASCADE;
DROP TABLE IF EXISTS patient_hospitalization_review CASCADE;
-- ΕΝΟΤΗΤΑ 9: SHIFT SCHEDULING
DROP TABLE IF EXISTS shift_staff CASCADE;
DROP TABLE IF EXISTS shifts CASCADE;
-- ΕΝΟΤΗΤΑ 8: PRESCRIPTIONS
DROP TABLE IF EXISTS prescription CASCADE;
-- ΕΝΟΤΗΤΑ 7: LAB & OPERATIONS
DROP TABLE IF EXISTS hospitalization_lab CASCADE; -- FIXED
DROP TABLE IF EXISTS lab_exam CASCADE;
DROP TABLE IF EXISTS procedure_participant CASCADE;
DROP TABLE IF EXISTS hospitalization_procedure CASCADE; -- FIXED
DROP TABLE IF EXISTS medical_procedure CASCADE;
DROP TABLE IF EXISTS operating_room CASCADE;
-- ΕΝΟΤΗΤΑ 6: HOSPITALIZATION
DROP TABLE IF EXISTS hospitalization CASCADE;
DROP TABLE IF EXISTS hospitalization_staff CASCADE;
DROP TABLE IF EXISTS icd10_code CASCADE;
DROP TABLE IF EXISTS ken_code CASCADE;
-- ΕΝΟΤΗΤΑ 5: TRIAGE
DROP TABLE IF EXISTS triage CASCADE;
-- ΕΝΟΤΗΤΑ 4: PATIENTS
DROP TABLE IF EXISTS patient_allergy CASCADE;
DROP TABLE IF EXISTS patient_emergency_contact CASCADE;
DROP TABLE IF EXISTS emergency_contact CASCADE;
DROP TABLE IF EXISTS patient CASCADE;
-- ΕΝΟΤΗΤΑ 3: PHARMACY
DROP TABLE IF EXISTS drug_substance CASCADE;
DROP TABLE IF EXISTS drug CASCADE;
DROP TABLE IF EXISTS active_substance CASCADE;
-- ΕΝΟΤΗΤΑ 2: STAFF
DROP TABLE IF EXISTS admin_staff CASCADE;
DROP TABLE IF EXISTS admin_role CASCADE;
DROP TABLE IF EXISTS nurse CASCADE;
DROP TABLE IF EXISTS doctor_department CASCADE;
DROP TABLE IF EXISTS doctor CASCADE;
DROP TABLE IF EXISTS doctor_specialty CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
-- ΕΝΟΤΗΤΑ 1: HOSPITAL DEPARTMENTS
DROP TABLE IF EXISTS department_beds CASCADE;
DROP TABLE IF EXISTS department_specialty CASCADE;
DROP TABLE IF EXISTS department CASCADE;
-- ΕΝΟΤΗΤΑ 0: REFERENCE DATA
DROP TABLE IF EXISTS insurer CASCADE;
DROP TABLE IF EXISTS country CASCADE;



-- ΜΕΡΟΣ Β: DROP VIEWS

DROP VIEW IF EXISTS v_department_full_profile CASCADE;
DROP VIEW IF EXISTS v_available_beds CASCADE;
DROP VIEW IF EXISTS v_staff_full_profile CASCADE;
DROP VIEW IF EXISTS v_department_directors CASCADE;
DROP VIEW IF EXISTS v_staff_availability CASCADE;
DROP VIEW IF EXISTS v_triage_nurses CASCADE;
DROP VIEW IF EXISTS v_patient_full_profile CASCADE;
DROP VIEW IF EXISTS v_patient_history CASCADE;
DROP VIEW IF EXISTS v_triage_queue CASCADE;
DROP VIEW IF EXISTS v_active_hospitalizations CASCADE;
DROP VIEW IF EXISTS v_hospitalization_cost_breakdown CASCADE;
DROP VIEW IF EXISTS v_patient_prescriptions CASCADE;
DROP VIEW IF EXISTS v_monthly_shift_summary CASCADE;
DROP VIEW IF EXISTS v_hospitalization_review_avg CASCADE;
DROP VIEW IF EXISTS v_doctor_review_avg CASCADE;

-- ΜΕΡΟΣ Γ: DROP FUNCTIONS

-- ΕΝΟΤΗΤΑ 1
DROP FUNCTION IF EXISTS fn_department_director_check() CASCADE;
DROP FUNCTION IF EXISTS fn_check_doctor_specialty_in_department() CASCADE;
DROP FUNCTION IF EXISTS fn_check_one_director_per_department() CASCADE;
-- ΕΝΟΤΗΤΑ 2
DROP FUNCTION IF EXISTS fn_check_staff_has_subtype() CASCADE;
DROP FUNCTION IF EXISTS fn_check_subtype_matches_type() CASCADE;
DROP FUNCTION IF EXISTS fn_doctor_supervisor_check() CASCADE;
DROP FUNCTION IF EXISTS fn_check_supervisor_same_department() CASCADE;
-- ΕΝΟΤΗΤΑ 3
DROP FUNCTION IF EXISTS fn_check_prescription_doctor() CASCADE;
-- ΕΝΟΤΗΤΑ 4
DROP FUNCTION IF EXISTS fn_patient_updated_at() CASCADE;
DROP FUNCTION IF EXISTS fn_patient_completeness_check(INT) CASCADE;
DROP FUNCTION IF EXISTS fn_patient_discharge_check() CASCADE;
DROP FUNCTION IF EXISTS fn_patient_prescription_check() CASCADE;
DROP FUNCTION IF EXISTS fn_patient_amka_gr_check() CASCADE;
-- ΕΝΟΤΗΤΑ 5
DROP FUNCTION IF EXISTS fn_triage_nurse_in_emergency() CASCADE;
DROP FUNCTION IF EXISTS fn_triage_single_active() CASCADE;
DROP FUNCTION IF EXISTS fn_triage_create_hospitalization() CASCADE;
-- ΕΝΟΤΗΤΑ 6
DROP FUNCTION IF EXISTS fn_hosp_bed_dept_match() CASCADE;
DROP FUNCTION IF EXISTS fn_hosp_bed_status() CASCADE;
DROP FUNCTION IF EXISTS fn_hosp_bed_overlap() CASCADE;
DROP FUNCTION IF EXISTS fn_hosp_discharge_diagnosis() CASCADE;
DROP FUNCTION IF EXISTS fn_hosp_total_cost() CASCADE;
-- ΕΝΟΤΗΤΑ 7
DROP FUNCTION IF EXISTS fn_surgery_room_overlap() CASCADE;
DROP FUNCTION IF EXISTS fn_surgery_doctor_overlap() CASCADE;
DROP FUNCTION IF EXISTS fn_surgery_assistant_overlap() CASCADE;
DROP FUNCTION IF EXISTS fn_procedure_during_hosp() CASCADE;
DROP FUNCTION IF EXISTS fn_lab_exam_during_hosp() CASCADE;
DROP FUNCTION IF EXISTS fn_lab_exam_doctor_in_dept() CASCADE;
-- ΕΝΟΤΗΤΑ 8
DROP FUNCTION IF EXISTS fn_allergy_check() CASCADE;
DROP FUNCTION IF EXISTS fn_prescription_doctor_in_dept() CASCADE;
DROP FUNCTION IF EXISTS fn_prescription_within_hosp() CASCADE;
-- ΕΝΟΤΗΤΑ 9
DROP FUNCTION IF EXISTS fn_shift_staff_belongs_to_department() CASCADE;
DROP FUNCTION IF EXISTS fn_shift_min_staff() CASCADE;
DROP FUNCTION IF EXISTS fn_shift_resident_needs_senior() CASCADE;
DROP FUNCTION IF EXISTS fn_shift_monthly_limit() CASCADE;
DROP FUNCTION IF EXISTS fn_shift_rest_8h() CASCADE;
DROP FUNCTION IF EXISTS fn_shift_max_3_night() CASCADE;
-- ΕΝΟΤΗΤΑ 10
DROP FUNCTION IF EXISTS fn_hr_after_discharge() CASCADE;
DROP FUNCTION IF EXISTS fn_dr_after_discharge() CASCADE;
DROP FUNCTION IF EXISTS fn_dr_prescribed_doctor() CASCADE;
-- ΕΝΟΤΗΤΑ 11
DROP FUNCTION IF EXISTS fn_image_entity_check() CASCADE;



-- ΜΕΡΟΣ Δ: CREATE TABLES


-- ΕΝΟΤΗΤΑ 0: REFERENCE DATA

-- Πίνακας Χωρών/Υπηκοοτήτων (ISO 3166-1 alpha-2)
CREATE TABLE country (
    country_code CHAR(2) NOT NULL,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_country PRIMARY KEY (country_code)
);

-- Πίνακας Ασφαλιστικών Φορέων
CREATE TABLE insurer (
    insurer_id SERIAL NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(30) NOT NULL CHECK (type IN ('δημόσια', 'στρατιωτική', 'επαγγελματική', 'ιδιωτική', 'ΕΟΧ', 'διμερής', 'διεθνής', 'ανασφάλιστος')),
    CONSTRAINT pk_insurer PRIMARY KEY (insurer_id),
    CONSTRAINT uq_insurer_name UNIQUE (name)
);


-- ΕΝΟΤΗΤΑ 1: HOSPITAL DEPARTMENTS

-- Τμήματα Νοσοκομείου
CREATE TABLE department (
    department_name VARCHAR(100) NOT NULL,
    department_description TEXT NOT NULL,
    bed_capacity INT NOT NULL CHECK (bed_capacity >= 0),
    floor_building VARCHAR(50) NOT NULL,
    director_id INT, -- FK προστίθεται με ALTER TABLE παρακάτω
    CONSTRAINT pk_department PRIMARY KEY (department_name),
    CONSTRAINT uq_dept_director UNIQUE (director_id)
);

-- Κλίνες ανά Τμήμα
CREATE TABLE department_beds (
    bed_id SERIAL NOT NULL,
    type VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'διαθέσιμη',
    department_name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_bed PRIMARY KEY (bed_id),
    CONSTRAINT uq_bed_dept UNIQUE (bed_id, department_name),
    CONSTRAINT fk_bed_dept FOREIGN KEY (department_name) REFERENCES department (department_name) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_bed_type CHECK (type IN ('ΜΕΘ', 'μονόκλινο', 'πολύκλινο', 'δίκλινο', 'απομόνωσης', 'ημερήσιας νοσηλείας', 'ΜΕΝΝ')),
    CONSTRAINT chk_bed_status CHECK (status IN ('διαθέσιμη', 'κατειλημμένη', 'υπό συντήρηση'))
);


-- ΕΝΟΤΗΤΑ 2: STAFF

-- Στοιχεία Προσωπικού (supertype)
CREATE TABLE staff (
    staff_id SERIAL NOT NULL,
    amka CHAR(11) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    hire_date DATE NOT NULL,
    staff_type VARCHAR(20) NOT NULL,  -- Discriminator ISA ιεραρχίας
    CONSTRAINT pk_staff PRIMARY KEY (staff_id),
    CONSTRAINT uq_staff_amka UNIQUE (amka),
    CONSTRAINT uq_staff_email UNIQUE (email),
    CONSTRAINT uq_staff_phone UNIQUE (phone),
    CONSTRAINT chk_staff_dob_min CHECK (date_of_birth >= CURRENT_DATE - INTERVAL '105 years'),
    CONSTRAINT chk_staff_dob_max CHECK (date_of_birth <= (CURRENT_DATE - INTERVAL '18 years')),
    CONSTRAINT chk_hire_not_future CHECK (hire_date <= CURRENT_DATE),
    CONSTRAINT chk_hire_min CHECK (hire_date >= CURRENT_SETTING('app.hospital_founded')::DATE),
    CONSTRAINT chk_hire_after_dob CHECK (hire_date >= (date_of_birth + INTERVAL '18 years')),
    CONSTRAINT chk_staff_type CHECK (staff_type IN ('Ιατρός', 'Νοσηλευτής', 'Διοικητικό Προσωπικό'))
);

-- Πίνακας Ειδικοτήτων Ιατρών
CREATE TABLE doctor_specialty (name VARCHAR(100) PRIMARY KEY);

-- Ιατροί (staff - subtype)
CREATE TABLE doctor (
    staff_id INT NOT NULL,
    license_number VARCHAR(50) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    rank VARCHAR(20)  NOT NULL,
    supervisor_id INT,
    CONSTRAINT pk_doctor PRIMARY KEY (staff_id),
    CONSTRAINT uq_doctor_license UNIQUE (license_number),
    CONSTRAINT chk_doctor_rank CHECK (rank IN ('Ειδικευόμενος', 'Επιμελητής Β', 'Επιμελητής Α', 'Διευθυντής')),
    CONSTRAINT chk_director_no_supervisor CHECK (rank <> 'Διευθυντής' OR supervisor_id IS NULL),
    CONSTRAINT chk_resident_has_supervisor CHECK (rank <> 'Ειδικευόμενος' OR supervisor_id IS NOT NULL),
    CONSTRAINT chk_doctor_no_self_supervisor CHECK (supervisor_id <> staff_id),
    CONSTRAINT fk_doctor_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_doctor_supervisor FOREIGN KEY (supervisor_id) REFERENCES doctor (staff_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_doctor_specialty FOREIGN KEY (specialty) REFERENCES doctor_specialty (name) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Ιατρός - Διευθυντής Τμήματος (deferred για bootstrapping)
ALTER TABLE department
    ADD CONSTRAINT fk_dept_director
        FOREIGN KEY (director_id) REFERENCES doctor (staff_id) ON DELETE RESTRICT ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;

-- Ειδικότητες Ανά Τμήμα
CREATE TABLE department_specialty (
    department_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    CONSTRAINT pk_dept_specialty PRIMARY KEY (department_name, specialty),
    CONSTRAINT fk_ds_department FOREIGN KEY (department_name) REFERENCES department (department_name) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_ds_specialty FOREIGN KEY (specialty) REFERENCES doctor_specialty (name) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Ιατρός ανά Τμήμα (M:N)
CREATE TABLE doctor_department (
    doctor_id INT NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_doctor_department PRIMARY KEY (doctor_id, department_name),
    CONSTRAINT fk_dd_doctor FOREIGN KEY (doctor_id) REFERENCES doctor (staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_dd_dept FOREIGN KEY (department_name) REFERENCES department (department_name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Νοσηλευτές (staff - subtype)
CREATE TABLE nurse (
    staff_id INT NOT NULL,
    nurse_rank VARCHAR(20) NOT NULL CHECK (nurse_rank IN ('Βοηθός Νοσηλευτή', 'Νοσηλευτής', 'Προϊστάμενος')),
    department_name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_nurse PRIMARY KEY (staff_id),
    CONSTRAINT fk_nurse_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_nurse_dept FOREIGN KEY (department_name) REFERENCES department (department_name) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Πίνακας Ρόλων Διοικητικού Προσωπικού
CREATE TABLE admin_role (name VARCHAR(100) PRIMARY KEY);

-- Διοικητικό Προσωπικό (staff - subtype)
CREATE TABLE admin_staff (
    staff_id INT NOT NULL,
    role VARCHAR(100) NOT NULL,
    office VARCHAR(100),
    department_name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_admin_staff PRIMARY KEY (staff_id),
    CONSTRAINT fk_admin_role FOREIGN KEY (role) REFERENCES admin_role (name) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_admin_staff_s FOREIGN KEY (staff_id) REFERENCES staff (staff_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_admin_staff_dept FOREIGN KEY (department_name) REFERENCES department (department_name) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- ΕΝΟΤΗΤΑ 3: PHARMACY

-- Πίνακας Δραστικών Ουσίων
CREATE TABLE active_substance (
    name VARCHAR(200) NOT NULL,
    CONSTRAINT pk_active_substance PRIMARY KEY (name)
);

-- Πίνακας Φαρμάκων (EMA Article 57)
CREATE TABLE drug (
    drug_code VARCHAR(30) NOT NULL,
    name VARCHAR(200) NOT NULL,
    CONSTRAINT pk_drug PRIMARY KEY (drug_code),
    CONSTRAINT uq_drug_name UNIQUE (name)
);

-- Δραστικές Ουσίες ανά Φάρμακο
CREATE TABLE drug_substance (
    drug_code VARCHAR(30) NOT NULL,
    active_substance_name VARCHAR(200) NOT NULL,
    CONSTRAINT pk_drug_substance PRIMARY KEY (drug_code, active_substance_name),
    CONSTRAINT fk_ds_drug FOREIGN KEY (drug_code) REFERENCES drug (drug_code) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_ds_substance FOREIGN KEY (active_substance_name) REFERENCES active_substance (name) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- ΕΝΟΤΗΤΑ 4: PATIENTS

-- Κεντρικό ευρετήριο ασθενών (Master Patient Index)
CREATE TABLE patient (
    patient_id  SERIAL NOT NULL,
    amka CHAR(11),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    fathers_name VARCHAR(50),
    dob DATE CHECK (dob <= CURRENT_DATE AND dob >= CURRENT_DATE - INTERVAL '120 years'),
    gender VARCHAR(10) CHECK (gender IN ('Άνδρας', 'Γυναίκα', 'Άλλο')),
    street VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(10),
    phone VARCHAR(20),
    email VARCHAR(100),
    occupation VARCHAR(100),
    nationality CHAR(2),
    insurer_id INT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT pk_patient PRIMARY KEY (patient_id),
    CONSTRAINT uq_patient_amka UNIQUE (amka),
    CONSTRAINT fk_patient_country FOREIGN KEY (nationality) REFERENCES country (country_code) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_patient_insurer FOREIGN KEY (insurer_id) REFERENCES insurer (insurer_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Πρόσωπα Επαφής Έκτακτης Ανάγκης (ανεξάρτητη οντότητα)
CREATE TABLE emergency_contact (
    contact_id SERIAL NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    fathers_name VARCHAR(50),
    phone VARCHAR(20) NOT NULL,
    CONSTRAINT pk_emergency_contact PRIMARY KEY (contact_id)
);

-- Junction: Ασθενής ↔ Πρόσωπο Επαφής (M:N)
CREATE TABLE patient_emergency_contact (
    patient_id INT NOT NULL,
    contact_id INT NOT NULL,
    relation VARCHAR(50),
    CONSTRAINT pk_pec PRIMARY KEY (patient_id, contact_id),
    CONSTRAINT fk_pec_patient FOREIGN KEY (patient_id) REFERENCES patient (patient_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pec_contact FOREIGN KEY (contact_id) REFERENCES emergency_contact (contact_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Αλλεργίες ασθενή σε δραστικές ουσίες
CREATE TABLE patient_allergy (
    allergy_id SERIAL NOT NULL,
    patient_id INT NOT NULL,
    active_substance VARCHAR(200) NOT NULL,
    CONSTRAINT pk_patient_allergy PRIMARY KEY (allergy_id),
    CONSTRAINT uq_pa_patient_subst UNIQUE (patient_id, active_substance),
    CONSTRAINT fk_pa_patient FOREIGN KEY (patient_id) REFERENCES patient (patient_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pa_substance FOREIGN KEY (active_substance) REFERENCES active_substance (name) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- ΕΝΟΤΗΤΑ 5: TRIAGE

-- Στοιχεία Διαλογής στο «Τμήμα Επειγόντων Περιστατικών»
CREATE TABLE triage (
    triage_id SERIAL NOT NULL,
    patient_id INT NOT NULL,
    nurse_id INT NOT NULL,
    referred_dept_name VARCHAR(100),
    arrival_time TIMESTAMP NOT NULL,
    symptoms TEXT NOT NULL,
    urgency_level INT NOT NULL CHECK (urgency_level BETWEEN 1 AND 5),
    weight DECIMAL(5,2) CHECK (weight > 0),
    height DECIMAL(5,2) CHECK (height > 0),
    outcome VARCHAR(50) CHECK (outcome IN ('αποχώρησε με οδηγίες', 'παραπομπή για νοσηλεία')),
    CONSTRAINT pk_triage PRIMARY KEY (triage_id),
    CONSTRAINT fk_tr_patient FOREIGN KEY (patient_id) REFERENCES patient (patient_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_tr_nurse FOREIGN KEY (nurse_id) REFERENCES nurse (staff_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_tr_dept FOREIGN KEY (referred_dept_name) REFERENCES department (department_name)    ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_triage_referral CHECK ((outcome = 'παραπομπή για νοσηλεία' AND referred_dept_name IS NOT NULL) OR (outcome = 'αποχώρησε με οδηγίες' AND referred_dept_name IS NULL) OR outcome IS NULL)
);


-- ΕΝΟΤΗΤΑ 6: HOSPITALIZATION

-- Κωδικοί ΚΕΝ (DRG) - Κοστολόγηση Νοσηλείας
CREATE TABLE ken_code (
    ken_code          VARCHAR(20)  NOT NULL,
    description       TEXT         NOT NULL,
    avg_duration_days INT,                        -- Μέση Διάρκεια Νοσηλείας
    base_cost         NUMERIC(10,2),              -- Βασική τιμή αποζημίωσης
    daily_extra       NUMERIC(10,2) DEFAULT 0,    -- Πρόσθετο ημερήσιο κόστος μετά τη μέση διάρκεια
    CONSTRAINT pk_ken_code PRIMARY KEY (ken_code)
);

-- Κωδικοί ICD-10 - Κωδικοποίηση Διαγνώσεων
CREATE TABLE icd10_code (
    icd10_code VARCHAR(10) NOT NULL,
    description VARCHAR(200) NOT NULL,
    category VARCHAR(60) NOT NULL,
    CONSTRAINT pk_icd10_code PRIMARY KEY (icd10_code)
);

CREATE TABLE medical_procedure (
    procedure_code  VARCHAR(20) NOT NULL,
    description     TEXT        NOT NULL,
    category        VARCHAR(50),
    CONSTRAINT pk_procedure PRIMARY KEY (procedure_code)
);

-- ── 2. ΕΡΓΑΣΤΗΡΙΑΚΕΣ ΕΞΕΤΑΣΕΙΣ

CREATE TABLE lab_exam (
    lab_code        VARCHAR(20) NOT NULL,
    description     TEXT        NOT NULL,
    CONSTRAINT pk_lab_exam PRIMARY KEY (lab_code)
);

-- Νοσηλείες Ασθενών
CREATE TABLE hospitalization (
    hospitalization_id SERIAL NOT NULL,
    patient_id  INT NOT NULL,
    triage_id INT NOT NULL,
    bed_id INT NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    admission_date DATE NOT NULL,
    discharge_date DATE,
    admission_diag_icd10 VARCHAR(10),
    discharge_diag_icd10 VARCHAR(10),
    ken_code VARCHAR(10),
    total_cost DECIMAL(10,2) CHECK (total_cost >= 0),
    CONSTRAINT pk_hospitalization PRIMARY KEY (hospitalization_id),
    CONSTRAINT uq_hosp_triage UNIQUE (triage_id),
    CONSTRAINT chk_hosp_dates CHECK (discharge_date IS NULL OR discharge_date >= admission_date),
    CONSTRAINT chk_hosp_discharge_diag CHECK (discharge_date IS NULL OR discharge_diag_icd10 IS NOT NULL),
    CONSTRAINT fk_hosp_patient FOREIGN KEY (patient_id) REFERENCES patient (patient_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_triage FOREIGN KEY (triage_id) REFERENCES triage (triage_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_bed FOREIGN KEY (bed_id, department_name) REFERENCES department_beds (bed_id, department_name) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_dept FOREIGN KEY (department_name) REFERENCES department (department_name) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_ken_code FOREIGN KEY (ken_code) REFERENCES ken_code (ken_code) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_icd10_in FOREIGN KEY (admission_diag_icd10) REFERENCES icd10_code (icd10_code) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_icd10_out FOREIGN KEY (discharge_diag_icd10) REFERENCES icd10_code (icd10_code) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Junction: Νοσηλεία ↔ Προσωπικό
CREATE TABLE hospitalization_staff (
    hospitalization_id INT NOT NULL,
    staff_id INT NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (role IN ('Θεράπων Ιατρός', 'Σύμβουλος Ιατρός', 'Υπεύθυνος Νοσηλευτής')),
    assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_hosp_staff PRIMARY KEY (hospitalization_id, staff_id),
    CONSTRAINT fk_hs_hospitalization FOREIGN KEY (hospitalization_id) REFERENCES hospitalization (hospitalization_id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_hs_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- ΕΝΟΤΗΤΑ 7: LAB & OPERATIONS

-- Χειρουργεία / Αίθουσες Επεμβάσεων
CREATE TABLE operating_room (
    room_id  SERIAL NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(30) NOT NULL CHECK (type IN ('Χειρουργείο', 'Αίθουσα επέμβασης')),
    building VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN ('Διαθέσιμη', 'Κατειλημμένη', 'Υπό Συντήρηση')),
    CONSTRAINT pk_operating_room PRIMARY KEY (room_id)
);

-- Ιατρικές Πράξεις / Επεμβάσεις ανά Νοσηλεία
CREATE TABLE IF NOT EXISTS hospitalization_procedure (
    hosp_procedure_id  SERIAL      NOT NULL,
    hospitalization_id INT         NOT NULL,
    procedure_code     VARCHAR(20) NOT NULL,
    performed_date     DATE        NOT NULL,
    performed_by       INT         NOT NULL,
    notes              TEXT,
    room            INT,
    CONSTRAINT pk_hosp_proc PRIMARY KEY (hosp_procedure_id),
    CONSTRAINT fk_hp_hosp FOREIGN KEY (hospitalization_id) REFERENCES hospitalization (hospitalization_id),
    CONSTRAINT fk_hp_proc FOREIGN KEY (procedure_code)     REFERENCES medical_procedure (procedure_code),
    CONSTRAINT fk_hp_doc  FOREIGN KEY (performed_by)       REFERENCES doctor (staff_id),
    CONSTRAINT fk_hp_room  FOREIGN KEY (room)       REFERENCES operating_room (room_id)
);

-- Βοηθοί Επεμβάσεων (ιατροί ή νοσηλευτές)
CREATE TABLE procedure_participant (
    hosp_procedure_id INT NOT NULL,
    staff_id INT NOT NULL,
    role VARCHAR(100),
    CONSTRAINT pk_procedure_participant PRIMARY KEY (hosp_procedure_id, staff_id), -- FIXED
    CONSTRAINT fk_pp_procedure FOREIGN KEY (hosp_procedure_id) REFERENCES hospitalization_procedure (hosp_procedure_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pp_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Εργαστηριακές Εξετάσεις ανά Νοσηλεία
-- Εργαστηριακές Εξετάσεις ανά Νοσηλεία
CREATE TABLE IF NOT EXISTS hospitalization_lab (
    hosp_lab_id        SERIAL      NOT NULL,
    hospitalization_id INT         NOT NULL,
    lab_code           VARCHAR(20) NOT NULL,
    ordered_date       DATE        NOT NULL,
    result_date        DATE,
    result_value       TEXT,
    result_unit        VARCHAR(30),
    ordered_by         INT         NOT NULL,
    CONSTRAINT pk_hosp_lab PRIMARY KEY (hosp_lab_id),
    CONSTRAINT fk_hl_hosp FOREIGN KEY (hospitalization_id) REFERENCES hospitalization (hospitalization_id),
    CONSTRAINT fk_hl_lab  FOREIGN KEY (lab_code)           REFERENCES lab_exam (lab_code),
    CONSTRAINT fk_hl_doc  FOREIGN KEY (ordered_by)         REFERENCES doctor (staff_id)
);


-- ΕΝΟΤΗΤΑ 8: PRESCRIPTIONS

-- Συνταγογραφήσεις Φαρμάκων
CREATE TABLE prescription (
    prescription_id SERIAL NOT NULL,
    doctor_id INT NOT NULL,
    patient_id INT NOT NULL,
    drug_code VARCHAR(30) NOT NULL,
    hospitalization_id INT NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CONSTRAINT pk_prescription PRIMARY KEY (prescription_id),
    CONSTRAINT uq_prescription UNIQUE (doctor_id, patient_id, drug_code, start_date),
    CONSTRAINT chk_pr_dates CHECK (end_date >= start_date),
    CONSTRAINT fk_pr_doctor FOREIGN KEY (doctor_id) REFERENCES doctor (staff_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pr_patient FOREIGN KEY (patient_id) REFERENCES patient (patient_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pr_drug FOREIGN KEY (drug_code) REFERENCES drug (drug_code) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pr_hosp FOREIGN KEY (hospitalization_id) REFERENCES hospitalization (hospitalization_id) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- ΕΝΟΤΗΤΑ 9: SHIFT SCHEDULING

-- Εφημερίες κάθε Τμήματος
CREATE TABLE shifts (
    shift_id SERIAL NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    shift_date  DATE NOT NULL,
    shift_type VARCHAR(60) NOT NULL CHECK (shift_type IN ('Πρωινή Βάρδια (07:00-15:00)', 'Απογευματινή Βάρδια (15:00-23:00)', 'Νυχτερινή Βάρδια (23:00-07:00)')),
    CONSTRAINT pk_shift PRIMARY KEY (shift_id),
    CONSTRAINT uq_shift UNIQUE (department_name, shift_date, shift_type),
    CONSTRAINT fk_shift_dept FOREIGN KEY (department_name) REFERENCES department (department_name) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Μέλη Προσωπικού ανά Εφημερία
CREATE TABLE shift_staff (
    shift_id INT NOT NULL,
    staff_id INT NOT NULL,
    CONSTRAINT pk_shift_staff PRIMARY KEY (shift_id, staff_id),
    CONSTRAINT fk_ss_shift FOREIGN KEY (shift_id) REFERENCES shifts (shift_id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_ss_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id)  ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ΕΝΟΤΗΤΑ 10: REVIEWS

-- Αξιολόγηση Νοσηλείας
CREATE TABLE patient_hospitalization_review (
    hospitalization_review_id SERIAL NOT NULL,
    hospitalization_id INT NOT NULL,
    nursing_care_score INT NOT NULL CHECK (nursing_care_score BETWEEN 1 AND 5),
    cleanliness_score INT NOT NULL CHECK (cleanliness_score BETWEEN 1 AND 5),
    food_score INT NOT NULL CHECK (food_score BETWEEN 1 AND 5),
    overall_score INT NOT NULL CHECK (overall_score BETWEEN 1 AND 5),
    CONSTRAINT pk_phr PRIMARY KEY (hospitalization_review_id),
    CONSTRAINT uq_phr_hosp UNIQUE (hospitalization_id),
    CONSTRAINT fk_phr_hosp FOREIGN KEY (hospitalization_id) REFERENCES hospitalization (hospitalization_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Αξιολόγηση Ιατρού
CREATE TABLE patient_doctor_review (
    doctor_review_id SERIAL NOT NULL,
    hospitalization_id INT NOT NULL,
    doctor_id INT NOT NULL,
    medical_care_score INT NOT NULL CHECK (medical_care_score BETWEEN 1 AND 5),
    CONSTRAINT pk_pdr PRIMARY KEY (doctor_review_id),
    CONSTRAINT uq_pdr_hosp_doc UNIQUE (hospitalization_id, doctor_id),
    CONSTRAINT fk_pdr_hosp FOREIGN KEY (hospitalization_id) REFERENCES hospitalization (hospitalization_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pdr_doctor FOREIGN KEY (doctor_id) REFERENCES doctor (staff_id) ON DELETE RESTRICT ON UPDATE CASCADE
);


-- ΕΝΟΤΗΤΑ 11: MEDIA

-- Εικόνες
CREATE TABLE image (
    image_id INT GENERATED ALWAYS AS IDENTITY,
    is_public BOOLEAN DEFAULT TRUE,
    department_name VARCHAR(100) DEFAULT NULL,
    staff_id INT DEFAULT NULL,
    patient_id INT DEFAULT NULL,
    room_id INT DEFAULT NULL,
    drug_code VARCHAR(30) DEFAULT NULL,
    active_substance VARCHAR(200) DEFAULT NULL,
    allergy_id INT DEFAULT NULL,
    bed_id INT DEFAULT NULL,
    url VARCHAR(255) NOT NULL,
    caption VARCHAR(255) NOT NULL,
    CONSTRAINT pk_image PRIMARY KEY (image_id),
    CONSTRAINT fk_img_dept FOREIGN KEY (department_name) REFERENCES department (department_name) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_img_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_img_patient FOREIGN KEY (patient_id) REFERENCES patient (patient_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_img_room FOREIGN KEY (room_id) REFERENCES operating_room (room_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_img_drug FOREIGN KEY (drug_code) REFERENCES drug (drug_code) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_img_subst FOREIGN KEY (active_substance) REFERENCES active_substance (name) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_img_allergy FOREIGN KEY (allergy_id) REFERENCES patient_allergy (allergy_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_img_bed FOREIGN KEY (bed_id) REFERENCES department_beds (bed_id) ON DELETE SET NULL ON UPDATE CASCADE
);



-- ΜΕΡΟΣ Ε: FUNCTIONS & TRIGGERS

-- ΕΝΟΤΗΤΑ 1: HOSPITAL DEPARTMENTS

-- #01 | trg_department_director_check
CREATE OR REPLACE FUNCTION fn_department_director_check()
RETURNS TRIGGER AS $$
DECLARE
    v_rank VARCHAR(30);
    v_other_dept_name VARCHAR(100);
BEGIN
    IF NEW.director_id IS NOT NULL THEN

        SELECT "rank" INTO v_rank
        FROM doctor
        WHERE staff_id = NEW.director_id;

        IF v_rank IS NULL THEN
            RAISE EXCEPTION
                'Ο staff_id=% δεν είναι ιατρός και δεν μπορεί να οριστεί Διευθυντής τμήματος.',
                NEW.director_id;
        END IF;

        IF v_rank <> 'Διευθυντής' THEN
            RAISE EXCEPTION
                'Ο ιατρός (staff_id=%) έχει βαθμό "%" — απαιτείται βαθμός "Διευθυντής".',
                NEW.director_id, v_rank;
        END IF;

        SELECT department_name INTO v_other_dept_name
        FROM department
        WHERE director_id = NEW.director_id
          AND department_name <> NEW.department_name
        LIMIT 1;

        IF FOUND THEN
            RAISE EXCEPTION
                'Ο ιατρός (staff_id=%) ήδη διευθύνει το τμήμα "%".',
                NEW.director_id, v_other_dept_name;
        END IF;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_department_director_check ON department;

CREATE TRIGGER trg_department_director_check
BEFORE INSERT OR UPDATE ON department
FOR EACH ROW
EXECUTE FUNCTION fn_department_director_check();

-- #02 | trg_doctor_specialty_in_department
CREATE OR REPLACE FUNCTION fn_check_doctor_specialty_in_department()
RETURNS TRIGGER AS $$
DECLARE
    v_specialty VARCHAR(100);
BEGIN
    SELECT specialty INTO v_specialty
    FROM doctor WHERE staff_id = NEW.doctor_id;

    IF NOT EXISTS (
        SELECT 1
        FROM department_specialty
        WHERE department_name = NEW.department_name
        AND specialty = v_specialty
    ) THEN
        RAISE EXCEPTION
            'Η ειδικότητα "%" δεν επιτρέπεται στο τμήμα "%".',
            v_specialty, NEW.department_name;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_doctor_specialty_in_department
BEFORE INSERT OR UPDATE ON doctor_department
FOR EACH ROW EXECUTE FUNCTION fn_check_doctor_specialty_in_department();


-- #03 | trg_one_director_per_department
CREATE OR REPLACE FUNCTION fn_check_one_director_per_department()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT rank FROM doctor WHERE staff_id = NEW.doctor_id) = 'Διευθυντής' THEN
        IF EXISTS (
            SELECT 1
            FROM doctor_department dd
            JOIN doctor d ON dd.doctor_id = d.staff_id
            WHERE dd.department_name = NEW.department_name
            AND d.rank = 'Διευθυντής'
            AND dd.doctor_id <> NEW.doctor_id
        ) THEN
            RAISE EXCEPTION
                'Το τμήμα "%" έχει ήδη Διευθυντή.',
                NEW.department_name;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_one_director_per_department
BEFORE INSERT OR UPDATE ON doctor_department
FOR EACH ROW EXECUTE FUNCTION fn_check_one_director_per_department();


-- ΕΝΟΤΗΤΑ 2: STAFF — ISA / Subtypes

-- #04 | trg_staff_has_subtype
CREATE OR REPLACE FUNCTION fn_check_staff_has_subtype()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM doctor WHERE staff_id = NEW.staff_id) AND
       NOT EXISTS (SELECT 1 FROM nurse WHERE staff_id = NEW.staff_id) AND
       NOT EXISTS (SELECT 1 FROM admin_staff WHERE staff_id = NEW.staff_id)
    THEN
        RAISE EXCEPTION
            'Staff % δεν ανήκει σε κανένα subtype.',
            NEW.staff_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_staff_has_subtype
AFTER INSERT OR UPDATE ON staff
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_staff_has_subtype();


-- #05 / #06 / #07 | trg_doctor_matches_type / trg_nurse_matches_type / trg_admin_matches_type
CREATE OR REPLACE FUNCTION fn_check_subtype_matches_type()
RETURNS TRIGGER AS $$
DECLARE
    v_staff_type VARCHAR(25);
BEGIN
    SELECT staff_type INTO v_staff_type
    FROM staff WHERE staff_id = NEW.staff_id;

    IF TG_TABLE_NAME = 'doctor' AND v_staff_type <> 'Ιατρός' THEN
        RAISE EXCEPTION
            'Ο staff % δεν είναι ιατρός (staff_type=%).',
            NEW.staff_id, v_staff_type;
    END IF;

    IF TG_TABLE_NAME = 'nurse' AND v_staff_type <> 'Νοσηλευτής' THEN
        RAISE EXCEPTION
            'Ο staff % δεν είναι νοσηλευτής (staff_type=%).',
            NEW.staff_id, v_staff_type;
    END IF;

    IF TG_TABLE_NAME = 'admin_staff' AND v_staff_type <> 'Διοικητικό Προσωπικό' THEN
        RAISE EXCEPTION
            'Ο staff % δεν είναι διοικητικό προσωπικό (staff_type=%).',
            NEW.staff_id, v_staff_type;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_doctor_matches_type
BEFORE INSERT OR UPDATE ON doctor
FOR EACH ROW EXECUTE FUNCTION fn_check_subtype_matches_type();

CREATE TRIGGER trg_nurse_matches_type
BEFORE INSERT OR UPDATE ON nurse
FOR EACH ROW EXECUTE FUNCTION fn_check_subtype_matches_type();

CREATE TRIGGER trg_admin_matches_type
BEFORE INSERT OR UPDATE ON admin_staff
FOR EACH ROW EXECUTE FUNCTION fn_check_subtype_matches_type();


-- #08 | trg_doctor_supervisor_check
CREATE OR REPLACE FUNCTION fn_doctor_supervisor_check()
RETURNS TRIGGER AS $$
DECLARE
    v_check_id INT;
    v_depth INT := 0;
    v_supervisor_rank VARCHAR(30);
    v_rank_order INT;
    v_supervisor_order INT;
BEGIN
    IF NEW.supervisor_id IS NOT NULL THEN

        -- Κυκλική αλυσίδα εποπτείας
        v_check_id := NEW.supervisor_id;
        LOOP
            SELECT supervisor_id INTO v_check_id
            FROM doctor WHERE staff_id = v_check_id;

            EXIT WHEN v_check_id IS NULL;

            v_depth := v_depth + 1;
            IF v_depth > 20 THEN
                RAISE EXCEPTION
                    'Κυκλική αλυσίδα εποπτείας ανιχνεύθηκε για staff_id=%.',
                    NEW.staff_id;
            END IF;

            IF v_check_id = NEW.staff_id THEN
                RAISE EXCEPTION
                    'Κυκλική αλυσίδα εποπτείας: staff_id=% εμφανίζεται στην αλυσίδα.',
                    NEW.staff_id;
            END IF;
        END LOOP;

        -- Επόπτης πρέπει να είναι ανώτερης βαθμίδας
        SELECT rank INTO v_supervisor_rank
        FROM doctor WHERE staff_id = NEW.supervisor_id;

        v_rank_order := CASE NEW.rank
            WHEN 'Ειδικευόμενος' THEN 1
            WHEN 'Επιμελητής Β'  THEN 2
            WHEN 'Επιμελητής Α'  THEN 3
            WHEN 'Διευθυντής'    THEN 4
        END;

        v_supervisor_order := CASE v_supervisor_rank
            WHEN 'Ειδικευόμενος' THEN 1
            WHEN 'Επιμελητής Β'  THEN 2
            WHEN 'Επιμελητής Α'  THEN 3
            WHEN 'Διευθυντής'    THEN 4
        END;

        IF v_supervisor_order <= v_rank_order THEN
            RAISE EXCEPTION
                'Ο επόπτης (rank=%) πρέπει να είναι ανώτερης βαθμίδας από τον εποπτευόμενο (rank=%).',
                v_supervisor_rank, NEW.rank;
        END IF;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_doctor_supervisor_check
BEFORE INSERT OR UPDATE ON doctor
FOR EACH ROW EXECUTE FUNCTION fn_doctor_supervisor_check();


-- #09 | trg_supervisor_same_department
CREATE OR REPLACE FUNCTION fn_check_supervisor_same_department()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.supervisor_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Αν ο ιατρός δεν έχει ακόμα τμήμα, παράλειψε
    IF NOT EXISTS (
        SELECT 1 FROM doctor_department WHERE doctor_id = NEW.staff_id
    ) THEN
        RETURN NEW;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM doctor_department dd1
        JOIN doctor_department dd2 ON dd1.department_name = dd2.department_name
        WHERE dd1.doctor_id = NEW.staff_id
        AND   dd2.doctor_id = NEW.supervisor_id
    ) THEN
        RAISE EXCEPTION
            'Ο επόπτης (staff_id=%) δεν ανήκει στο ίδιο τμήμα με τον εποπτευόμενο (staff_id=%).',
            NEW.supervisor_id, NEW.staff_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_supervisor_same_department
AFTER INSERT OR UPDATE OF supervisor_id ON doctor
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_check_supervisor_same_department();

-- ΕΝΟΤΗΤΑ 4: PATIENTS

-- #11 | trg_patient_updated_at
CREATE OR REPLACE FUNCTION fn_patient_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patient_updated_at
BEFORE UPDATE ON patient
FOR EACH ROW EXECUTE FUNCTION fn_patient_updated_at();


-- #12 | fn_patient_completeness_check (utility function, not a trigger)
CREATE OR REPLACE FUNCTION fn_patient_completeness_check(p_patient_id INT)
RETURNS VOID AS $$
DECLARE
    v_patient patient%ROWTYPE;
    v_has_triage BOOLEAN;
BEGIN
    SELECT * INTO v_patient
    FROM patient WHERE patient_id = p_patient_id;

    IF v_patient.first_name IS NULL THEN
        RAISE EXCEPTION 'Λείπει first_name για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.last_name IS NULL THEN
        RAISE EXCEPTION 'Λείπει last_name για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.dob IS NULL THEN
        RAISE EXCEPTION 'Λείπει dob για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.gender IS NULL THEN
        RAISE EXCEPTION 'Λείπει gender για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.street IS NULL THEN
        RAISE EXCEPTION 'Λείπει street για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.city IS NULL THEN
        RAISE EXCEPTION 'Λείπει city για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.postal_code IS NULL THEN
        RAISE EXCEPTION 'Λείπει postal_code για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.phone IS NULL THEN
        RAISE EXCEPTION 'Λείπει phone για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.email IS NULL THEN
        RAISE EXCEPTION 'Λείπει email για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.nationality IS NULL THEN
        RAISE EXCEPTION 'Λείπει nationality για patient_id=%.', p_patient_id;
    END IF;

    IF v_patient.insurer_id IS NULL THEN
        RAISE EXCEPTION 'Λείπει insurer_id για patient_id=%.', p_patient_id;
    END IF;

    -- AMKA υποχρεωτικό μόνο για Έλληνες
    IF v_patient.nationality = 'GR' AND v_patient.amka IS NULL THEN
        RAISE EXCEPTION
            'Ο Έλληνας ασθενής (patient_id=%) πρέπει να έχει AMKA.',
            p_patient_id;
    END IF;

    -- Weight και height υποχρεωτικά από triage
    SELECT EXISTS (
        SELECT 1 FROM triage
        WHERE patient_id = p_patient_id
        AND weight IS NOT NULL
        AND height IS NOT NULL
    ) INTO v_has_triage;

    IF NOT v_has_triage THEN
        RAISE EXCEPTION
            'Ο ασθενής (patient_id=%) δεν έχει weight/height από διαλογή.',
            p_patient_id;
    END IF;

END;
$$ LANGUAGE plpgsql;

-- #13 | trg_patient_discharge_check
CREATE OR REPLACE FUNCTION fn_patient_discharge_check()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.discharge_date IS NULL OR OLD.discharge_date IS NOT NULL THEN
        RETURN NEW;
    END IF;

    PERFORM fn_patient_completeness_check(NEW.patient_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patient_discharge_check
BEFORE UPDATE OF discharge_date ON hospitalization
FOR EACH ROW EXECUTE FUNCTION fn_patient_discharge_check();


-- #14 | trg_patient_prescription_check
CREATE OR REPLACE FUNCTION fn_patient_prescription_check()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM fn_patient_completeness_check(NEW.patient_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patient_prescription_check
BEFORE INSERT ON prescription
FOR EACH ROW EXECUTE FUNCTION fn_patient_prescription_check();


-- #15 | trg_patient_amka_gr_check
CREATE OR REPLACE FUNCTION fn_patient_amka_gr_check()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.nationality = 'GR' AND NEW.amka IS NULL THEN
        IF EXISTS (SELECT 1 FROM hospitalization WHERE patient_id = NEW.patient_id) OR
           EXISTS (SELECT 1 FROM prescription WHERE patient_id = NEW.patient_id)
        THEN
            RAISE EXCEPTION
                'Ο ασθενής (patient_id=%) έχει ελληνική υπηκοότητα και πρέπει να έχει AMKA.',
                NEW.patient_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patient_amka_gr_check
BEFORE UPDATE OF nationality, amka ON patient
FOR EACH ROW EXECUTE FUNCTION fn_patient_amka_gr_check();


-- ΕΝΟΤΗΤΑ 5: TRIAGE

-- #16 | trg_triage_nurse_in_emergency
CREATE OR REPLACE FUNCTION fn_triage_nurse_in_emergency()
RETURNS TRIGGER AS $$
DECLARE
    v_department_name VARCHAR(100);
BEGIN
    SELECT department_name INTO v_department_name
    FROM nurse WHERE staff_id = NEW.nurse_id;

    IF v_department_name <> 'Επείγοντα Περιστατικά' THEN
        RAISE EXCEPTION
            'Ο νοσηλευτής (staff_id=%) δεν ανήκει στα Επείγοντα Περιστατικά (τμήμα=%).',
            NEW.nurse_id, v_department_name;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_triage_nurse_in_emergency
BEFORE INSERT OR UPDATE OF nurse_id ON triage
FOR EACH ROW EXECUTE FUNCTION fn_triage_nurse_in_emergency();


-- #17 | trg_triage_single_active
CREATE OR REPLACE FUNCTION fn_triage_single_active()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM triage
        WHERE patient_id = NEW.patient_id
        AND outcome IS NULL
        AND triage_id <> COALESCE(NEW.triage_id, -1)
    ) THEN
        RAISE EXCEPTION
            'Ο ασθενής (patient_id=%) έχει ήδη ανοιχτό triage στην ουρά.',
            NEW.patient_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_triage_single_active
BEFORE INSERT ON triage
FOR EACH ROW EXECUTE FUNCTION fn_triage_single_active();


-- #18 | trg_triage_create_hospitalization
CREATE OR REPLACE FUNCTION fn_triage_create_hospitalization()
RETURNS TRIGGER AS $$
DECLARE
    v_bed_number INT;
BEGIN
    IF NEW.outcome = 'παραπομπή για νοσηλεία' AND
       (OLD.outcome IS NULL OR OLD.outcome <> 'παραπομπή για νοσηλεία')
    THEN
        IF NOT EXISTS (
            SELECT 1 FROM department_beds
            WHERE department_name = NEW.referred_dept_name
            AND status = 'διαθέσιμη'
        ) THEN
            RAISE EXCEPTION
                'Δεν υπάρχει διαθέσιμη κλίνη στο τμήμα "%".',
                NEW.referred_dept_name;
        END IF;

        SELECT bed_id INTO v_bed_number
        FROM department_beds
        WHERE department_name = NEW.referred_dept_name
        AND status = 'διαθέσιμη'
        ORDER BY bed_id
        LIMIT 1;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_triage_create_hospitalization
AFTER UPDATE OF outcome ON triage
FOR EACH ROW EXECUTE FUNCTION fn_triage_create_hospitalization();


-- ΕΝΟΤΗΤΑ 6: HOSPITALIZATION

-- #19 | trg_hosp_bed_dept_match
CREATE OR REPLACE FUNCTION fn_hosp_bed_dept_match()
RETURNS TRIGGER AS $$
DECLARE
    v_bed_dept VARCHAR(100);
BEGIN
    SELECT department_name INTO v_bed_dept
    FROM department_beds WHERE bed_id = NEW.bed_id;

    IF v_bed_dept <> NEW.department_name THEN
        RAISE EXCEPTION
            'Η κλίνη (bed_id=%) ανήκει στο τμήμα "%" — δεν ταιριάζει με τη νοσηλεία (department="%").',
            NEW.bed_id, v_bed_dept, NEW.department_name;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hosp_bed_dept_match
BEFORE INSERT OR UPDATE OF bed_id, department_name ON hospitalization
FOR EACH ROW EXECUTE FUNCTION fn_hosp_bed_dept_match();


-- #20 | trg_hosp_bed_status
CREATE OR REPLACE FUNCTION fn_hosp_bed_status()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.discharge_date IS NULL THEN
            UPDATE department_beds
            SET status = 'κατειλημμένη'
            WHERE bed_id = NEW.bed_id;
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE department_beds b
        SET status =
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM hospitalization h
                    WHERE h.bed_id = (NEW.bed_id, OLD.bed_id)
                      AND h.discharge_date IS NULL
                )
                THEN 'κατειλημμένη'
                ELSE 'διαθέσιμη'
            END
        WHERE b.bed_id = (NEW.bed_id, OLD.bed_id);

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE department_beds b
        SET status =
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM hospitalization h
                    WHERE h.bed_id = OLD.bed_id
                      AND h.discharge_date IS NULL
                )
                THEN 'κατειλημμένη'
                ELSE 'διαθέσιμη'
            END
        WHERE b.bed_id = OLD.bed_id;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hosp_bed_status
AFTER INSERT OR UPDATE ON hospitalization
FOR EACH ROW EXECUTE FUNCTION fn_hosp_bed_status();


-- #21 | trg_hosp_bed_overlap
CREATE OR REPLACE FUNCTION fn_hosp_bed_overlap()
RETURNS TRIGGER AS $$
DECLARE
    v_overlap_count INT;
BEGIN
    SELECT COUNT(*) INTO v_overlap_count
    FROM hospitalization
    WHERE bed_id = NEW.bed_id
    AND hospitalization_id <> COALESCE(NEW.hospitalization_id, -1)
    AND admission_date <= COALESCE(NEW.discharge_date, 'infinity'::DATE)
    AND COALESCE(discharge_date, 'infinity'::DATE) >= NEW.admission_date;

    IF v_overlap_count > 0 THEN
        RAISE EXCEPTION
            'Επικάλυψη νοσηλειών: κλίνη bed_id=% είναι ήδη κατειλημμένη για αυτή την περίοδο.',
            NEW.bed_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hosp_bed_overlap
BEFORE INSERT OR UPDATE ON hospitalization
FOR EACH ROW EXECUTE FUNCTION fn_hosp_bed_overlap();


-- #22 | trg_hosp_discharge_diagnosis
CREATE OR REPLACE FUNCTION fn_hosp_discharge_diagnosis()
RETURNS TRIGGER AS $$
DECLARE
    v_icd_exists INT;
BEGIN
    IF NEW.discharge_date IS NOT NULL AND OLD.discharge_date IS NULL THEN
        IF NEW.discharge_diag_icd10 IS NULL THEN
            RAISE EXCEPTION
                'Δεν επιτρέπεται έξοδος (hospitalization_id=%) χωρίς κωδικό ICD-10 διάγνωσης εξόδου.',
                NEW.hospitalization_id;
        END IF;
        SELECT COUNT(*) INTO v_icd_exists
        FROM icd10_code WHERE icd10_code = NEW.discharge_diag_icd10;
        IF v_icd_exists = 0 THEN
            RAISE EXCEPTION
                'Ο κωδικός ICD-10 "%" δεν υπάρχει στον πίνακα icd10_code (hospitalization_id=%).',
                NEW.discharge_diag_icd10, NEW.hospitalization_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hosp_discharge_diagnosis
BEFORE UPDATE ON hospitalization
FOR EACH ROW EXECUTE FUNCTION fn_hosp_discharge_diagnosis();


-- #23 | trg_hosp_total_cost
CREATE OR REPLACE FUNCTION fn_hosp_total_cost()
RETURNS TRIGGER AS $$
DECLARE
    v_base_cost DECIMAL(10,2);
    v_avg_duration DECIMAL(5,2);
    v_daily_extra DECIMAL(10,2);
    v_days_stayed DECIMAL(10,2);
    v_extra_days DECIMAL(10,2);
BEGIN
    IF NEW.discharge_date IS NOT NULL AND OLD.discharge_date IS NULL THEN
        IF NEW.ken_code IS NOT NULL THEN
            SELECT base_cost, avg_duration_days, daily_extra
            INTO v_base_cost, v_avg_duration, v_daily_extra
            FROM ken_code WHERE ken_code = NEW.ken_code;

            v_days_stayed := (NEW.discharge_date - NEW.admission_date)::DECIMAL;
            v_extra_days := GREATEST(0, v_days_stayed - v_avg_duration);
            NEW.total_cost := v_base_cost + (v_extra_days * v_daily_extra);
        ELSE
            NEW.total_cost := NULL;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hosp_total_cost
BEFORE UPDATE ON hospitalization
FOR EACH ROW EXECUTE FUNCTION fn_hosp_total_cost();


-- ΕΝΟΤΗΤΑ 7: LAB & OPERATIONS

-- FIXED: Τα αρχικά surgery overlap triggers αφαιρέθηκαν ως invalid references.
-- Δεν υπάρχουν room_id/start_time/duration_minutes/lead_doctor_id στο τρέχον data model,
-- άρα δεν προστίθεται νέα λογική χωρίς τεκμηριωμένη στήριξη από το schema.


-- #27 | trg_procedure_during_hosp
CREATE OR REPLACE FUNCTION fn_procedure_during_hosp()
RETURNS TRIGGER AS $$
DECLARE
    v_admission_date DATE;
    v_discharge_date DATE;
BEGIN
    SELECT admission_date, discharge_date
    INTO v_admission_date, v_discharge_date
    FROM hospitalization WHERE hospitalization_id = NEW.hospitalization_id;

    IF NEW.performed_date < v_admission_date THEN
        RAISE EXCEPTION
            'Η πράξη (hosp_procedure_id=%) γίνεται πριν την εισαγωγή (%).',
            NEW.hosp_procedure_id, v_admission_date;
    END IF;

    IF v_discharge_date IS NOT NULL AND NEW.performed_date > v_discharge_date THEN
        RAISE EXCEPTION
            'Η πράξη (hosp_procedure_id=%) γίνεται μετά την έξοδο (%).',
            NEW.hosp_procedure_id, v_discharge_date;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FIXED
CREATE TRIGGER trg_procedure_during_hosp
BEFORE INSERT OR UPDATE ON hospitalization_procedure
FOR EACH ROW EXECUTE FUNCTION fn_procedure_during_hosp();


-- #28 | trg_lab_exam_during_hosp
CREATE OR REPLACE FUNCTION fn_lab_exam_during_hosp()
RETURNS TRIGGER AS $$
DECLARE
    v_admission_date DATE;
    v_discharge_date DATE;
BEGIN
    SELECT admission_date, discharge_date
    INTO v_admission_date, v_discharge_date
    FROM hospitalization WHERE hospitalization_id = NEW.hospitalization_id;

    IF NEW.ordered_date::DATE < v_admission_date THEN
        RAISE EXCEPTION
            'Η εξέταση (exam_id=%) γίνεται πριν την εισαγωγή (%).',
            NEW.hosp_lab_id, v_admission_date;
    END IF;

    IF v_discharge_date IS NOT NULL AND
       NEW.ordered_date::DATE > v_discharge_date THEN
        RAISE EXCEPTION
            'Η εξέταση (exam_id=%) γίνεται μετά την έξοδο (%).',
            NEW.hosp_lab_id, v_discharge_date;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_lab_exam_during_hosp
BEFORE INSERT OR UPDATE ON hospitalization_lab -- FIXED
FOR EACH ROW EXECUTE FUNCTION fn_lab_exam_during_hosp();


-- -- #29 | trg_lab_exam_doctor_in_dept
-- CREATE OR REPLACE FUNCTION fn_lab_exam_doctor_in_dept()
-- RETURNS TRIGGER AS $$
-- DECLARE
--     v_dept_name VARCHAR(100);
-- BEGIN
--     SELECT department_name INTO v_dept_name
--     FROM hospitalization WHERE hospitalization_id = NEW.hospitalization_id;
--
--     IF NOT EXISTS (
--         SELECT 1 FROM doctor_department
--         WHERE doctor_id = NEW.ordered_by
--         AND department_name = v_dept_name
--     ) THEN
--         RAISE EXCEPTION
--             'Ο γιατρός (doctor_id=%) δεν ανήκει στο τμήμα "%" της νοσηλείας.',
--             NEW.ordered_by, v_dept_name;
--     END IF;
--
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
--
-- CREATE TRIGGER trg_lab_exam_doctor_in_dept
-- BEFORE INSERT OR UPDATE ON hospitalization_lab -- FIXED
-- FOR EACH ROW EXECUTE FUNCTION fn_lab_exam_doctor_in_dept();


-- ΕΝΟΤΗΤΑ 8: PRESCRIPTIONS

-- #30 | trg_allergy_check
CREATE OR REPLACE FUNCTION fn_allergy_check()
RETURNS TRIGGER AS $$
DECLARE
    v_conflicting_substance VARCHAR(200);
BEGIN
    SELECT ds.active_substance_name INTO v_conflicting_substance
    FROM drug_substance ds
    JOIN patient_allergy pa ON pa.active_substance = ds.active_substance_name
    WHERE ds.drug_code = NEW.drug_code
    AND pa.patient_id = NEW.patient_id
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION
            'Απαγορευμένη συνταγογράφηση: ο ασθενής (patient_id=%) έχει αλλεργία στη δραστική ουσία "%" (drug_code=%).',
            NEW.patient_id, v_conflicting_substance, NEW.drug_code;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_allergy_check
BEFORE INSERT ON prescription
FOR EACH ROW EXECUTE FUNCTION fn_allergy_check();

-- #32 | trg_prescription_within_hosp
CREATE OR REPLACE FUNCTION fn_prescription_within_hosp()
RETURNS TRIGGER AS $$
DECLARE
    v_admission_date DATE;
    v_discharge_date DATE;
BEGIN
    SELECT admission_date, discharge_date
    INTO v_admission_date, v_discharge_date
    FROM hospitalization WHERE hospitalization_id = NEW.hospitalization_id;

    IF NEW.start_date < v_admission_date THEN
        RAISE EXCEPTION
            'Η ημερομηνία έναρξης συνταγής (%) είναι πριν την εισαγωγή (%).',
            NEW.start_date, v_admission_date;
    END IF;

    IF v_discharge_date IS NOT NULL AND NEW.end_date > v_discharge_date THEN
        RAISE EXCEPTION
            'Η ημερομηνία λήξης συνταγής (%) είναι μετά την έξοδο (%).',
            NEW.end_date, v_discharge_date;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prescription_within_hosp
BEFORE INSERT ON prescription
FOR EACH ROW EXECUTE FUNCTION fn_prescription_within_hosp();


-- ΕΝΟΤΗΤΑ 9: SHIFT SCHEDULING

-- #33 | trg_shift_staff_belongs_to_department
CREATE OR REPLACE FUNCTION fn_shift_staff_belongs_to_department()
RETURNS TRIGGER AS $$
DECLARE
    v_department_name VARCHAR(100);
    v_staff_type VARCHAR(25);
BEGIN
    SELECT department_name INTO v_department_name
    FROM shifts WHERE shift_id = NEW.shift_id;

    SELECT staff_type INTO v_staff_type
    FROM staff WHERE staff_id = NEW.staff_id;

    IF v_staff_type = 'Ιατρός' THEN
        IF NOT EXISTS (
            SELECT 1 FROM doctor_department
            WHERE doctor_id = NEW.staff_id
            AND department_name = v_department_name
        ) THEN
            RAISE EXCEPTION
                'Ο ιατρός (staff_id=%) δεν ανήκει στο τμήμα %.',
                NEW.staff_id, v_department_name;
        END IF;

    ELSIF v_staff_type = 'Νοσηλευτής' THEN
        IF NOT EXISTS (
            SELECT 1 FROM nurse
            WHERE staff_id = NEW.staff_id
            AND department_name = v_department_name
        ) THEN
            RAISE EXCEPTION
                'Ο νοσηλευτής (staff_id=%) δεν ανήκει στο τμήμα %.',
                NEW.staff_id, v_department_name;
        END IF;

    ELSIF v_staff_type = 'Διοικητικό Προσωπικό' THEN
        IF NOT EXISTS (
            SELECT 1 FROM admin_staff
            WHERE staff_id = NEW.staff_id
            AND department_name = v_department_name
        ) THEN
            RAISE EXCEPTION
                'Ο διοικητικός (staff_id=%) δεν ανήκει στο τμήμα %.',
                NEW.staff_id, v_department_name;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_shift_staff_belongs_to_department
BEFORE INSERT ON shift_staff
FOR EACH ROW EXECUTE FUNCTION fn_shift_staff_belongs_to_department();


-- #34 | trg_shift_min_staff
CREATE OR REPLACE FUNCTION fn_shift_min_staff()
RETURNS TRIGGER AS $$
DECLARE
    v_shift_id INT;
    v_doctor_count INT;
    v_nurse_count INT;
    v_admin_count INT;
BEGIN
    v_shift_id := CASE TG_OP WHEN 'DELETE' THEN OLD.shift_id ELSE NEW.shift_id END;

    SELECT COUNT(*) INTO v_doctor_count
    FROM shift_staff ss
    JOIN staff s ON ss.staff_id = s.staff_id
    WHERE ss.shift_id  = v_shift_id
    AND s.staff_type = 'Ιατρός';

    SELECT COUNT(*) INTO v_nurse_count
    FROM shift_staff ss
    JOIN staff s ON ss.staff_id = s.staff_id
    WHERE ss.shift_id  = v_shift_id
    AND s.staff_type = 'Νοσηλευτής';

    SELECT COUNT(*) INTO v_admin_count
    FROM shift_staff ss
    JOIN staff s ON ss.staff_id = s.staff_id
    WHERE ss.shift_id  = v_shift_id
    AND s.staff_type = 'Διοικητικό Προσωπικό';

    IF v_doctor_count < 3 THEN
        RAISE EXCEPTION
            'Βάρδια % έχει % ιατρούς — απαιτούνται τουλάχιστον 3.',
            v_shift_id, v_doctor_count;
    END IF;

    IF v_nurse_count < 6 THEN
        RAISE EXCEPTION
            'Βάρδια % έχει % νοσηλευτές — απαιτούνται τουλάχιστον 6.',
            v_shift_id, v_nurse_count;
    END IF;

    IF v_admin_count < 2 THEN
        RAISE EXCEPTION
            'Βάρδια % έχει % διοικητικούς — απαιτούνται τουλάχιστον 2.',
            v_shift_id, v_admin_count;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_shift_min_staff
AFTER INSERT OR DELETE ON shift_staff
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_shift_min_staff();


-- #35 | trg_shift_resident_needs_senior
CREATE OR REPLACE FUNCTION fn_shift_resident_needs_senior()
RETURNS TRIGGER AS $$
DECLARE
    v_shift_id INT;
    v_has_resident BOOLEAN;
    v_has_senior BOOLEAN;
BEGIN
    v_shift_id := CASE TG_OP WHEN 'DELETE' THEN OLD.shift_id ELSE NEW.shift_id END;

    SELECT EXISTS (
        SELECT 1
        FROM shift_staff ss
        JOIN doctor d ON ss.staff_id = d.staff_id
        WHERE ss.shift_id = v_shift_id
        AND d.rank = 'Ειδικευόμενος'
    ) INTO v_has_resident;

    IF v_has_resident THEN
        SELECT EXISTS (
            SELECT 1
            FROM shift_staff ss
            JOIN doctor d ON ss.staff_id = d.staff_id
            WHERE ss.shift_id = v_shift_id
            AND d.rank IN ('Επιμελητής Α', 'Διευθυντής')
        ) INTO v_has_senior;

        IF NOT v_has_senior THEN
            RAISE EXCEPTION
                'Βάρδια % έχει Ειδικευόμενο αλλά δεν έχει Επιμελητή Α ή Διευθυντή.',
                v_shift_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_shift_resident_needs_senior
AFTER INSERT OR DELETE ON shift_staff
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION fn_shift_resident_needs_senior();


-- #36 | trg_shift_monthly_limit
CREATE OR REPLACE FUNCTION fn_shift_monthly_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_shift_date DATE;
    v_shift_month INT;
    v_shift_year INT;
    v_shift_count INT;
    v_monthly_limit INT;
    v_staff_type VARCHAR(25);
BEGIN
    SELECT shift_date INTO v_shift_date
    FROM shifts WHERE shift_id = NEW.shift_id;

    v_shift_month := EXTRACT(MONTH FROM v_shift_date);
    v_shift_year := EXTRACT(YEAR FROM v_shift_date);

    SELECT staff_type INTO v_staff_type
    FROM staff WHERE staff_id = NEW.staff_id;

    v_monthly_limit := CASE v_staff_type
        WHEN 'Ιατρός' THEN 15
        WHEN 'Νοσηλευτής' THEN 20
        WHEN 'Διοικητικό Προσωπικό' THEN 25
    END;

    SELECT COUNT(*) INTO v_shift_count
    FROM shift_staff ss
    JOIN shifts s ON ss.shift_id = s.shift_id
    WHERE ss.staff_id = NEW.staff_id
    AND EXTRACT(MONTH FROM s.shift_date) = v_shift_month
    AND EXTRACT(YEAR FROM s.shift_date) = v_shift_year;

    IF v_shift_count >= v_monthly_limit THEN
        RAISE EXCEPTION
            'Υπέρβαση μηνιαίου ορίου: staff_id=% έχει % βαρδιές τον %/% (όριο: %).',
            NEW.staff_id, v_shift_count, v_shift_month, v_shift_year, v_monthly_limit;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_shift_monthly_limit
BEFORE INSERT ON shift_staff
FOR EACH ROW EXECUTE FUNCTION fn_shift_monthly_limit();


-- #37 | trg_shift_rest_8h
CREATE OR REPLACE FUNCTION fn_shift_rest_8h()
RETURNS TRIGGER AS $$
DECLARE
    v_new_date DATE;
    v_new_type VARCHAR(60);
    v_new_start TIMESTAMP;
    v_new_end TIMESTAMP;
    rec RECORD;
    v_prev_end TIMESTAMP;
    v_next_start TIMESTAMP;
BEGIN
    SELECT shift_date, shift_type INTO v_new_date, v_new_type
    FROM shifts WHERE shift_id = NEW.shift_id;

    v_new_start := CASE v_new_type
        WHEN 'Π' THEN (v_new_date::TEXT || ' 07:00')::TIMESTAMP
        WHEN 'Α' THEN (v_new_date::TEXT || ' 15:00')::TIMESTAMP
        WHEN 'Ν' THEN (v_new_date::TEXT || ' 23:00')::TIMESTAMP
    END;

    v_new_end := CASE v_new_type
        WHEN 'Π' THEN (v_new_date::TEXT || ' 15:00')::TIMESTAMP
        WHEN 'Α' THEN (v_new_date::TEXT || ' 23:00')::TIMESTAMP
        WHEN 'Ν' THEN ((v_new_date + INTERVAL '1 day')::TEXT || ' 07:00')::TIMESTAMP
    END;

    FOR rec IN
        SELECT s.shift_date, s.shift_type
        FROM shift_staff ss
        JOIN shifts s ON ss.shift_id = s.shift_id
        WHERE ss.staff_id  = NEW.staff_id AND s.shift_date BETWEEN v_new_date - INTERVAL '2 days' AND v_new_date + INTERVAL '2 days'
    LOOP
        v_prev_end := CASE rec.shift_type
            WHEN 'Π' THEN (rec.shift_date::TEXT || ' 15:00')::TIMESTAMP
            WHEN 'Α' THEN (rec.shift_date::TEXT || ' 23:00')::TIMESTAMP
            WHEN 'Ν' THEN ((rec.shift_date + INTERVAL '1 day')::TEXT || ' 07:00')::TIMESTAMP
        END;

        v_next_start := CASE rec.shift_type
            WHEN 'Π' THEN (rec.shift_date::TEXT || ' 07:00')::TIMESTAMP
            WHEN 'Α' THEN (rec.shift_date::TEXT || ' 15:00')::TIMESTAMP
            WHEN 'Ν' THEN (rec.shift_date::TEXT || ' 23:00')::TIMESTAMP
        END;

        IF v_prev_end <= v_new_start AND
           EXTRACT(EPOCH FROM (v_new_start - v_prev_end)) / 3600 < 8 THEN
            RAISE EXCEPTION
                'Παραβίαση 8ω ανάπαυσης: staff_id=% έχει μόνο % ώρες πριν τη νέα βάρδια.',
                NEW.staff_id,
                ROUND((EXTRACT(EPOCH FROM (v_new_start - v_prev_end)) / 3600)::NUMERIC, 1);
        END IF;

        IF v_new_end <= v_next_start AND
           EXTRACT(EPOCH FROM (v_next_start - v_new_end)) / 3600 < 8 THEN
            RAISE EXCEPTION
                'Παραβίαση 8ω ανάπαυσης: staff_id=% θα έχει μόνο % ώρες μετά τη νέα βάρδια.',
                NEW.staff_id,
                ROUND((EXTRACT(EPOCH FROM (v_next_start - v_new_end)) / 3600)::NUMERIC, 1);
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_shift_rest_8h
BEFORE INSERT ON shift_staff
FOR EACH ROW EXECUTE FUNCTION fn_shift_rest_8h();


-- #38 | trg_shift_max_3_night
CREATE OR REPLACE FUNCTION fn_shift_max_3_night()
RETURNS TRIGGER AS $$
DECLARE
    v_new_date DATE;
    v_new_type VARCHAR(60);
    v_consecutive INT := 1;
    v_check_date DATE;
BEGIN
    SELECT shift_date, shift_type INTO v_new_date, v_new_type
    FROM shifts WHERE shift_id = NEW.shift_id;

    IF v_new_type <> 'Ν' THEN
        RETURN NEW;
    END IF;

    v_check_date := v_new_date - INTERVAL '1 day';

    LOOP
        EXIT WHEN v_consecutive > 3;

        IF EXISTS (
            SELECT 1
            FROM shift_staff ss
            JOIN shifts s ON ss.shift_id = s.shift_id
            WHERE ss.staff_id = NEW.staff_id
            AND s.shift_type = 'Ν'
            AND s.shift_date = v_check_date
        ) THEN
            v_consecutive := v_consecutive + 1;
            v_check_date := v_check_date - INTERVAL '1 day';
        ELSE
            EXIT;
        END IF;
    END LOOP;

    IF v_consecutive > 3 THEN
        RAISE EXCEPTION
            'Παραβίαση ορίου: staff_id=% θα έχει % συνεχόμενες νυχτερινές (μέγιστο 3).',
            NEW.staff_id, v_consecutive;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_shift_max_3_night
BEFORE INSERT ON shift_staff
FOR EACH ROW EXECUTE FUNCTION fn_shift_max_3_night();


-- ΕΝΟΤΗΤΑ 10: REVIEWS

-- #39 | trg_hr_after_discharge
CREATE OR REPLACE FUNCTION fn_hr_after_discharge()
RETURNS TRIGGER AS $$
DECLARE
    v_discharge_date DATE;
BEGIN
    SELECT discharge_date INTO v_discharge_date
    FROM hospitalization WHERE hospitalization_id = NEW.hospitalization_id;

    IF v_discharge_date IS NULL THEN
        RAISE EXCEPTION
            'Δεν επιτρέπεται αξιολόγηση νοσηλείας (hospitalization_id=%): ο ασθενής δεν έχει εξέλθει ακόμα.',
            NEW.hospitalization_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hr_after_discharge
BEFORE INSERT ON patient_hospitalization_review
FOR EACH ROW EXECUTE FUNCTION fn_hr_after_discharge();


-- #40 | trg_dr_after_discharge
CREATE OR REPLACE FUNCTION fn_dr_after_discharge()
RETURNS TRIGGER AS $$
DECLARE
    v_discharge_date DATE;
BEGIN
    SELECT discharge_date INTO v_discharge_date
    FROM hospitalization WHERE hospitalization_id = NEW.hospitalization_id;

    IF v_discharge_date IS NULL THEN
        RAISE EXCEPTION
            'Δεν επιτρέπεται αξιολόγηση ιατρού (hospitalization_id=%): ο ασθενής δεν έχει εξέλθει ακόμα.',
            NEW.hospitalization_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dr_after_discharge
BEFORE INSERT ON patient_doctor_review
FOR EACH ROW EXECUTE FUNCTION fn_dr_after_discharge();


-- #41 | trg_dr_prescribed_doctor
CREATE OR REPLACE FUNCTION fn_dr_prescribed_doctor()
RETURNS TRIGGER AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM prescription
    WHERE hospitalization_id = NEW.hospitalization_id
    AND doctor_id = NEW.doctor_id;

    IF v_count = 0 THEN
        RAISE EXCEPTION
            'Δεν επιτρέπεται αξιολόγηση: ο ιατρός (doctor_id=%) δεν έχει συνταγογραφήσει κατά τη νοσηλεία (hospitalization_id=%).',
            NEW.doctor_id, NEW.hospitalization_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dr_prescribed_doctor
BEFORE INSERT ON patient_doctor_review
FOR EACH ROW EXECUTE FUNCTION fn_dr_prescribed_doctor();


-- ΕΝΟΤΗΤΑ 11: MEDIA

-- #42 | trg_image_entity_check
CREATE OR REPLACE FUNCTION fn_image_entity_check()
RETURNS TRIGGER AS $$
DECLARE
    v_count INT := 0;
BEGIN
    IF NEW.department_name IS NOT NULL THEN v_count := v_count + 1; END IF;
    IF NEW.staff_id IS NOT NULL THEN v_count := v_count + 1; END IF;
    IF NEW.patient_id IS NOT NULL THEN v_count := v_count + 1; END IF;
    IF NEW.room_id IS NOT NULL THEN v_count := v_count + 1; END IF;
    IF NEW.drug_code IS NOT NULL THEN v_count := v_count + 1; END IF;
    IF NEW.active_substance IS NOT NULL THEN v_count := v_count + 1; END IF;
    IF NEW.allergy_id IS NOT NULL THEN v_count := v_count + 1; END IF;
    IF NEW.bed_id IS NOT NULL THEN v_count := v_count + 1; END IF;

    IF v_count = 0 THEN
        RAISE EXCEPTION
            'Η εικόνα (image_id=%) πρέπει να ανήκει σε τουλάχιστον μία οντότητα.',
            NEW.image_id;
    END IF;

    IF v_count > 1 THEN
        RAISE EXCEPTION
            'Η εικόνα (image_id=%) δεν μπορεί να ανήκει σε περισσότερες από μία οντότητες (count=%).',
            NEW.image_id, v_count;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_image_entity_check
BEFORE INSERT OR UPDATE ON image
FOR EACH ROW EXECUTE FUNCTION fn_image_entity_check();


-- ΜΕΡΟΣ ΣΤ: VIEWS

-- ΕΝΟΤΗΤΑ 1: HOSPITAL DEPARTMENTS

-- Πλήρες προφίλ τμήματος με διευθυντή, προσωπικό και διαθέσιμα κρεβάτια
CREATE VIEW v_department_full_profile AS
SELECT
    d.department_name,
    d.director_id,
    s.first_name AS director_first_name,
    s.last_name  AS director_last_name,
    -- Προσωπικό τμήματος
    (SELECT STRING_AGG(first_name || ' ' || last_name || ' (' || staff_type || ')', ', ')
     FROM staff st JOIN doctor_department dd ON st.staff_id = dd.doctor_id
     WHERE dd.department_name = d.department_name) AS doctors,
    (SELECT STRING_AGG(first_name || ' ' || last_name || ' (' || staff_type || ')', ', ')
     FROM staff st JOIN nurse n ON st.staff_id = n.staff_id
     WHERE n.department_name = d.department_name) AS nurses,
    (SELECT STRING_AGG(first_name || ' ' || last_name || ' (' || staff_type || ')', ', ')
     FROM staff st JOIN admin_staff a ON st.staff_id = a.staff_id
     WHERE a.department_name = d.department_name) AS admin_staff
FROM department d
JOIN staff s ON d.director_id = s.staff_id;

-- Διαθέσιμα κρεβάτια ανά τμήμα
CREATE VIEW v_available_beds AS
SELECT
    db.bed_id,
    db.department_name,
    db.type  AS bed_type,
    db.status,
    d.floor_building,
    d.bed_capacity,
    COUNT(*) OVER (PARTITION BY db.department_name) AS available_beds_in_dept
FROM department_beds db
JOIN department d ON db.department_name = d.department_name
WHERE db.status = 'διαθέσιμη' AND db.bed_id NOT IN (SELECT h.bed_id FROM hospitalization h WHERE h.discharge_date IS NULL)
ORDER BY db.department_name, db.type, db.bed_id;

-- ΕΝΟΤΗΤΑ 2: STAFF

-- Πλήρες Προφίλ Προσωπικού
CREATE VIEW v_staff_full_profile AS
SELECT
    s.staff_id,
    s.amka,
    s.first_name,
    s.last_name,
    s.email,
    s.phone,
    s.hire_date,
    s.staff_type,
    DATE_PART('year', AGE(CURRENT_DATE, s.date_of_birth)) AS age,
    -- Ιατρός
    d.license_number AS doctor_license,
    d.specialty AS doctor_specialty,
    d.rank AS doctor_rank,
    sup.staff_id AS supervisor_id,
    sup_s.first_name AS supervisor_first_name,
    sup_s.last_name AS supervisor_last_name,
    -- Νοσηλευτής
    n.nurse_rank,
    n.department_name AS nurse_department,
    -- Διοικητικό
    a.role AS admin_role,
    a.office AS admin_office,
    a.department_name AS admin_department,
    -- Τμήματα ιατρών
    dd.department_name AS doctor_department,
    -- Ενιαίος ρόλος
    CASE
        WHEN d.staff_id IS NOT NULL THEN 'Ιατρός'
        WHEN n.staff_id IS NOT NULL THEN 'Νοσηλευτής'
        WHEN a.staff_id IS NOT NULL THEN 'Διοικητικό'
        ELSE 'Άγνωστο'
    END AS resolved_role
FROM staff s
LEFT JOIN doctor d ON s.staff_id = d.staff_id
LEFT JOIN doctor sup ON d.supervisor_id = sup.staff_id
LEFT JOIN staff sup_s ON sup.staff_id = sup_s.staff_id
LEFT JOIN nurse n ON s.staff_id = n.staff_id
LEFT JOIN admin_staff a ON s.staff_id = a.staff_id
LEFT JOIN doctor_department dd ON d.staff_id = dd.doctor_id;

-- v_department_directors: διευθυντές ανά τμήμα
CREATE VIEW v_department_directors AS
SELECT
    d.department_name,
    doc.staff_id,
    s.first_name,
    s.last_name,
    doc.rank
FROM department d
JOIN doctor doc ON d.director_id = doc.staff_id
JOIN staff s ON s.staff_id = doc.staff_id;

-- ΕΝΟΤΗΤΑ 4: PATIENTS

-- v_patient_full_profile
CREATE VIEW v_patient_full_profile AS
SELECT
    p.patient_id,
    p.amka,
    p.first_name,
    p.last_name,
    p.fathers_name,
    p.gender,
    p.street,
    p.city,
    p.postal_code,
    p.phone,
    p.email,
    p.occupation,
    p.nationality,
    c.name AS nationality_name,
    i.name AS insurer_name,
    i.type AS insurer_type,

    EXTRACT(YEAR FROM AGE(p.dob))::INT AS age,

    (SELECT weight FROM triage WHERE patient_id = p.patient_id ORDER BY arrival_time DESC LIMIT 1)  AS last_weight,
    (SELECT height FROM triage WHERE patient_id = p.patient_id ORDER BY arrival_time DESC LIMIT 1)  AS last_height,

    STRING_AGG(DISTINCT pa.active_substance, ', ')  AS allergies,

    STRING_AGG(DISTINCT ec.first_name || ' ' || ec.last_name || ' (' || COALESCE(pec.relation, '?') || ')',' | '
    ) AS emergency_contacts,

    COUNT(DISTINCT h.hospitalization_id) AS total_hospitalizations,
    MAX(h.admission_date) AS last_admission_date

FROM patient p
LEFT JOIN country c ON p.nationality = c.country_code
LEFT JOIN insurer i ON p.insurer_id = i.insurer_id
LEFT JOIN patient_allergy pa ON p.patient_id = pa.patient_id
LEFT JOIN patient_emergency_contact pec ON p.patient_id = pec.patient_id
LEFT JOIN emergency_contact ec ON pec.contact_id = ec.contact_id
LEFT JOIN hospitalization h ON p.patient_id = h.patient_id
GROUP BY
    p.patient_id, p.amka, p.first_name, p.last_name, p.fathers_name,
    p.dob, p.gender, p.street, p.city, p.postal_code, p.phone, p.email,
    p.occupation, p.nationality, c.name, i.name, i.type;

-- -- v_patient_history: ιστορικό νοσηλειών, συνταγών, εξετάσεων και πράξεων
-- CREATE VIEW v_patient_history AS
--
-- -- Νοσηλείες
-- SELECT
--     p.patient_id,
--     p.first_name,
--     p.last_name,
--     p.amka,
--     h.hospitalization_id,
--     h.department_name,
--     h.admission_date,
--     h.discharge_date,
--     h.admission_diag_icd10,
--     h.discharge_diag_icd10,
--     h.ken_code,
--     h.total_cost,
--     'νοσηλεία' AS record_type,
--     NULL AS detail_code,
--     NULL AS detail_name,
--     h.admission_date AS event_date
-- FROM patient p
-- JOIN hospitalization h ON p.patient_id = h.patient_id
--
-- UNION ALL
--
-- -- Συνταγές
-- SELECT
--     p.patient_id,
--     p.first_name,
--     p.last_name,
--     p.amka,
--     pr.hospitalization_id,
--     h.department_name,
--     h.admission_date,
--     h.discharge_date,
--     NULL AS admission_diag_icd10,
--     NULL AS discharge_diag_icd10,
--     NULL AS ken_code,
--     NULL AS total_cost,
--     'συνταγή' AS record_type,
--     pr.drug_code AS detail_code,
--     d.name AS detail_name,
--     pr.start_date AS event_date
-- FROM patient p
-- JOIN prescription pr ON p.patient_id = pr.patient_id
-- JOIN hospitalization h ON pr.hospitalization_id = h.hospitalization_id
-- JOIN drug d ON pr.drug_code = d.drug_code
--
-- UNION ALL
--
-- -- Εργαστηριακές εξετάσεις
-- SELECT
--     p.patient_id,
--     p.first_name,
--     p.last_name,
--     p.amka,
--     le.hospitalization_id,
--     h.department_name,
--     h.admission_date,
--     h.discharge_date,
--     NULL AS admission_diag_icd10,
--     NULL AS discharge_diag_icd10,
--     NULL AS ken_code,
--     NULL AS total_cost,
--     'εξέταση' AS record_type,
--     le.code AS detail_code,
--     le.type AS detail_name,
--     le.ordered_date::DATE AS event_date
-- FROM patient p
-- JOIN hospitalization h ON p.patient_id = h.patient_id
-- JOIN hospitalization_lab_exam le ON le.hospitalization_id = h.hospitalization_id
--
-- UNION ALL
--
-- -- Ιατρικές πράξεις
-- SELECT
--     p.patient_id,
--     p.first_name,
--     p.last_name,
--     p.amka,
--     hp.hospitalization_id,
--     h.department_name,
--     h.admission_date,
--     h.discharge_date,
--     NULL AS admission_diag_icd10,
--     NULL AS discharge_diag_icd10,
--     NULL AS ken_code,
--     NULL AS total_cost,
--     'πράξη' AS record_type,
--     hp.procedure_code AS detail_code,
--     mp.description AS detail_name,
--     hp.performed_date AS event_date
-- FROM patient p
-- JOIN hospitalization h ON p.patient_id = h.patient_id
-- JOIN hospitalization_procedure hp ON hp.hospitalization_id = h.hospitalization_id
-- JOIN medical_procedure mp ON hp.procedure_code = mp.procedure_code
--
-- ORDER BY patient_id, event_date, record_type;

-- ΕΝΟΤΗΤΑ 5: TRIAGE

-- v_triage_summary: συνοπτική εικόνα τριάς ανά ασθενή
CREATE VIEW v_triage_queue AS
SELECT
    t.triage_id,
    t.patient_id,
    p.first_name,
    p.last_name,
    p.amka,
    t.arrival_time,
    t.urgency_level,
    t.symptoms,
    t.nurse_id,
    s.first_name AS nurse_first_name,
    s.last_name AS nurse_last_name
FROM triage t
JOIN patient p ON t.patient_id = p.patient_id
JOIN staff s ON t.nurse_id = s.staff_id
WHERE t.outcome IS NULL
ORDER BY t.urgency_level, t.arrival_time;

-- ΕΝΟΤΗΤΑ 6: HOSPITALIZATION

-- v_active_hospitalizations: ενεργές νοσηλείες με βασικές πληροφορίες
CREATE VIEW v_active_hospitalizations AS
SELECT
    h.hospitalization_id,
    h.patient_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    p.amka AS patient_amka,
    h.department_name,
    h.bed_id,
    db.type AS bed_type,
    h.admission_date,
    h.admission_diag_icd10,
    h.ken_code,
    hs.staff_id AS attending_doctor_id,
    s.first_name AS doctor_first_name,
    s.last_name AS doctor_last_name
FROM hospitalization h
JOIN patient p ON h.patient_id = p.patient_id
JOIN department_beds db ON h.bed_id = db.bed_id
LEFT JOIN hospitalization_staff hs ON hs.hospitalization_id = h.hospitalization_id AND hs.role = 'attending_doctor'
LEFT JOIN staff s ON hs.staff_id = s.staff_id
WHERE h.discharge_date IS NULL;

CREATE VIEW v_hospitalization_cost_breakdown AS
SELECT
    h.hospitalization_id,
    h.patient_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    h.department_name,
    h.admission_date,
    h.discharge_date,
    h.ken_code,
    k.base_cost AS ken_base_cost,
    k.avg_duration_days AS ken_avg_days,
    k.daily_extra AS ken_daily_extra,
    GREATEST(0, (h.discharge_date - h.admission_date) - k.avg_duration_days) AS extra_days,
    COALESCE(k.base_cost + GREATEST(0, (h.discharge_date - h.admission_date) - k.avg_duration_days) * k.daily_extra, 0) AS ken_total,
    0::NUMERIC AS procedures_cost, -- FIXED: δεν υπάρχει στήλη κόστους στις ιατρικές πράξεις του τρέχοντος schema
    h.total_cost AS stored_total_cost
FROM hospitalization h
JOIN patient p ON h.patient_id = p.patient_id
LEFT JOIN ken_code k ON h.ken_code = k.ken_code
LEFT JOIN hospitalization_lab le ON le.hospitalization_id = h.hospitalization_id -- FIXED
GROUP BY
    h.hospitalization_id, h.patient_id, p.first_name, p.last_name,
    h.department_name, h.admission_date, h.discharge_date, h.ken_code,
    k.base_cost, k.avg_duration_days, k.daily_extra, h.total_cost;


-- ΕΝΟΤΗΤΑ 8: PRESCRIPTIONS
-- v_patient_prescriptions: συνταγές ανά ασθενή/νοσηλεία
CREATE OR REPLACE VIEW v_patient_prescriptions AS
SELECT
    pr.prescription_id,
    p.patient_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    p.amka AS patient_amka,
    pr.hospitalization_id,
    h.department_name AS hospitalization_dept,
    h.admission_date,
    h.discharge_date,
    s.staff_id AS doctor_id,
    s.first_name AS doctor_first_name,
    s.last_name AS doctor_last_name,
    d.specialty AS doctor_specialty,
    d.rank AS doctor_rank,
    dr.drug_code,
    dr.name AS drug_name,
    pr.dosage,
    pr.frequency,
    pr.start_date,
    pr.end_date,
    (pr.end_date - pr.start_date) AS duration_days
FROM prescription pr
JOIN patient p ON pr.patient_id = p.patient_id
JOIN hospitalization h ON pr.hospitalization_id = h.hospitalization_id
JOIN staff s ON pr.doctor_id = s.staff_id
JOIN doctor d ON pr.doctor_id = d.staff_id
JOIN drug dr ON pr.drug_code = dr.drug_code
ORDER BY pr.patient_id, pr.start_date;

-- ΕΝΟΤΗΤΑ 9: SHIFT SCHEDULING
-- v_triage_nurses: νοσηλευτές στη βάρδια τρέχουσας ώρας
CREATE VIEW v_triage_nurses AS
SELECT
    s.staff_id,
    s.first_name,
    s.last_name,
    n.nurse_rank,
    n.department_name,
    sh.shift_type,
    sh.shift_date
FROM staff s
JOIN nurse n ON s.staff_id = n.staff_id
JOIN shift_staff ss ON s.staff_id = ss.staff_id
JOIN shifts sh ON ss.shift_id = sh.shift_id
WHERE sh.shift_date = CURRENT_DATE
  AND (
    (sh.shift_type = 'Π' AND CURRENT_TIME BETWEEN '07:00' AND '15:00')
    OR
    (sh.shift_type = 'Α' AND CURRENT_TIME BETWEEN '15:00' AND '23:00')
    OR
    (sh.shift_type = 'Ν' AND (CURRENT_TIME >= '23:00' OR CURRENT_TIME <= '07:00'))
  )
ORDER BY n.nurse_rank DESC, s.last_name, s.first_name;

-- Συνοπτική αναφορά βαρδιών ανά υπάλληλο ανά μήνα
CREATE VIEW v_monthly_shift_summary AS
SELECT
    ss.staff_id,
    s.first_name,
    s.last_name,
    s.staff_type,
    EXTRACT(YEAR  FROM sh.shift_date)::INT AS year,
    EXTRACT(MONTH FROM sh.shift_date)::INT AS month,
    COUNT(*) AS shift_count,
    COUNT(*) FILTER (WHERE sh.shift_type = 'Π') AS morning_shifts,
    COUNT(*) FILTER (WHERE sh.shift_type = 'Α') AS afternoon_shifts,
    COUNT(*) FILTER (WHERE sh.shift_type = 'Ν') AS night_shifts
FROM shift_staff ss
JOIN staff s ON ss.staff_id = s.staff_id
JOIN shifts sh ON ss.shift_id = sh.shift_id
GROUP BY
    ss.staff_id, s.first_name, s.last_name, s.staff_type,
    EXTRACT(YEAR FROM sh.shift_date),
    EXTRACT(MONTH FROM sh.shift_date);

-- ΕΝΟΤΗΤΑ 10: REVIEWS
-- Μέση βαθμολογία νοσηλείας
CREATE VIEW v_hospitalization_review_avg AS
SELECT
    hospitalization_id,
    ROUND(
        (AVG(nursing_care_score) + AVG(cleanliness_score) + AVG(food_score) + AVG(overall_score)) / 4.0, 2
    ) AS avg_score
FROM patient_hospitalization_review
GROUP BY hospitalization_id;

-- Μέση βαθμολογία ιατρού
CREATE VIEW v_doctor_review_avg AS
SELECT
    doctor_id,
    ROUND(AVG(medical_care_score), 2) AS avg_score
FROM patient_doctor_review
GROUP BY doctor_id;



-- ΜΕΡΟΣ Ζ: PROCEDURES / FUNCTIONS

-- ΕΝΟΤΗΤΑ 2: STAFF

-- Πρόσληψη Προσωπικού
DROP FUNCTION IF EXISTS sp_hire_staff(
    VARCHAR, VARCHAR, VARCHAR, DATE, VARCHAR, VARCHAR, DATE, VARCHAR,
    VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR[],
    VARCHAR, VARCHAR,
    VARCHAR, VARCHAR, VARCHAR
) CASCADE;

CREATE OR REPLACE FUNCTION sp_hire_staff(
    p_amka VARCHAR,
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_dob DATE,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_hire_date DATE,
    p_staff_type VARCHAR,
    p_license_number VARCHAR DEFAULT NULL,
    p_specialty VARCHAR DEFAULT NULL,
    p_rank VARCHAR DEFAULT NULL,
    p_supervisor_id INT DEFAULT NULL,
    p_department_names VARCHAR[] DEFAULT NULL,
    p_nurse_rank VARCHAR DEFAULT NULL,
    p_nurse_department VARCHAR DEFAULT NULL,
    p_admin_role VARCHAR DEFAULT NULL,
    p_admin_office VARCHAR DEFAULT NULL,
    p_admin_department VARCHAR DEFAULT NULL
) RETURNS INT AS $$
DECLARE
    v_staff_id INT;
    v_dept_name VARCHAR(100);
BEGIN
    IF p_staff_type NOT IN ('Ιατρός', 'Νοσηλευτής', 'Διοικητικό Προσωπικό') THEN
        RAISE EXCEPTION 'Μη έγκυρος staff_type: "%".', p_staff_type;
    END IF;

    IF p_staff_type = 'Ιατρός' THEN
        IF p_license_number IS NULL THEN
            RAISE EXCEPTION 'Απαιτείται license_number για ιατρό.';
        END IF;
        IF p_specialty IS NULL THEN
            RAISE EXCEPTION 'Απαιτείται specialty για ιατρό.';
        END IF;
        IF p_rank IS NULL THEN
            RAISE EXCEPTION 'Απαιτείται rank για ιατρό.';
        END IF;
        IF p_department_names IS NULL OR array_length(p_department_names, 1) = 0 THEN
            RAISE EXCEPTION 'Απαιτείται τουλάχιστον ένα τμήμα για ιατρό.';
        END IF;
        IF p_rank = 'Ειδικευόμενος' AND p_supervisor_id IS NULL THEN
            RAISE EXCEPTION 'Ο Ειδικευόμενος πρέπει να έχει supervisor.';
        END IF;
        IF p_rank = 'Διευθυντής' AND p_supervisor_id IS NOT NULL THEN
            RAISE EXCEPTION 'Ο Διευθυντής δεν μπορεί να έχει supervisor.';
        END IF;

    ELSIF p_staff_type = 'Νοσηλευτής' THEN
        IF p_nurse_rank IS NULL THEN
            RAISE EXCEPTION 'Απαιτείται nurse_rank για νοσηλευτή.';
        END IF;
        IF p_nurse_department IS NULL THEN
            RAISE EXCEPTION 'Απαιτείται τμήμα για νοσηλευτή.';
        END IF;

    ELSIF p_staff_type = 'Διοικητικό Προσωπικό' THEN
        IF p_admin_role IS NULL THEN
            RAISE EXCEPTION 'Απαιτείται ρόλος για διοικητικό προσωπικό.';
        END IF;
        IF p_admin_department IS NULL THEN
            RAISE EXCEPTION 'Απαιτείται τμήμα για διοικητικό προσωπικό.';
        END IF;
    END IF;

    INSERT INTO staff (
        amka, first_name, last_name, date_of_birth,
        email, phone, hire_date, staff_type
    ) VALUES (
        p_amka, p_first_name, p_last_name, p_dob,
        p_email, p_phone, p_hire_date, p_staff_type
    )
    RETURNING staff_id INTO v_staff_id;

    IF p_staff_type = 'Ιατρός' THEN

        INSERT INTO doctor (
            staff_id, license_number, specialty, rank, supervisor_id
        ) VALUES (
            v_staff_id, p_license_number, p_specialty, p_rank, p_supervisor_id
        );

        FOREACH v_dept_name IN ARRAY p_department_names LOOP
            INSERT INTO doctor_department (doctor_id, department_name)
            VALUES (v_staff_id, v_dept_name);
        END LOOP;

    ELSIF p_staff_type = 'Νοσηλευτής' THEN

        INSERT INTO nurse (staff_id, nurse_rank, department_name)
        VALUES (v_staff_id, p_nurse_rank, p_nurse_department);

    ELSIF p_staff_type = 'Διοικητικό Προσωπικό' THEN

        INSERT INTO admin_staff (staff_id, role, office, department_name)
        VALUES (v_staff_id, p_admin_role, p_admin_office, p_admin_department);

    END IF;

    RAISE NOTICE 'Πρόσληψη επιτυχής: % % (staff_id=%, τύπος=%).',
        p_first_name, p_last_name, v_staff_id, p_staff_type;

    RETURN v_staff_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Αποτυχία πρόσληψης για % %: %',
            p_first_name, p_last_name, SQLERRM;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sp_hire_staff IS
    'Atomic πρόσληψη προσωπικού. Δημιουργεί εγγραφή στο staff και στο αντίστοιχο subtype '
    '(doctor/nurse/admin_staff) σε ένα transaction. '
    'Για ιατρούς: δέχεται array τμημάτων και ελέγχει supervisor κανόνες. '
    'Επιστρέφει το staff_id του νέου μέλους.';


-- ΕΝΟΤΗΤΑ 5: TRIAGE

-- Διαλογή Ασθενή
DROP FUNCTION IF EXISTS sp_triage_admission(
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE, VARCHAR, VARCHAR,
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT,
    INT, DECIMAL, DECIMAL, TEXT, INT, VARCHAR, VARCHAR
) CASCADE;

CREATE OR REPLACE FUNCTION sp_triage_admission(
    p_amka VARCHAR DEFAULT NULL,
    p_first_name VARCHAR DEFAULT NULL,
    p_last_name VARCHAR DEFAULT NULL,
    p_fathers_name VARCHAR DEFAULT NULL,
    p_dob DATE DEFAULT NULL,
    p_gender VARCHAR DEFAULT NULL,
    p_phone VARCHAR DEFAULT NULL,
    p_email VARCHAR DEFAULT NULL,
    p_street VARCHAR DEFAULT NULL,
    p_city VARCHAR DEFAULT NULL,
    p_postal_code VARCHAR DEFAULT NULL,
    p_insurer_id INT DEFAULT NULL,
    p_nurse_id INT DEFAULT NULL,
    p_weight DECIMAL DEFAULT NULL,
    p_height DECIMAL DEFAULT NULL,
    p_symptoms TEXT DEFAULT NULL,
    p_urgency_level INT DEFAULT NULL,
    p_outcome VARCHAR DEFAULT NULL,
    p_referred_dept VARCHAR DEFAULT NULL
) RETURNS TABLE (
    out_patient_id INT,
    out_triage_id INT,
    out_hospitalization_id  INT,
    out_is_new_patient BOOLEAN
) AS $$
DECLARE
    v_patient_id INT;
    v_triage_id INT;
    v_hospitalization_id INT;
    v_is_new_patient BOOLEAN := FALSE;
BEGIN
    IF p_amka IS NOT NULL THEN
        SELECT patient_id INTO v_patient_id
        FROM patient WHERE amka = p_amka;
    END IF;

    IF v_patient_id IS NULL THEN
        INSERT INTO patient (
            amka, first_name, last_name, fathers_name, dob, gender,
            phone, email, street, city, postal_code, insurer_id
        ) VALUES (
            p_amka, p_first_name, p_last_name, p_fathers_name, p_dob, p_gender,
            p_phone, p_email, p_street, p_city, p_postal_code, p_insurer_id
        )
        RETURNING patient_id INTO v_patient_id;

        v_is_new_patient := TRUE;
        RAISE NOTICE 'Νέος ασθενής δημιουργήθηκε (patient_id=%).', v_patient_id;
    ELSE
        RAISE NOTICE 'Υπάρχων ασθενής εντοπίστηκε (patient_id=%).', v_patient_id;
    END IF;

    INSERT INTO triage (
        patient_id, nurse_id, arrival_time,
        weight, height, symptoms, urgency_level,
        outcome, referred_dept_name
    ) VALUES (
        v_patient_id, p_nurse_id, CURRENT_TIMESTAMP,
        p_weight, p_height, p_symptoms, p_urgency_level,
        p_outcome, p_referred_dept
    )
    RETURNING triage_id INTO v_triage_id;

    RAISE NOTICE 'Triage καταχωρήθηκε (triage_id=%, urgency=%).',
        v_triage_id, p_urgency_level;

    IF p_outcome = 'παραπομπή για νοσηλεία' THEN
        SELECT hospitalization_id INTO v_hospitalization_id
        FROM hospitalization
        WHERE triage_id = v_triage_id;

        RAISE NOTICE 'Νοσηλεία δημιουργήθηκε αυτόματα (hospitalization_id=%).',
            v_hospitalization_id;
    END IF;

    RETURN QUERY SELECT
        v_patient_id,
        v_triage_id,
        v_hospitalization_id,
        v_is_new_patient;

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sp_triage_admission IS
    'Atomic workflow διαλογής. '
    'Βήμα 1: Εντοπίζει υπάρχοντα ασθενή βάσει AMKA ή δημιουργεί νέο. '
    'Βήμα 2: Καταχωρεί triage — constraints και triggers αναλαμβάνουν την επικύρωση. '
    'Βήμα 3: Αν outcome = παραπομπή, ανακτά το hospitalization_id που δημιούργησε ο trigger. '
    'Επιστρέφει patient_id, triage_id, hospitalization_id, is_new_patient.';


-- ΕΝΟΤΗΤΑ 6: HOSPITALIZATION

-- Εξόδος Ασθενή
DROP FUNCTION IF EXISTS sp_discharge_patient(INT, DATE, VARCHAR, VARCHAR, VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION sp_discharge_patient(
    p_hospitalization_id INT,
    p_discharge_date DATE,
    p_discharge_icd10 VARCHAR,
    p_ken_code VARCHAR DEFAULT NULL
) RETURNS TABLE (
    out_hospitalization_id  INT,
    out_total_cost DECIMAL,
    out_days_stayed INT
) AS $$
DECLARE
    v_admission_date DATE;
    v_discharge_date DATE;
    v_total_cost DECIMAL;
BEGIN
    SELECT admission_date, discharge_date
    INTO v_admission_date, v_discharge_date
    FROM hospitalization
    WHERE hospitalization_id = p_hospitalization_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Δεν βρέθηκε νοσηλεία με id=%.', p_hospitalization_id;
    END IF;

    IF v_discharge_date IS NOT NULL THEN
        RAISE EXCEPTION 'Η νοσηλεία % έχει ήδη ολοκληρωθεί (discharge_date=%).',
            p_hospitalization_id, v_discharge_date;
    END IF;

    IF p_discharge_date < v_admission_date THEN
        RAISE EXCEPTION 'Η ημερομηνία εξόδου (%) είναι πριν την εισαγωγή (%).',
            p_discharge_date, v_admission_date;
    END IF;

    UPDATE hospitalization SET
        discharge_date       = p_discharge_date,
        discharge_diag_icd10 = p_discharge_icd10,
        ken_code             = COALESCE(p_ken_code, ken_code)
    WHERE hospitalization_id = p_hospitalization_id;

    SELECT total_cost INTO v_total_cost
    FROM hospitalization
    WHERE hospitalization_id = p_hospitalization_id;

    RAISE NOTICE 'Έξοδος ασθενή επιτυχής (hospitalization_id=%, ημέρες=%, κόστος=%).',
        p_hospitalization_id,
        (p_discharge_date - v_admission_date),
        v_total_cost;

    RETURN QUERY SELECT
        p_hospitalization_id,
        v_total_cost,
        (p_discharge_date - v_admission_date)::INT;

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sp_discharge_patient IS
    'Atomic workflow εξόδου ασθενή. '
    'Ενημερώνει discharge_date, ICD-10 εξόδου και ΚΕΝ. '
    'Οι triggers trg_hosp_total_cost, trg_hosp_bed_status, trg_hosp_discharge_diagnosis '
    'εκτελούνται αυτόματα. '
    'Επιστρέφει hospitalization_id, συνολικό κόστος και ημέρες νοσηλείας.';



-- ΜΕΡΟΣ Η: INDEXES

-- ΕΝΟΤΗΤΑ 0: REFERENCE DATA
CREATE INDEX idx_country_name ON country(name);
CREATE INDEX idx_insurer_type ON insurer(type);

-- ΕΝΟΤΗΤΑ 1: HOSPITAL DEPARTMENTS
CREATE INDEX idx_department_floor ON department(floor_building);
CREATE INDEX idx_department_director ON department(director_id);
CREATE INDEX idx_department_specialty_specialty ON department_specialty(specialty);
CREATE INDEX idx_department_beds_department ON department_beds(department_name);
CREATE INDEX idx_department_beds_status ON department_beds(status);
CREATE INDEX idx_department_beds_type ON department_beds(type);

-- ΕΝΟΤΗΤΑ 2: STAFF
CREATE INDEX idx_staff_last_name ON staff(last_name);
CREATE INDEX idx_staff_staff_type ON staff(staff_type);
CREATE INDEX idx_staff_hire_date ON staff(hire_date);
CREATE INDEX idx_doctor_specialty ON doctor(specialty);
CREATE INDEX idx_doctor_rank ON doctor(rank);
CREATE INDEX idx_doctor_supervisor ON doctor(supervisor_id);
CREATE INDEX idx_doctor_department_department ON doctor_department(department_name);
CREATE INDEX idx_nurse_department ON nurse(department_name);
CREATE INDEX idx_nurse_rank ON nurse(nurse_rank);
CREATE INDEX idx_admin_staff_department ON admin_staff(department_name);
CREATE INDEX idx_admin_staff_role ON admin_staff(role);

-- ΕΝΟΤΗΤΑ 3: PHARMACY
CREATE INDEX idx_drug_name ON drug(name);
CREATE INDEX idx_drug_substance_substance ON drug_substance(active_substance_name);

-- ΕΝΟΤΗΤΑ 4: PATIENTS
CREATE INDEX idx_patient_last_name ON patient(last_name);
CREATE INDEX idx_patient_city ON patient(city);
CREATE INDEX idx_patient_nationality ON patient(nationality);
CREATE INDEX idx_patient_insurer ON patient(insurer_id);
CREATE INDEX idx_patient_created_at ON patient(created_at);
CREATE INDEX idx_emergency_contact_last_name ON emergency_contact(last_name);
CREATE INDEX idx_patient_emergency_contact_contact ON patient_emergency_contact(contact_id);
CREATE INDEX idx_patient_allergy_patient ON patient_allergy(patient_id);
CREATE INDEX idx_patient_allergy_substance ON patient_allergy(active_substance);

-- ΕΝΟΤΗΤΑ 5: TRIAGE
CREATE INDEX idx_triage_patient ON triage(patient_id);
CREATE INDEX idx_triage_nurse ON triage(nurse_id);
CREATE INDEX idx_triage_arrival_time ON triage(arrival_time);
CREATE INDEX idx_triage_urgency ON triage(urgency_level);
CREATE INDEX idx_triage_referred_department ON triage(referred_dept_name);

-- ΕΝΟΤΗΤΑ 6: HOSPITALIZATION
CREATE INDEX idx_ken_description ON ken_code (description);
CREATE INDEX idx_icd10_category ON icd10_code(category);
CREATE INDEX idx_hospitalization_patient ON hospitalization(patient_id);
CREATE INDEX idx_hospitalization_bed ON hospitalization(bed_id);
CREATE INDEX idx_hospitalization_department ON hospitalization(department_name);
CREATE INDEX idx_hospitalization_admission_date ON hospitalization(admission_date);
CREATE INDEX idx_hospitalization_discharge_date ON hospitalization(discharge_date);
CREATE INDEX idx_hospitalization_ken_code ON hospitalization(ken_code);
CREATE INDEX idx_hospitalization_admission_icd10 ON hospitalization(admission_diag_icd10);
CREATE INDEX idx_hospitalization_discharge_icd10 ON hospitalization(discharge_diag_icd10);
CREATE INDEX idx_hosp_staff_hospitalization ON hospitalization_staff(hospitalization_id);
CREATE INDEX idx_hosp_staff_staff ON hospitalization_staff(staff_id);
CREATE INDEX idx_hosp_staff_role ON hospitalization_staff(role);

-- ΕΝΟΤΗΤΑ 7: LAB & OPERATIONS
CREATE INDEX idx_operating_room_type ON operating_room(type);
CREATE INDEX idx_medical_procedure_category ON medical_procedure(category);
CREATE INDEX idx_hosp_procedure_hospitalization ON hospitalization_procedure(hospitalization_id); -- FIXED
CREATE INDEX idx_hosp_procedure_code ON hospitalization_procedure(procedure_code); -- FIXED
CREATE INDEX idx_hosp_procedure_doctor ON hospitalization_procedure(performed_by); -- FIXED
CREATE INDEX idx_hosp_procedure_date ON hospitalization_procedure(performed_date); -- ADDED BASED ON ANALYSIS
CREATE INDEX idx_procedure_participant_staff ON procedure_participant(staff_id);
CREATE INDEX idx_lab_exam_hospitalization ON hospitalization_lab(hospitalization_id); -- FIXED
CREATE INDEX idx_lab_exam_doctor ON hospitalization_lab(ordered_by); -- FIXED
CREATE INDEX idx_lab_exam_exam_date ON hospitalization_lab(ordered_by); -- FIXED

-- ΕΝΟΤΗΤΑ 8: PRESCRIPTIONS
CREATE INDEX idx_prescription_doctor ON prescription(doctor_id);
CREATE INDEX idx_prescription_patient ON prescription(patient_id);
CREATE INDEX idx_prescription_drug ON prescription(drug_code);
CREATE INDEX idx_prescription_hospitalization ON prescription(hospitalization_id);
CREATE INDEX idx_prescription_start_date ON prescription(start_date);
CREATE INDEX idx_prescription_end_date ON prescription(end_date);

-- ΕΝΟΤΗΤΑ 9: SHIFT SCHEDULING
CREATE INDEX idx_shifts_department ON shifts(department_name);
CREATE INDEX idx_shifts_date ON shifts(shift_date);
CREATE INDEX idx_shifts_type ON shifts(shift_type);
CREATE INDEX idx_shift_staff_staff ON shift_staff(staff_id);

-- ΕΝΟΤΗΤΑ 10: REVIEWS
CREATE INDEX idx_patient_doctor_review_doctor ON patient_doctor_review(doctor_id);

-- ΕΝΟΤΗΤΑ 11: MEDIA
CREATE INDEX idx_image_department ON image(department_name);
CREATE INDEX idx_image_staff ON image(staff_id);
CREATE INDEX idx_image_patient ON image(patient_id);
CREATE INDEX idx_image_room ON image(room_id);
CREATE INDEX idx_image_drug ON image(drug_code);
CREATE INDEX idx_image_substance ON image(active_substance);
CREATE INDEX idx_image_allergy ON image(allergy_id);
CREATE INDEX idx_image_bed ON image(bed_id);
CREATE INDEX idx_image_public ON image(is_public);


-- END OF install.sql
COMMIT;
