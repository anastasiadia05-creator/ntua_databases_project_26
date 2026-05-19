# Υγειούπολις — Σύστημα Διαχείρισης Νοσοκομείου

Διαδικτυακή εφαρμογή διαχείρισης νοσοκομείου με Flask backend και single-page HTML/JS frontend, συνδεδεμένη με PostgreSQL βάση δεδομένων.

---

## Προαπαιτούμενα

- Python 3.9+
- PostgreSQL 13+
- pip

---

## 1. Δημιουργία Βάσης Δεδομένων

Συνδέσου στην PostgreSQL και δημιούργησε τη βάση:

```sql
CREATE DATABASE hospital;
```

Έπειτα εισήγαγε το schema (αν έχεις `.sql` αρχείο):

```bash
psql -U postgres -d hospital -f schema.sql
```

---

## 2. Ρύθμιση Σύνδεσης στη Βάση

Άνοιξε το `app.py` και άλλαξε το `DB_CONFIG` με τα δικά σου στοιχεία:

```python
DB_CONFIG = {
    "host":     "localhost",
    "port":     5432,
    "database": "hospital",
    "user":     "postgres",
    "password": "ο_κωδικός_σου"
}
```

---

## 3. Εγκατάσταση Εξαρτήσεων

```bash
pip install flask flask-cors psycopg2-binary
```

---

## 4. Δομή Αρχείων

```
.
├── app.py              # Flask backend — όλα τα API routes
├── hospital_ui.html    # Κύριο frontend
├── queries.html        # Σελίδα αναλυτικών ερωτημάτων
└── README.md
```

Τα αρχεία `hospital_ui.html` και `queries.html` πρέπει να βρίσκονται στον **ίδιο φάκελο** με το `app.py`.

---

## 5. Εκκίνηση της Εφαρμογής

```bash
python app.py
```

---

## 6. Άνοιγμα στον Browser

Άνοιξε απευθείας το αρχείο `hospital_ui.html` στον browser σου (διπλό κλικ ή File → Open).


> Το frontend επικοινωνεί αυτόματα με τον Flask server που τρέχει στο παρασκήνιο.

---

## 7. API — Κύρια Endpoints

Όλα τα endpoints ξεκινούν με `/api/`. Η απόκριση έχει πάντα τη μορφή:

```json
{ "status": "ok", "message": "OK", "data": ... }
```

| Μέθοδος | Endpoint | Περιγραφή |
|---------|----------|-----------|
| GET | `/api/patients` | Λίστα ασθενών (`?search=`, `?gender=`) |
| GET | `/api/patients/<id>` | Πλήρες προφίλ ασθενή |
| POST | `/api/patients` | Δημιουργία ασθενή |
| PUT | `/api/patients/<id>` | Ενημέρωση ασθενή |
| DELETE | `/api/patients/<id>` | Διαγραφή ασθενή |
| GET/POST | `/api/hospitalizations` | Νοσηλείες |
| GET/POST | `/api/hospitalizations/<id>/staff` | Προσωπικό νοσηλείας |
| GET/POST | `/api/staff` | Προσωπικό |
| GET/POST | `/api/shifts` | Βάρδιες |
| GET | `/api/departments` | Τμήματα |
| GET | `/api/drugs` | Φάρμακα |
| POST | `/api/queries/<Q01–Q15>` | Εκτέλεση αναλυτικών ερωτημάτων |

---

## 8. Συχνά Προβλήματα

**Αδυναμία σύνδεσης στη βάση**
Βεβαιώσου ότι η PostgreSQL τρέχει και τα στοιχεία στο `DB_CONFIG` είναι σωστά:
```bash
psql -h localhost -U postgres -d hospital
```

**`ModuleNotFoundError: No module named 'psycopg2'`**
```bash
pip install psycopg2-binary
```

**Το HTML δεν φορτώνει δεδομένα**
Βεβαιώσου ότι ο Flask server (`python app.py`) τρέχει πριν ανοίξεις το HTML στον browser.
