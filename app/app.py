"""
Υγειούπολις HMS — Flask Backend
Συνδέεται στη PostgreSQL βάση δεδομένων σου.
"""

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import psycopg2
import psycopg2.extras
import os

app = Flask(__name__)

from flask_cors import CORS
CORS(app)

@app.after_request
def cors_headers(response):
    response.headers["Access-Control-Allow-Origin"]  = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    return response

@app.route("/api/<path:p>", methods=["OPTIONS", "GET", "POST", "DELETE"])
def preflight(p):
    """Χειρίζεται OPTIONS preflight για όλα τα API endpoints."""
    return "", 200


# ─── ΡΥΘΜΙΣΕΙΣ ΒΑΣΗΣ ΔΕΔΟΜΕΝΩΝ ────────────────────────────────────────────
# Άλλαξε αυτά με τα δικά σου στοιχεία σύνδεσης
DB_CONFIG = {
    "host":     "localhost",
    "port":     5432,
    "database": "hospital",
    "user":     "postgres",
    "password": "2005"
}

def get_db():
    """Επιστρέφει σύνδεση στη βάση δεδομένων."""
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False
    return conn

def query(sql, params=None, fetch="all"):
    """Εκτελεί query και επιστρέφει αποτέλεσμα."""
    import datetime, decimal
    conn = get_db()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(sql, params)
        if fetch == "all":
            result = cur.fetchall()
        elif fetch == "one":
            result = cur.fetchone()
        else:
            result = None
        conn.commit()
        cur.close()
        conn.close()

        def convert(val):
            if isinstance(val, (datetime.date, datetime.datetime)):
                return val.isoformat()
            if isinstance(val, decimal.Decimal):
                return float(val)
            return val

        if fetch == "all" and result:
            return [{k: convert(v) for k, v in dict(row).items()} for row in result]
        elif fetch == "one" and result:
            return {k: convert(v) for k, v in dict(result).items()}
        return result
    except Exception as e:
        conn.rollback()
        conn.close()
        raise e

def ok(data=None, msg="OK"):
    return jsonify({"status": "ok", "message": msg, "data": data})

def err(msg, code=400):
    return jsonify({"status": "error", "message": msg}), code



# ══════════════════════════════════════════════════════════════════════════════
# PATIENTS
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/api/patients", methods=["GET", "OPTIONS"])
def get_patients():
    search = request.args.get("search", "").strip()
    gender = request.args.get("gender", "").strip()

    sql = """
        SELECT p.*,
               i.name AS insurer_name
        FROM patient p
        LEFT JOIN insurer i ON p.insurer_id = i.insurer_id
        WHERE 1=1
    """
    params = []

    if search:
        sql += " AND (p.first_name ILIKE %s OR p.last_name ILIKE %s OR p.amka ILIKE %s)"
        params += [f"%{search}%", f"%{search}%", f"%{search}%"]

    if gender:
        sql += " AND p.gender = %s"
        params.append(gender)

    sql += " ORDER BY p.patient_id DESC"

    rows = query(sql, params)
    return ok([dict(r) for r in rows])


@app.route("/api/patients/<int:pid>", methods=["GET", "OPTIONS"])
def get_patient(pid):
    p = query("SELECT * FROM patient WHERE patient_id = %s", [pid], fetch="one")
    if not p:
        return err("Ο ασθενής δεν βρέθηκε.", 404)

    allergies = query("SELECT active_substance FROM patient_allergy WHERE patient_id = %s", [pid])

    hosps = query("""
        SELECT h.hospitalization_id, h.patient_id, h.department_name,
               h.bed_id,
               h.admission_date, h.discharge_date,
               h.admission_diag_icd10, h.ken_code,
               s.first_name  AS doc_fn,
               s.last_name   AS doc_ln
        FROM hospitalization h
        LEFT JOIN (
            SELECT DISTINCT ON (hospitalization_id) hospitalization_id, doctor_id
            FROM prescription
            ORDER BY hospitalization_id, prescription_id ASC
        ) pr_doc ON pr_doc.hospitalization_id = h.hospitalization_id
        LEFT JOIN staff s ON s.staff_id = pr_doc.doctor_id
        WHERE h.patient_id = %s
        ORDER BY h.admission_date DESC
    """, [pid])

    ec = query("""
        SELECT ec.*, pec.relation FROM emergency_contact ec
        JOIN patient_emergency_contact pec ON ec.contact_id = pec.contact_id
        WHERE pec.patient_id = %s
    """, [pid])

    prescs = query("""
        SELECT pr.prescription_id, pr.doctor_id, pr.patient_id,
               pr.drug_code, pr.hospitalization_id,
               pr.dosage, pr.frequency,
               pr.start_date, pr.end_date,
               s.first_name  AS doc_fn,
               s.last_name   AS doc_ln
        FROM prescription pr
        LEFT JOIN staff s ON s.staff_id = pr.doctor_id
        WHERE pr.patient_id = %s
        ORDER BY pr.start_date DESC
    """, [pid])

    img = query("SELECT url FROM image WHERE patient_id = %s AND is_public = TRUE ORDER BY image_id DESC LIMIT 1", [pid], fetch="one")

    return ok({
        "patient":            dict(p),
        "image_url":          img["url"] if img else None,
        "allergies":          [r["active_substance"] for r in allergies],
        "hosps":              [dict(r)               for r in hosps],
        "emergency_contacts": [dict(r)               for r in ec],
        "prescriptions":      [dict(r)               for r in prescs],
    })


@app.route("/api/patients", methods=["POST", "OPTIONS"])
def create_patient():
    d = request.get_json(force=True, silent=True) or {}

    if not d.get("first_name") or not d.get("last_name"):
        return err("Απαιτούνται first_name και last_name.")

    # Καθαρισμός ΑΜΚΑ — αν είναι κενό string το κάνουμε None
    amka = d.get("amka", "").strip() or None

    # Αν δόθηκε ΑΜΚΑ, έλεγξε αν υπάρχει ήδη ΠΡΙΝ την εισαγωγή
    if amka:
        existing = query(
            "SELECT patient_id FROM patient WHERE amka = %s",
            [amka], fetch="one"
        )
        if existing:
            return err(f"Υπάρχει ήδη ασθενής με ΑΜΚΑ {amka} (ID: {existing['patient_id']}).")

    conn = None
    try:
        conn = get_db()
        cur  = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # 1. Εισαγωγή ασθενή
        cur.execute("""
            INSERT INTO patient
                (first_name, last_name, fathers_name, amka, dob, gender,
                 occupation, street, city, postal_code, nationality, insurer_id,
                 phone, email)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            RETURNING patient_id
        """, [
            d.get("first_name"),
            d.get("last_name"),
            d.get("fathers_name") or None,
            amka,
            d.get("dob") or None,
            d.get("gender") or None,
            d.get("occupation") or None,
            d.get("street") or None,
            d.get("city") or None,
            d.get("postal_code") or None,
            d.get("nationality") or None,
            int(d["insurer_id"]) if d.get("insurer_id") else None,
            (d.get("phones") or [None])[0] if d.get("phones") else d.get("phone") or None,
            (d.get("emails") or [None])[0] if d.get("emails") else d.get("email") or None,
        ])
        pid = cur.fetchone()["patient_id"]

        # 2. Αλλεργίες
        for substance in d.get("allergies", []):
            substance = str(substance).strip()
            if substance:
                cur.execute(
                    "INSERT INTO active_substance (name) VALUES (%s) ON CONFLICT DO NOTHING",
                    [substance]
                )
                cur.execute(
                    "INSERT INTO patient_allergy (patient_id, active_substance) VALUES (%s,%s) ON CONFLICT DO NOTHING",
                    [pid, substance]
                )

        # 5. Επαφή έκτακτης ανάγκης
        ec = d.get("emergency_contact") or {}
        if ec.get("first_name"):
            cur.execute("""
                INSERT INTO emergency_contact (first_name, last_name, fathers_name, phone)
                VALUES (%s,%s,%s,%s) RETURNING contact_id
            """, [
                ec.get("first_name"),
                ec.get("last_name") or None,
                ec.get("fathers_name") or None,
                ec.get("phone") or None,
            ])
            cid = cur.fetchone()["contact_id"]
            cur.execute("""
                INSERT INTO patient_emergency_contact (patient_id, contact_id, relation)
                VALUES (%s,%s,%s)
            """, [pid, cid, ec.get("relation") or None])

        conn.commit()
        cur.close()
        conn.close()
        return ok({"patient_id": pid}, "Ο ασθενής καταχωρήθηκε επιτυχώς.")

    except psycopg2.errors.UniqueViolation as e:
        if conn:
            conn.rollback()
            conn.close()
        # Εντοπισμός ποιο constraint έσπασε
        detail = str(e)
        if "amka" in detail.lower():
            return err("Υπάρχει ήδη ασθενής με αυτό το ΑΜΚΑ.")
        elif "email" in detail.lower():
            return err("Ένα από τα email υπάρχει ήδη στο σύστημα.")
        else:
            return err(f"Διπλότυπη εγγραφή: {detail}")
    except Exception as e:
        if conn:
            conn.rollback()
            conn.close()
        return err(f"Σφάλμα βάσης: {str(e)}")


@app.route("/api/patients/<int:pid>/update", methods=["GET", "POST", "OPTIONS"])
def update_patient(pid):
    if request.method == "OPTIONS":
        return "", 200
    if request.method == "GET":
        d = request.args.to_dict()
    else:
        d = request.get_json(force=True, silent=True) or {}
    if not d.get("first_name") or not d.get("last_name"):
        return err("Απαιτούνται first_name και last_name.")
    amka = d.get("amka","").strip() or None
    if amka:
        existing = query("SELECT patient_id FROM patient WHERE amka=%s AND patient_id!=%s",[amka,pid],fetch="one")
        if existing:
            return err(f"Υπάρχει ήδη ασθενής με ΑΜΚΑ {amka}.")
    try:
        query("""
            UPDATE patient SET
              first_name=%s, last_name=%s, fathers_name=%s, amka=%s, dob=%s,
              gender=%s, occupation=%s, street=%s, city=%s, postal_code=%s,
              nationality=%s, insurer_id=%s, updated_at=NOW()
            WHERE patient_id=%s
        """,[d.get("first_name"),d.get("last_name"),d.get("fathers_name") or None,
             amka, d.get("dob") or None, d.get("gender") or None,
             d.get("occupation") or None, d.get("street") or None,
             d.get("city") or None, d.get("postal_code") or None,
             d.get("nationality") or None,
             int(d["insurer_id"]) if d.get("insurer_id") else None,
             pid
        ], fetch="none")
        return ok(msg="Ο ασθενής ενημερώθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/hospitalizations/<int:hid>/update", methods=["GET", "POST", "OPTIONS"])
def update_hosp(hid):
    if request.method == "OPTIONS":
        return "", 200
    if request.method == "GET":
        d = request.args.to_dict()
    else:
        d = request.get_json(force=True, silent=True) or {}

    discharge_date = d.get("discharge_date") or None

    # Αν δίνεται ημ. εξόδου, απαιτούνται και η διάγνωση εξόδου
    if discharge_date:
        if not d.get("discharge_diag_icd10"):
            return err("Για έξοδο ασθενή απαιτείται κωδικός ICD-10 διάγνωσης εξόδου (discharge_diag_icd10).")
    try:
        query("""
            UPDATE hospitalization SET
              admission_date=%s, discharge_date=%s,
              admission_diag_icd10=%s,
              discharge_diag_icd10=%s,
              ken_code=%s
            WHERE hospitalization_id=%s
        """, [
            d.get("admission_date"),
            discharge_date,
            d.get("admission_diag_icd10") or None,
            d.get("discharge_diag_icd10") or None,
            d.get("ken_code") or None,
            hid
        ], fetch="none")
        return ok(msg="Η νοσηλεία ενημερώθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/surgery", methods=["GET", "OPTIONS"])
def get_surgery():
    """Legacy alias — ανακατευθύνει στο /api/procedures για συμβατότητα UI."""
    return get_procedures()


@app.route("/api/patients/<int:pid>", methods=["DELETE", "OPTIONS"])
def delete_patient(pid):
    try:
        query("DELETE FROM patient WHERE patient_id = %s", [pid], fetch="none")
        return ok(msg="Ο ασθενής διαγράφηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


# ══════════════════════════════════════════════════════════════════════════════
# HOSPITALIZATIONS
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/api/hospitalizations", methods=["GET", "OPTIONS"])
def get_hosps():
    rows = query("""
        SELECT h.hospitalization_id, h.patient_id, h.department_name, h.bed_id,
               h.admission_date, h.discharge_date,
               h.admission_diag_icd10, h.ken_code, h.total_cost,
               p.first_name, p.last_name
        FROM hospitalization h
        JOIN patient p ON h.patient_id = p.patient_id
        ORDER BY h.hospitalization_id DESC
    """)
    return ok([dict(r) for r in rows])


@app.route("/api/hospitalizations", methods=["POST", "OPTIONS"])
def create_hosp():
    d = request.get_json(force=True, silent=True) or {}
    required = ["patient_id", "department_name", "bed_id", "triage_id", "admission_date"]
    missing  = [f for f in required if not d.get(f)]
    if missing:
        return err(f"Απαιτούνται: {', '.join(missing)}")
    try:
        row = query("""
            INSERT INTO hospitalization
                (patient_id, department_name, bed_id, triage_id,
                 admission_date,
                 admission_diag_icd10, ken_code)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            RETURNING hospitalization_id
        """, [
            d["patient_id"], d["department_name"], d["bed_id"], d["triage_id"],
            d["admission_date"],
            d.get("admission_diag_icd10") or None,
            d.get("ken_code") or None
        ], fetch="one")
        return ok({"hospitalization_id": row["hospitalization_id"]}, "Η νοσηλεία καταχωρήθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/hospitalizations/<int:hid>", methods=["DELETE", "OPTIONS"])
def delete_hosp(hid):
    try:
        query("DELETE FROM hospitalization WHERE hospitalization_id = %s", [hid], fetch="none")
        return ok(msg="Η νοσηλεία διαγράφηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


# ══════════════════════════════════════════════════════════════════════════════
# TRIAGE
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/api/triage", methods=["GET", "OPTIONS"])
def get_triage():
    rows = query("""
        SELECT t.*, p.first_name, p.last_name
        FROM triage t
        JOIN patient p ON t.patient_id = p.patient_id
        ORDER BY t.urgency_level ASC, t.arrival_time ASC
    """)
    return ok([dict(r) for r in rows])


@app.route("/api/triage", methods=["POST", "OPTIONS"])
def create_triage():
    d = request.get_json(force=True, silent=True) or {}
    if not d.get("patient_id") or not d.get("nurse_id") or not d.get("arrival_time") or not d.get("urgency_level"):
        return err("Απαιτούνται: patient_id, nurse_id, arrival_time, urgency_level.")
    try:
        row = query("""
            INSERT INTO triage
                (patient_id, nurse_id, arrival_time, urgency_level,
                 weight, height, symptoms, outcome, referred_dept_name)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            RETURNING triage_id
        """, [
            d["patient_id"], d["nurse_id"], d["arrival_time"], d["urgency_level"],
            d.get("weight") or None, d.get("height") or None,
            d.get("symptoms"), d.get("outcome") or None,
            d.get("referred_dept_name") or None
        ], fetch="one")
        return ok({"triage_id": row["triage_id"]}, "Το τριάζ καταχωρήθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


# ══════════════════════════════════════════════════════════════════════════════
# STAFF / DOCTORS
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/api/staff", methods=["GET", "OPTIONS"])
def get_staff():
    rows = query("""
        SELECT s.*, d.specialty, d.rank, d.license_number, d.supervisor_id,
               img.url AS image_url
        FROM staff s
        JOIN doctor d ON s.staff_id = d.staff_id
        LEFT JOIN LATERAL (
            SELECT url FROM image WHERE staff_id = s.staff_id AND is_public = TRUE
            ORDER BY image_id DESC LIMIT 1
        ) img ON TRUE
        ORDER BY s.staff_id DESC
    """)
    return ok([dict(r) for r in rows])


@app.route("/api/staff", methods=["POST", "OPTIONS"])
def create_staff():
    d = request.get_json(force=True, silent=True) or {}
    required = ["first_name", "last_name", "date_of_birth", "hire_date", "license_number", "specialty", "rank"]
    missing  = [f for f in required if not d.get(f)]
    if missing:
        return err(f"Απαιτούνται: {', '.join(missing)}")
    try:
        conn = get_db()
        cur  = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cur.execute("""
            INSERT INTO staff (amka, first_name, last_name, date_of_birth, email, phone, hire_date, staff_type)
            VALUES (%s,%s,%s,%s,%s,%s,%s,'Ιατρός') RETURNING staff_id
        """, [
            d.get("amka") or None,
            d["first_name"], d["last_name"],
            d.get("date_of_birth"),
            d.get("email") or None,
            d.get("phone") or None,
            d["hire_date"]
        ])
        sid = cur.fetchone()["staff_id"]

        cur.execute("""
            INSERT INTO doctor (staff_id, license_number, specialty, rank)
            VALUES (%s,%s,%s,%s)
        """, [sid, d["license_number"], d["specialty"], d["rank"]])

        conn.commit(); cur.close(); conn.close()
        return ok({"staff_id": sid}, "Ο γιατρός καταχωρήθηκε.")
    except psycopg2.errors.UniqueViolation:
        return err("Υπάρχει ήδη γιατρός με αυτόν τον αριθμό άδειας.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/staff/<int:sid>/update", methods=["GET", "POST", "OPTIONS"])
def update_staff(sid):
    if request.method == "OPTIONS": return "", 200
    d = request.args.to_dict() if request.method=="GET" else (request.get_json(force=True,silent=True) or {})
    try:
        query("""
            UPDATE staff SET first_name=%s, last_name=%s, date_of_birth=%s, hire_date=%s
            WHERE staff_id=%s
        """, [d.get("first_name"), d.get("last_name"),
              d.get("date_of_birth") or None,
              d.get("hire_date") or None, sid], fetch="none")
        if d.get("specialty") or d.get("rank"):
            query("""
                UPDATE doctor SET specialty=%s, rank=%s WHERE staff_id=%s
            """, [d.get("specialty"), d.get("rank"), sid], fetch="none")
        return ok(msg="Ο γιατρός ενημερώθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/nurses/<int:sid>/update", methods=["GET", "POST", "OPTIONS"])
def update_nurse(sid):
    if request.method == "OPTIONS": return "", 200
    d = request.args.to_dict() if request.method=="GET" else (request.get_json(force=True,silent=True) or {})
    try:
        query("""
            UPDATE staff SET first_name=%s, last_name=%s, date_of_birth=%s, hire_date=%s
            WHERE staff_id=%s
        """, [d.get("first_name"), d.get("last_name"),
              d.get("date_of_birth") or None,
              d.get("hire_date") or None, sid], fetch="none")
        dept_name = d.get("department_name") or None
        if d.get("rank") or dept_name:
            query("""
                UPDATE nurse SET nurse_rank=%s, department_name=%s WHERE staff_id=%s
            """, [d.get("rank"), dept_name, sid], fetch="none")
        return ok(msg="Ο νοσηλευτής ενημερώθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


# ══════════════════════════════════════════════════════════════════════════════
# NURSES
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/api/nurses", methods=["GET", "OPTIONS"])
def get_nurses():
    rows = query("""
        SELECT s.*, n.nurse_rank, n.department_name,
               img.url AS image_url
        FROM staff s
        JOIN nurse n ON s.staff_id = n.staff_id
        LEFT JOIN LATERAL (
            SELECT url FROM image WHERE staff_id = s.staff_id AND is_public = TRUE
            ORDER BY image_id DESC LIMIT 1
        ) img ON TRUE
        ORDER BY s.staff_id DESC
    """)
    return ok([dict(r) for r in rows])


@app.route("/api/nurses", methods=["POST", "OPTIONS"])
def create_nurse():
    d = request.get_json(force=True, silent=True) or {}
    if not d.get("first_name") or not d.get("last_name") or not d.get("department_name"):
        return err("Απαιτούνται: first_name, last_name, department_name.")
    try:
        conn = get_db()
        cur  = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cur.execute("""
            INSERT INTO staff (amka, first_name, last_name, date_of_birth, email, phone, hire_date, staff_type)
            VALUES (%s,%s,%s,%s,%s,%s,%s,'Νοσηλευτής') RETURNING staff_id
        """, [
            d.get("amka") or None,
            d["first_name"], d["last_name"],
            d.get("date_of_birth") or "1990-01-01",
            d.get("email") or None,
            d.get("phone") or None,
            d.get("hire_date") or "2024-01-01"
        ])
        sid = cur.fetchone()["staff_id"]

        cur.execute("""
            INSERT INTO nurse (staff_id, nurse_rank, department_name)
            VALUES (%s,%s,%s)
        """, [sid, d.get("rank", "Νοσηλευτής"), d["department_name"]])

        conn.commit(); cur.close(); conn.close()
        return ok({"staff_id": sid}, "Ο νοσηλευτής καταχωρήθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/nurses/<int:sid>", methods=["DELETE", "OPTIONS"])
def delete_nurse(sid):
    try:
        query("DELETE FROM staff WHERE staff_id = %s", [sid], fetch="none")
        return ok(msg="Διαγράφηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


# ══════════════════════════════════════════════════════════════════════════════
# PRESCRIPTIONS
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/api/prescriptions", methods=["GET", "OPTIONS"])
def get_prescs():
    rows = query("""
        SELECT pr.prescription_id, pr.doctor_id, pr.patient_id,
               pr.drug_code, pr.hospitalization_id,
               pr.dosage, pr.frequency,
               pr.start_date, pr.end_date,
               p.first_name, p.last_name,
               s.first_name AS doc_fn, s.last_name AS doc_ln
        FROM prescription pr
        JOIN patient p ON pr.patient_id = p.patient_id
        LEFT JOIN staff s ON s.staff_id = pr.doctor_id
        ORDER BY pr.prescription_id DESC
    """)
    return ok([dict(r) for r in rows])


@app.route("/api/prescriptions", methods=["POST", "OPTIONS"])
def create_presc():
    d = request.get_json(force=True, silent=True) or {}
    required = ["patient_id","doctor_id","drug_code","hospitalization_id","dosage","frequency","start_date","end_date"]
    missing  = [f for f in required if not d.get(f)]
    if missing:
        return err(f"Απαιτούνται: {', '.join(missing)}")
    try:
        row = query("""
            INSERT INTO prescription
                (patient_id, doctor_id, drug_code, hospitalization_id,
                 dosage, frequency, start_date, end_date)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            RETURNING prescription_id
        """, [
            d["patient_id"], d["doctor_id"], d["drug_code"], d["hospitalization_id"],
            d["dosage"], d["frequency"], d["start_date"], d["end_date"]
        ], fetch="one")
        return ok({"prescription_id": row["prescription_id"]}, "Η συνταγή καταχωρήθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


# ══════════════════════════════════════════════════════════════════════════════
# REFERENCE DATA (για dropdowns)
# ══════════════════════════════════════════════════════════════════════════════

@app.route("/api/admin", methods=["GET", "OPTIONS"])
def get_admin():
    if request.method == "OPTIONS": return "", 200
    rows = query("""
        SELECT s.staff_id, s.first_name, s.last_name, s.date_of_birth, s.hire_date,
               s.amka, s.email, s.phone,
               a.role, a.office, a.department_name,
               img.url AS image_url
        FROM admin_staff a
        JOIN staff s ON s.staff_id = a.staff_id
        LEFT JOIN LATERAL (
            SELECT url FROM image WHERE staff_id = s.staff_id AND is_public = TRUE
            ORDER BY image_id DESC LIMIT 1
        ) img ON TRUE
        ORDER BY s.last_name, s.first_name
    """)
    return ok([dict(r) for r in rows])


@app.route("/api/admin", methods=["POST", "OPTIONS"])
def create_admin():
    if request.method == "OPTIONS": return "", 200
    d = request.get_json(force=True, silent=True) or {}
    required = ["first_name","last_name","date_of_birth","hire_date","role","department_name"]
    missing  = [f for f in required if not d.get(f)]
    if missing: return err(f"Απαιτούνται: {', '.join(missing)}")
    try:
        conn = get_db()
        cur  = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("""
            INSERT INTO staff (amka, first_name, last_name, date_of_birth, email, phone, hire_date, staff_type)
            VALUES (%s,%s,%s,%s,%s,%s,%s,'Διοικητικό Προσωπικό') RETURNING staff_id
        """, [
            d.get("amka") or None,
            d["first_name"], d["last_name"],
            d.get("date_of_birth"),
            d.get("email") or None,
            d.get("phone") or None,
            d["hire_date"]
        ])
        sid = cur.fetchone()["staff_id"]
        cur.execute("""
            INSERT INTO admin_staff (staff_id, role, office, department_name)
            VALUES (%s,%s,%s,%s)
        """, [sid, d["role"], d.get("office") or None, d["department_name"]])
        conn.commit(); cur.close(); conn.close()
        return ok({"staff_id": sid}, "Ο υπάλληλος καταχωρήθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/admin/<int:sid>/update", methods=["GET","POST","OPTIONS"])
def update_admin(sid):
    if request.method == "OPTIONS": return "", 200
    d = request.args.to_dict() if request.method=="GET" else (request.get_json(force=True,silent=True) or {})
    try:
        query("""
            UPDATE staff SET first_name=%s, last_name=%s, date_of_birth=%s, hire_date=%s
            WHERE staff_id=%s
        """, [d.get("first_name"), d.get("last_name"),
              d.get("date_of_birth") or None,
              d.get("hire_date") or None, sid], fetch="none")
        query("""
            UPDATE admin_staff SET role=%s, office=%s, department_name=%s
            WHERE staff_id=%s
        """, [d.get("role"), d.get("office") or None,
              d.get("department_name") or None, sid], fetch="none")
        return ok(msg="Ο υπάλληλος ενημερώθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/admin/<int:sid>", methods=["DELETE","OPTIONS"])
def delete_admin(sid):
    if request.method == "OPTIONS": return "", 200
    try:
        query("DELETE FROM staff WHERE staff_id=%s", [sid], fetch="none")
        return ok(msg="Ο υπάλληλος διαγράφηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/staff/<int:sid>/image", methods=["GET", "POST", "OPTIONS"])
def staff_image(sid):
    """Ανάκτηση/αποθήκευση εικόνας προσωπικού μέσω πίνακα image."""
    if request.method == "OPTIONS": return "", 200
    if request.method == "GET":
        row = query("""
            SELECT url FROM image WHERE staff_id = %s AND is_public = TRUE
            ORDER BY image_id DESC LIMIT 1
        """, [sid], fetch="one")
        return ok({"url": row["url"] if row else None})
    # POST
    d = request.get_json(force=True, silent=True) or {}
    url = (d.get("url") or d.get("image_url") or "").strip()
    if not url:
        return err("Απαιτείται url εικόνας.")
    try:
        # Διαγραφή παλιάς εικόνας αν υπάρχει
        query("DELETE FROM image WHERE staff_id = %s", [sid], fetch="none")
        query("""
            INSERT INTO image (staff_id, url, caption, is_public)
            VALUES (%s, %s, %s, TRUE)
        """, [sid, url, f"Staff {sid} photo"], fetch="none")
        return ok({"url": url}, "Η φωτογραφία αποθηκεύτηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/patients/<int:pid>/image", methods=["GET", "POST", "OPTIONS"])
def patient_image(pid):
    """Ανάκτηση/αποθήκευση εικόνας ασθενή μέσω πίνακα image."""
    if request.method == "OPTIONS": return "", 200
    if request.method == "GET":
        row = query("""
            SELECT url FROM image WHERE patient_id = %s AND is_public = TRUE
            ORDER BY image_id DESC LIMIT 1
        """, [pid], fetch="one")
        return ok({"url": row["url"] if row else None})
    # POST
    d = request.get_json(force=True, silent=True) or {}
    url = (d.get("url") or d.get("image_url") or "").strip()
    if not url:
        return err("Απαιτείται url εικόνας.")
    try:
        query("DELETE FROM image WHERE patient_id = %s", [pid], fetch="none")
        query("""
            INSERT INTO image (patient_id, url, caption, is_public)
            VALUES (%s, %s, %s, TRUE)
        """, [pid, url, f"Patient {pid} photo"], fetch="none")
        return ok({"url": url}, "Η φωτογραφία αποθηκεύτηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/departments", methods=["GET", "OPTIONS"])
def get_departments():
    rows = query("SELECT department_name, department_description, bed_capacity FROM department ORDER BY department_name")
    return ok([dict(r) for r in rows])

@app.route("/api/duties", methods=["GET", "OPTIONS"])
def get_duties():
    date       = request.args.get("date", "").strip()
    dept_name  = request.args.get("department_name", "").strip()
    shift_type = request.args.get("shift_type", "").strip()

    sql = """
        SELECT
            ss.shift_id || '-' || ss.staff_id AS duty_id,
            ss.staff_id,
            s.first_name,
            s.last_name,
            CASE WHEN doc.staff_id IS NOT NULL THEN 'Γιατρός' ELSE 'Νοσηλευτής' END AS staff_role,
            COALESCE(doc.specialty, nr.nurse_rank) AS specialty_or_rank,
            sh.shift_id,
            sh.shift_type,
            sh.shift_date AS shift_date,
            sh.department_name
        FROM shift_staff ss
        JOIN staff      s   ON s.staff_id  = ss.staff_id
        JOIN shifts     sh  ON sh.shift_id = ss.shift_id
        LEFT JOIN doctor doc ON doc.staff_id = ss.staff_id
        LEFT JOIN nurse  nr  ON nr.staff_id  = ss.staff_id
        WHERE 1=1
    """
    params = []

    if date:
        sql += " AND sh.shift_date = %s"
        params.append(date)
    if dept_name:
        sql += " AND sh.department_name = %s"
        params.append(dept_name)
    if shift_type:
        sql += " AND sh.shift_type = %s"
        params.append(shift_type)

    sql += " ORDER BY sh.shift_date, sh.shift_type, sh.department_name, s.last_name"

    rows = query(sql, params)
    return ok([dict(r) for r in rows])

@app.route("/api/duties/week", methods=["GET", "OPTIONS"])
def get_duties_week():
    """Επιστρέφει σύνοψη εφημεριών για μια εβδομάδα από δοθείσα ημερομηνία."""
    date = request.args.get("date", "").strip()
    if not date:
        return err("Απαιτείται παράμετρος date.")

    rows = query("""
        SELECT
            sh.department_name,
            sh.shift_date AS shift_date,
            sh.shift_type,
            COUNT(ss.staff_id) AS staff_count
        FROM shifts sh
        LEFT JOIN shift_staff ss ON ss.shift_id = sh.shift_id
        WHERE sh.shift_date BETWEEN %s::date AND %s::date + INTERVAL '6 days'
        GROUP BY sh.department_name, sh.shift_date, sh.shift_type
        ORDER BY sh.department_name, sh.shift_date, sh.shift_type
    """, [date, date])
    return ok([dict(r) for r in rows])

@app.route("/api/insurers", methods=["GET", "OPTIONS"])
def get_insurers():
    rows = query("SELECT insurer_id, name, type FROM insurer ORDER BY insurer_id")
    return ok([dict(r) for r in rows])

@app.route("/api/countries", methods=["GET", "OPTIONS"])
def get_countries():
    rows = query("SELECT country_code, name FROM country ORDER BY name")
    return ok([dict(r) for r in rows])

@app.route("/api/triage/pending", methods=["GET", "OPTIONS"])
def get_pending_triage():
    """Επιστρέφει triage που ΔΕΝ έχουν ήδη νοσηλεία."""
    rows = query("""
        SELECT t.triage_id, t.patient_id, t.arrival_time, t.urgency_level,
               p.first_name, p.last_name, t.referred_dept_name, t.outcome
        FROM triage t
        JOIN patient p ON t.patient_id = p.patient_id
        WHERE NOT EXISTS (
            SELECT 1 FROM hospitalization h WHERE h.triage_id = t.triage_id
        )
        ORDER BY t.urgency_level ASC, t.arrival_time DESC
        LIMIT 200
    """)
    return ok([dict(r) for r in rows])

@app.route("/api/cost_breakdown", methods=["GET", "OPTIONS"])
def get_cost_breakdown():
    """Κόστος ανά νοσηλεία — direct query."""
    dept = request.args.get("department_name", "").strip()
    sql = """
        SELECT
            h.hospitalization_id,
            h.patient_id,
            p.first_name  AS patient_first_name,
            p.last_name   AS patient_last_name,
            h.department_name,
            h.admission_date,
            h.discharge_date,
            h.ken_code,
            k.base_cost                                              AS ken_base_cost,
            k.avg_duration_days                                      AS ken_avg_days,
            k.daily_extra                                            AS ken_daily_extra,
            GREATEST(0,
                (h.discharge_date - h.admission_date)::NUMERIC
                - COALESCE(k.avg_duration_days, 0)
            )                                                        AS extra_days,
            COALESCE(
                k.base_cost + GREATEST(0,
                    (h.discharge_date - h.admission_date)::NUMERIC
                    - COALESCE(k.avg_duration_days, 0)
                ) * COALESCE(k.daily_extra, 0),
                0
            )                                                        AS ken_total,
            0::NUMERIC                                               AS lab_exams_cost,
            h.total_cost                                             AS stored_total_cost
        FROM hospitalization h
        JOIN patient p ON h.patient_id = p.patient_id
        LEFT JOIN ken k ON h.ken_code = k.ken_code
        WHERE h.discharge_date IS NOT NULL
    """
    params = []
    if dept:
        sql += " AND h.department_name = %s"
        params.append(dept)
    sql += " ORDER BY h.hospitalization_id DESC LIMIT 500"
    rows = query(sql, params)
    return ok([dict(r) for r in rows])


@app.route("/api/shift_summary", methods=["GET", "OPTIONS"])
def get_shift_summary():
    """Μηνιαία σύνοψη βαρδιών — χρησιμοποιεί duty_assignment."""
    year     = request.args.get("year",     "").strip()
    month    = request.args.get("month",    "").strip()
    staff_id = request.args.get("staff_id", "").strip()
    sql = """
        SELECT
            ss.staff_id,
            s.first_name,
            s.last_name,
            s.staff_type,
            EXTRACT(YEAR  FROM sh.shift_date)::INT AS year,
            EXTRACT(MONTH FROM sh.shift_date)::INT AS month,
            COUNT(*)                                AS shift_count,
            COUNT(*) FILTER (WHERE sh.shift_type = 'Πρωινή Βάρδια (07:00-15:00)')       AS morning_shifts,
            COUNT(*) FILTER (WHERE sh.shift_type = 'Απογευματινή Βάρδια (15:00-23:00)') AS afternoon_shifts,
            COUNT(*) FILTER (WHERE sh.shift_type = 'Νυχτερινή Βάρδια (23:00-07:00)')   AS night_shifts,
            STRING_AGG(DISTINCT sh.shift_type, ',')                                      AS shift_types_debug
        FROM shift_staff ss
        JOIN staff  s  ON ss.staff_id  = s.staff_id
        JOIN shifts sh ON ss.shift_id  = sh.shift_id
        WHERE 1=1
    """
    params = []
    if year:
        sql += " AND EXTRACT(YEAR  FROM sh.shift_date) = %s"; params.append(year)
    if month:
        sql += " AND EXTRACT(MONTH FROM sh.shift_date) = %s"; params.append(month)
    if staff_id:
        sql += " AND ss.staff_id = %s"; params.append(staff_id)
    sql += """
        GROUP BY ss.staff_id, s.first_name, s.last_name, s.staff_type,
                 EXTRACT(YEAR FROM sh.shift_date), EXTRACT(MONTH FROM sh.shift_date)
        ORDER BY year DESC, month DESC, shift_count DESC
        LIMIT 200
    """
    rows = query(sql, params)
    return ok([dict(r) for r in rows])


@app.route("/api/staff_profile/<int:sid>", methods=["GET", "OPTIONS"])
def get_staff_profile(sid):
    """Πλήρες προφίλ ιατρού — direct query."""
    row = query("""
        SELECT
            s.staff_id, s.first_name, s.last_name, s.amka, s.email, s.phone,
            s.hire_date, s.staff_type, s.date_of_birth,
            d.license_number AS doctor_license,
            d.specialty      AS doctor_specialty,
            d.rank           AS doctor_rank,
            sup.staff_id     AS supervisor_id,
            sup_s.first_name AS supervisor_first_name,
            sup_s.last_name  AS supervisor_last_name,
            dd.department_name AS doctor_department
        FROM staff s
        LEFT JOIN doctor d        ON s.staff_id    = d.staff_id
        LEFT JOIN doctor sup      ON d.supervisor_id = sup.staff_id
        LEFT JOIN staff  sup_s    ON sup.staff_id   = sup_s.staff_id
        LEFT JOIN doctor_department dd ON d.staff_id = dd.doctor_id
        WHERE s.staff_id = %s
        LIMIT 1
    """, [sid], fetch="one")
    if not row:
        return err("Δεν βρέθηκε.", 404)
    return ok(dict(row))


@app.route("/api/reviews", methods=["GET", "OPTIONS"])
def get_reviews():
    """Αξιολογήσεις νοσηλειών και ιατρών — χρησιμοποιεί views v_hospitalization_review_avg και v_doctor_review_avg."""
    hosp_reviews = query("""
        SELECT
            phr.hospitalization_review_id,
            phr.hospitalization_id,
            p.first_name || ' ' || p.last_name AS patient_name,
            h.department_name,
            h.admission_date,
            h.discharge_date,
            phr.nursing_care_score,
            phr.cleanliness_score,
            phr.food_score,
            phr.overall_score,
            ROUND((phr.nursing_care_score + phr.cleanliness_score + phr.food_score + phr.overall_score) / 4.0, 2) AS avg_score
        FROM patient_hospitalization_review phr
        JOIN hospitalization h ON phr.hospitalization_id = h.hospitalization_id
        JOIN patient p ON h.patient_id = p.patient_id
        ORDER BY phr.hospitalization_review_id DESC
    """)
    doc_reviews = query("""
        SELECT
            pdr.doctor_review_id,
            pdr.hospitalization_id,
            pdr.doctor_id,
            s.first_name || ' ' || s.last_name AS doctor_name,
            d.specialty AS doctor_specialty,
            p.first_name || ' ' || p.last_name AS patient_name,
            h.department_name,
            h.discharge_date,
            pdr.medical_care_score
        FROM patient_doctor_review pdr
        JOIN doctor d ON pdr.doctor_id = d.staff_id
        JOIN staff s ON pdr.doctor_id = s.staff_id
        JOIN hospitalization h ON pdr.hospitalization_id = h.hospitalization_id
        JOIN patient p ON h.patient_id = p.patient_id
        ORDER BY pdr.doctor_review_id DESC
    """)
    # Μέσοι όροι από views
    hosp_avg = query("SELECT hospitalization_id, avg_score FROM v_hospitalization_review_avg") or []
    doc_avg  = query("SELECT doctor_id, avg_score FROM v_doctor_review_avg") or []
    return ok({
        "hospitalization_reviews": [dict(r) for r in hosp_reviews],
        "doctor_reviews":          [dict(r) for r in doc_reviews],
        "hosp_avg_by_id":          {r["hospitalization_id"]: float(r["avg_score"]) for r in hosp_avg},
        "doc_avg_by_id":           {r["doctor_id"]: float(r["avg_score"]) for r in doc_avg},
    })

@app.route("/api/icd10", methods=["GET", "OPTIONS"])
def get_icd10():
    rows = query("SELECT icd10_code, description, category FROM icd10_code ORDER BY icd10_code")
    return ok([dict(r) for r in rows])

@app.route("/api/drugs", methods=["GET", "OPTIONS"])
def get_drugs():
    rows = query("SELECT drug_code, name FROM drug ORDER BY name")
    return ok([dict(r) for r in rows])

@app.route("/api/stats", methods=["GET", "OPTIONS"])
def get_stats():
    patients = query("SELECT COUNT(*) AS c FROM patient", fetch="one")["c"]
    active   = query("SELECT COUNT(*) AS c FROM hospitalization WHERE discharge_date IS NULL", fetch="one")["c"]
    pending  = query("SELECT COUNT(*) AS c FROM triage WHERE outcome IS NULL", fetch="one")["c"]
    doctors  = query("SELECT COUNT(*) AS c FROM doctor", fetch="one")["c"]
    nurses   = query("SELECT COUNT(*) AS c FROM nurse", fetch="one")["c"]
    return ok({
        "patients": patients,
        "active_hospitalizations": active,
        "pending_triage": pending,
        "staff": int(doctors) + int(nurses)
    })

@app.route("/api/procedures", methods=["GET", "OPTIONS"])
def get_procedures():
    if request.method == "OPTIONS":
        return ok()

    hid = request.args.get("hospitalization_id", "").strip()
    cat = request.args.get("category", "").strip()
    q   = request.args.get("q", "").strip()

    sql = """
        SELECT
            hp.hosp_procedure_id                        AS procedure_id,
            hp.hospitalization_id,
            p.first_name || ' ' || p.last_name          AS patient_name,
            h.department_name,
            mp.description                              AS procedure_name,
            hp.procedure_code,
            mp.category,
            s.first_name || ' ' || s.last_name          AS lead_doctor_name,
            d.specialty                                 AS doctor_specialty,
            hp.performed_date::TEXT                     AS start_time,
            k.avg_duration_days                         AS ken_avg_days,
            k.base_cost                                 AS cost,
            hp.notes,
            h.ken_code,
            k.description                               AS ken_description
        FROM hospitalization_procedure hp
        JOIN hospitalization   h  ON hp.hospitalization_id = h.hospitalization_id
        JOIN patient           p  ON h.patient_id          = p.patient_id
        JOIN medical_procedure mp ON hp.procedure_code     = mp.procedure_code
        JOIN staff             s  ON hp.performed_by       = s.staff_id
        JOIN doctor            d  ON hp.performed_by       = d.staff_id
        LEFT JOIN ken_code     k  ON h.ken_code            = k.ken_code
        WHERE 1=1
    """
    params = []
    if hid:
        sql += " AND hp.hospitalization_id = %s"
        params.append(hid)
    if cat:
        sql += " AND mp.category = %s"
        params.append(cat)
    if q:
        sql += " AND (LOWER(mp.description) LIKE %s OR LOWER(hp.procedure_code) LIKE %s OR LOWER(p.last_name) LIKE %s)"
        val = f"%{q.lower()}%"
        params += [val, val, val]

    sql += " ORDER BY hp.performed_date DESC"

    try:
        rows = query(sql, params)
        if not rows:
            return ok([])

        proc_ids = [r["procedure_id"] for r in rows]
        placeholders = ",".join(["%s"] * len(proc_ids))
        parts_sql = f"""
            SELECT pp.hosp_procedure_id,
                   s.first_name || ' ' || s.last_name AS staff_name,
                   pp.role
            FROM procedure_participant pp
            JOIN staff s ON s.staff_id = pp.staff_id
            WHERE pp.hosp_procedure_id IN ({placeholders})
        """
        parts = query(parts_sql, proc_ids) or []

        parts_map = {}
        for pt in parts:
            pid = pt["hosp_procedure_id"]
            parts_map.setdefault(pid, []).append(f"{pt['staff_name']} ({pt['role']})")

        for r in rows:
            r["participants"] = parts_map.get(r["procedure_id"], [])

        return ok(rows)
    except Exception as e:
        return err(str(e))


@app.route("/api/procedures", methods=["POST", "OPTIONS"])
def create_procedure():
    """Καταχώρηση νέας ιατρικής πράξης στο hospitalization_procedure."""
    if request.method == "OPTIONS":
        return ok()
    d = request.get_json(force=True, silent=True) or {}
    required = ["hospitalization_id", "procedure_code", "performed_date", "performed_by"]
    missing  = [f for f in required if not d.get(f)]
    if missing:
        return err(f"Απαιτούνται: {', '.join(missing)}")
    try:
        row = query("""
            INSERT INTO hospitalization_procedure
                (hospitalization_id, procedure_code, performed_date, performed_by, notes)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING hosp_procedure_id
        """, [
            d["hospitalization_id"],
            d["procedure_code"],
            d["performed_date"],
            d["performed_by"],
            d.get("notes") or None,
        ], fetch="one")

        hosp_proc_id = row["hosp_procedure_id"]
        for part in d.get("participants", []):
            if part.get("staff_id"):
                query("""
                    INSERT INTO procedure_participant (hosp_procedure_id, staff_id, role)
                    VALUES (%s, %s, %s)
                    ON CONFLICT DO NOTHING
                """, [hosp_proc_id, part["staff_id"], part.get("role") or None], fetch="none")

        return ok({"hosp_procedure_id": hosp_proc_id}, "Η ιατρική πράξη καταχωρήθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/labs", methods=["GET", "OPTIONS"])
def get_labs():
    """Εργαστηριακές εξετάσεις — πίνακας lab_exam."""
    hid = request.args.get("hospitalization_id", "").strip()
    q   = request.args.get("q", "").strip()
    sql = """
        SELECT
            le.hosp_lab_id                           AS exam_id,
            le.hospitalization_id,
            le.ordered_by                            AS ordering_doctor_id,
            s.first_name || ' ' || s.last_name       AS doctor_name,
            d.specialty                              AS doctor_specialty,
            le.lab_code                              AS code,
            lx.description                           AS lab_description,
            le.ordered_date                          AS exam_date,
            le.result_date,
            le.result_value,
            le.result_unit                           AS unit,
            0::NUMERIC                               AS cost,
            p.first_name || ' ' || p.last_name       AS patient_name,
            h.department_name
        FROM hospitalization_lab le
        JOIN hospitalization h  ON le.hospitalization_id = h.hospitalization_id
        JOIN patient         p  ON h.patient_id          = p.patient_id
        JOIN staff           s  ON le.ordered_by         = s.staff_id
        JOIN doctor          d  ON le.ordered_by         = d.staff_id
        LEFT JOIN lab_exam  lx  ON le.lab_code           = lx.lab_code
        WHERE 1=1
    """
    params = []
    if hid:
        sql += " AND le.hospitalization_id = %s"
        params.append(hid)
    if q:
        sql += " AND (LOWER(COALESCE(lx.description,'')) LIKE %s OR LOWER(le.lab_code) LIKE %s)"
        params += [f"%{q.lower()}%", f"%{q.lower()}%"]
    sql += " ORDER BY le.ordered_date DESC"
    rows = query(sql, params)
    return ok([dict(r) for r in rows])


@app.route("/api/labs", methods=["POST", "OPTIONS"])
def create_lab():
    """Καταχώρηση νέας εργαστηριακής εξέτασης στο lab_exam."""
    if request.method == "OPTIONS":
        return ok()
    d = request.get_json(force=True, silent=True) or {}
    required = ["hospitalization_id", "ordering_doctor_id", "lab_code", "exam_date"]
    missing  = [f for f in required if not d.get(f)]
    if missing:
        return err(f"Απαιτούνται: {', '.join(missing)}")
    try:
        row = query("""
            INSERT INTO hospitalization_lab
                (hospitalization_id, ordered_by, lab_code, ordered_date,
                 result_date, result_value, result_unit)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING hosp_lab_id
        """, [
            d["hospitalization_id"],
            d["ordering_doctor_id"],
            d["lab_code"],
            d["exam_date"],
            d.get("result_date") or None,
            d.get("result_value") or None,
            d.get("unit") or None,
        ], fetch="one")
        return ok({"exam_id": row["hosp_lab_id"]}, "Η εργαστηριακή εξέταση καταχωρήθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")


@app.route("/api/available_beds", methods=["GET", "OPTIONS"])
def get_available_beds():
    """Διαθέσιμες κλίνες ανά τμήμα — από view v_available_beds."""
    dept = request.args.get("department_name", "").strip()
    if not dept:
        rows = query("""
            SELECT bed_id, department_name, bed_type, status, floor_building, available_beds_in_dept
            FROM v_available_beds
            ORDER BY department_name, bed_id
        """)
    else:
        rows = query("""
            SELECT bed_id, department_name, bed_type, status, floor_building, available_beds_in_dept
            FROM v_available_beds
            WHERE department_name = %s
            ORDER BY bed_id
        """, [dept])
    return ok([dict(r) for r in rows])



@app.route("/api/run_query", methods=["POST", "OPTIONS"])
def run_query():
    """Εκτελεί ένα από τα προκαθορισμένα queries της άσκησης."""
    if request.method == "OPTIONS": return "", 200
    d = request.get_json(force=True, silent=True) or {}
    qid   = d.get("query_id", "")
    params = d.get("params", {})

    QUERIES = {
        "Q01": ("""
SELECT
    h.department_name,
    EXTRACT(YEAR FROM h.discharge_date)::INT AS year,
    h.ken_code,
    k.description AS ken_description,
    i.name AS insurer_name,
    i.type AS insurer_type,
    k.base_cost AS ken_base_cost,
    SUM(GREATEST(0,(h.discharge_date-h.admission_date)-k.avg_duration_days)*k.daily_extra) AS total_extra_charge,
    COUNT(h.hospitalization_id) AS hosp_count,
    SUM(h.total_cost) AS total_revenue
FROM hospitalization h
JOIN patient p ON h.patient_id=p.patient_id
JOIN insurer i ON p.insurer_id=i.insurer_id
JOIN ken k ON h.ken_code=k.ken_code
WHERE h.discharge_date IS NOT NULL
GROUP BY h.department_name,EXTRACT(YEAR FROM h.discharge_date),h.ken_code,k.description,k.base_cost,k.avg_duration_days,k.daily_extra,i.name,i.type
ORDER BY year DESC,h.department_name,total_revenue DESC
""", []),

        "Q02": ("""
SELECT st.staff_id,st.first_name,st.last_name,doc.specialty,doc.rank,
    CASE WHEN EXISTS(SELECT 1 FROM shift_staff ss JOIN shifts sh ON ss.shift_id=sh.shift_id WHERE ss.staff_id=st.staff_id AND EXTRACT(YEAR FROM sh.shift_date)=EXTRACT(YEAR FROM CURRENT_DATE)) THEN 'ΝΑΙ' ELSE 'ΟΧΙ' END AS had_shift_this_year,
    COUNT(hp.hosp_procedure_id) AS lead_doctor_procedures
FROM staff st JOIN doctor doc ON st.staff_id=doc.staff_id
LEFT JOIN hospitalization_procedure hp ON hp.performed_by=st.staff_id
WHERE doc.specialty=%s
GROUP BY st.staff_id,st.first_name,st.last_name,doc.specialty,doc.rank
ORDER BY lead_doctor_procedures DESC,st.last_name
""", ["specialty"]),

        "Q03": ("""
SELECT pt.patient_id,pt.first_name,pt.last_name,hp.department_name,COUNT(hp.hospitalization_id) AS hosp_count,SUM(hp.total_cost) AS total_cost
FROM hospitalization hp JOIN patient pt ON hp.patient_id=pt.patient_id
WHERE hp.discharge_date IS NOT NULL
GROUP BY pt.patient_id,pt.first_name,pt.last_name,hp.department_name
HAVING COUNT(hp.hospitalization_id)>3
ORDER BY hosp_count DESC,pt.last_name
""", []),

        "Q05": ("""
SELECT st.staff_id,st.first_name,st.last_name,EXTRACT(YEAR FROM AGE(st.date_of_birth))::INT AS age,doc.rank,COUNT(hp.hosp_procedure_id) AS procedures_count
FROM staff st JOIN doctor doc ON st.staff_id=doc.staff_id
JOIN hospitalization_procedure hp ON hp.performed_by=doc.staff_id
JOIN medical_procedure mp ON hp.procedure_code=mp.procedure_code
WHERE EXTRACT(YEAR FROM AGE(st.date_of_birth))<35 AND mp.category=%s
GROUP BY st.staff_id,st.first_name,st.last_name,st.date_of_birth,doc.rank
ORDER BY procedures_count DESC,age ASC
""", ["category"]),

        "Q07": ("""
SELECT a.name,COUNT(DISTINCT pa.patient_id) AS patient_count,COUNT(DISTINCT ds.drug_code) AS drug_count
FROM active_substance a
LEFT JOIN patient_allergy pa ON a.name=pa.active_substance
LEFT JOIN drug_substance ds ON a.name=ds.active_substance_name
GROUP BY a.name
ORDER BY patient_count DESC
""", []),

        "Q08": ("""
SELECT st.staff_id,st.first_name,st.last_name,st.staff_type
FROM staff st
WHERE NOT EXISTS(SELECT 1 FROM shift_staff ss JOIN shifts sh ON ss.shift_id=sh.shift_id WHERE ss.staff_id=st.staff_id AND sh.shift_date=%s AND sh.department_name=%s)
ORDER BY st.staff_type,st.last_name
""", ["date","department_name"]),

        "Q09": ("""
WITH hosp_days AS(
SELECT p.patient_id,p.first_name,p.last_name,SUM((h.discharge_date-h.admission_date)::INT) AS total_days,EXTRACT(YEAR FROM h.discharge_date)::INT AS year
FROM hospitalization h JOIN patient p ON h.patient_id=p.patient_id
WHERE h.discharge_date IS NOT NULL
GROUP BY p.patient_id,p.first_name,p.last_name,EXTRACT(YEAR FROM h.discharge_date)
HAVING SUM((h.discharge_date-h.admission_date)::INT)>15)
SELECT hd1.patient_id,hd1.first_name,hd1.last_name,hd1.total_days,hd1.year
FROM hosp_days hd1
WHERE EXISTS(SELECT 1 FROM hosp_days hd2 WHERE hd1.total_days=hd2.total_days AND hd1.patient_id<>hd2.patient_id AND hd1.year=hd2.year)
ORDER BY hd1.year DESC,hd1.total_days
""", []),

        "Q10": ("""
WITH substance_per_prescription AS(
SELECT pr.patient_id,pr.hospitalization_id,pr.drug_code,ds.active_substance_name AS substance
FROM prescription pr JOIN drug_substance ds ON pr.drug_code=ds.drug_code),
substance_pairs AS(
SELECT sp1.substance AS substance_a,sp2.substance AS substance_b,sp1.patient_id,sp2.hospitalization_id
FROM substance_per_prescription sp1
JOIN substance_per_prescription sp2 ON sp1.patient_id=sp2.patient_id AND sp1.hospitalization_id=sp2.hospitalization_id AND sp1.substance<sp2.substance)
SELECT substance_a,substance_b,COUNT(*) AS frequency FROM substance_pairs
GROUP BY substance_a,substance_b ORDER BY frequency DESC LIMIT 3
""", []),

        "Q11": ("""
WITH procedure_count AS(SELECT hp.performed_by AS doctor_id,COUNT(hp.hosp_procedure_id) AS num_of_procedures FROM hospitalization_procedure hp WHERE EXTRACT(YEAR FROM hp.performed_date)=%s GROUP BY hp.performed_by),
max_procedures AS(SELECT MAX(num_of_procedures) AS max_count FROM procedure_count)
SELECT pc.doctor_id,s.first_name,s.last_name,d.rank,pc.num_of_procedures,mp.max_count,(mp.max_count-pc.num_of_procedures) AS difference
FROM procedure_count pc JOIN max_procedures mp ON TRUE JOIN staff s ON pc.doctor_id=s.staff_id JOIN doctor d ON pc.doctor_id=d.staff_id
WHERE(mp.max_count-pc.num_of_procedures)>=5
ORDER BY pc.num_of_procedures DESC
""", ["year"]),

        "Q12": ("""
SELECT sh.department_name,sh.shift_date,sh.shift_type,s.staff_type,
    CASE WHEN doc.staff_id IS NOT NULL THEN doc.specialty WHEN n.staff_id IS NOT NULL THEN n.nurse_rank WHEN a.staff_id IS NOT NULL THEN a.role END AS subcategory,
    COUNT(ss.staff_id) AS staff_count
FROM shifts sh JOIN shift_staff ss ON sh.shift_id=ss.shift_id JOIN staff s ON ss.staff_id=s.staff_id
LEFT JOIN doctor doc ON s.staff_id=doc.staff_id LEFT JOIN nurse n ON s.staff_id=n.staff_id LEFT JOIN admin_staff a ON s.staff_id=a.staff_id
WHERE sh.shift_date BETWEEN %s AND %s
GROUP BY sh.department_name,sh.shift_date,sh.shift_type,s.staff_type,CASE WHEN doc.staff_id IS NOT NULL THEN doc.specialty WHEN n.staff_id IS NOT NULL THEN n.nurse_rank WHEN a.staff_id IS NOT NULL THEN a.role END
ORDER BY sh.shift_date,sh.department_name,sh.shift_type,s.staff_type,subcategory
""", ["date_from","date_to"]),

        "Q13": ("""
WITH RECURSIVE supervision_hierarchy AS(
SELECT d.staff_id AS doctor_id,s.first_name||' '||s.last_name AS doctor_name,d.rank AS doctor_rank,d.supervisor_id,0 AS level,d.staff_id AS root_id
FROM doctor d JOIN staff s ON d.staff_id=s.staff_id
UNION ALL
SELECT sup.staff_id,ss.first_name||' '||ss.last_name,sup.rank,sup.supervisor_id,h.level+1,h.root_id
FROM supervision_hierarchy h JOIN doctor sup ON h.supervisor_id=sup.staff_id JOIN staff ss ON sup.staff_id=ss.staff_id
WHERE h.supervisor_id IS NOT NULL)
SELECT h.root_id AS doctor_id,rs.first_name||' '||rs.last_name AS doctor_name,rd.rank AS doctor_rank,h.level,
    CASE h.level WHEN 0 THEN 'Ο ίδιος' WHEN 1 THEN 'Άμεσος Επόπτης' ELSE 'Επόπτης Επιπέδου '||h.level END AS level_description,
    h.doctor_id AS supervisor_id,h.doctor_name AS supervisor_name,h.doctor_rank AS supervisor_rank
FROM supervision_hierarchy h JOIN doctor rd ON h.root_id=rd.staff_id JOIN staff rs ON h.root_id=rs.staff_id
ORDER BY h.root_id,h.level
""", []),

        "Q14": ("""
WITH yearly_counts AS(
SELECT i.category,EXTRACT(YEAR FROM h.admission_date)::INT AS year,COUNT(h.hospitalization_id) AS hosp_count
FROM hospitalization h JOIN icd10_code i ON h.admission_diag_icd10=i.icd10_code
GROUP BY i.category,EXTRACT(YEAR FROM h.admission_date)
HAVING COUNT(h.hospitalization_id)>=5)
SELECT y1.category,y1.year AS year1,y2.year AS year2,y1.hosp_count AS count_year1,y2.hosp_count AS count_year2
FROM yearly_counts y1 JOIN yearly_counts y2 ON y1.category=y2.category AND y2.year=y1.year+1 AND y1.hosp_count=y2.hosp_count
ORDER BY y1.category,y1.year
""", []),

        "Q15": ("""
SELECT t.urgency_level,
    CASE t.urgency_level WHEN 1 THEN 'Άμεσο' WHEN 2 THEN 'Επείγον' WHEN 3 THEN 'Επιτακτικό' WHEN 4 THEN 'Λιγότερο επείγον' WHEN 5 THEN 'Μη επείγον' END AS urgency_label,
    SUM(COUNT(*)) OVER(PARTITION BY t.urgency_level) AS total_cases,
    ROUND(AVG(EXTRACT(EPOCH FROM(h.admission_date::TIMESTAMP-t.arrival_time))/60.0)::NUMERIC,2) AS avg_wait_minutes,
    SUM(COUNT(*) FILTER(WHERE t.outcome='παραπομπή για νοσηλεία')) OVER(PARTITION BY t.urgency_level) AS hospitalized_count,
    ROUND(100.0*SUM(COUNT(*) FILTER(WHERE t.outcome='παραπομπή για νοσηλεία')) OVER(PARTITION BY t.urgency_level)/SUM(COUNT(*)) OVER(PARTITION BY t.urgency_level),2) AS hospitalization_pct,
    t.referred_dept_name,
    COUNT(*) AS referrals_to_dept,
    ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(PARTITION BY t.urgency_level),2) AS pct_referrals_within_level
FROM triage t LEFT JOIN hospitalization h ON t.triage_id=h.triage_id
GROUP BY t.urgency_level,t.referred_dept_name
ORDER BY t.urgency_level,referrals_to_dept DESC
""", []),
    }

    if qid not in QUERIES:
        return err(f"Άγνωστο query: {qid}")

    sql, param_keys = QUERIES[qid]
    sql_params = [params.get(k) for k in param_keys]

    try:
        rows = query(sql, sql_params if sql_params else None)
        return ok({"rows": [dict(r) for r in rows] if rows else [], "count": len(rows) if rows else 0})
    except Exception as e:
        return err(f"Σφάλμα SQL: {str(e)}")



@app.route("/api/hospitalizations/<int:hid>/staff", methods=["GET", "POST", "OPTIONS"])
def hosp_staff(hid):
    if request.method == "OPTIONS": return "", 200
    if request.method == "GET":
        rows = query("""
            SELECT hs.staff_id, hs.role, hs.assigned_date,
                   s.first_name, s.last_name, s.staff_type,
                   d.specialty, d.rank
            FROM hospitalization_staff hs
            JOIN staff s ON hs.staff_id = s.staff_id
            LEFT JOIN doctor d ON d.staff_id = s.staff_id
            WHERE hs.hospitalization_id = %s
            ORDER BY hs.role, s.last_name
        """, [hid])
        return ok([dict(r) for r in rows])
    # POST
    d = request.get_json(force=True, silent=True) or {}
    if not d.get("staff_id") or not d.get("role"):
        return err("Απαιτούνται staff_id και role.")
    try:
        query("""
            INSERT INTO hospitalization_staff (hospitalization_id, staff_id, role, assigned_date)
            VALUES (%s, %s, %s, CURRENT_DATE)
            ON CONFLICT (hospitalization_id, staff_id) DO UPDATE SET role=EXCLUDED.role
        """, [hid, d["staff_id"], d["role"]], fetch="none")
        return ok(msg="Το προσωπικό καταχωρήθηκε.")
    except Exception as e:
        return err(f"Σφάλμα: {str(e)}")

@app.route("/api/doctors_by_dept", methods=["GET", "OPTIONS"])
def get_doctors_by_dept():
    """Γιατροί ανά τμήμα για το hospitalization modal."""
    dept = request.args.get("department_name", "").strip()
    if not dept:
        return err("Απαιτείται department_name.")
    rows = query("""
        SELECT s.staff_id, s.first_name, s.last_name, d.rank, d.specialty
        FROM doctor_department dd
        JOIN doctor d ON dd.doctor_id = d.staff_id
        JOIN staff  s ON s.staff_id   = d.staff_id
        WHERE dd.department_name = %s
        ORDER BY
            CASE d.rank
                WHEN 'Διευθυντής'   THEN 1
                WHEN 'Επιμελητής Α' THEN 2
                WHEN 'Επιμελητής Β' THEN 3
                ELSE 4
            END, s.last_name
    """, [dept])
    return ok([dict(r) for r in rows])

@app.route("/")
def serve_ui():
    import os
    folder = os.path.dirname(os.path.abspath(__file__))
    print(f"[DEBUG] Serving from: {folder}")
    print(f"[DEBUG] Files: {os.listdir(folder)}")
    return send_from_directory(folder, "hospital_ui.html")


@app.route("/queries")
def serve_queries():
    import os
    folder = os.path.dirname(os.path.abspath(__file__))
    return send_from_directory(folder, "queries.html")

if __name__ == "__main__":
    print("=" * 55)
    print("  Υγειούπολις HMS — Backend Server")
    print("  http://localhost:5000  ← Άνοιξε αυτό στον browser")
    print("=" * 55)
    app.run(debug=True, port=5000)