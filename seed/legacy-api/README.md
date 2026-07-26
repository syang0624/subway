# legacy-api

Internal REST API for the v1 mobile app (deprecated — superseded by TaskTomo's
built-in API routes). Kept around "just in case."

## Stack

- **FastAPI** — HTTP layer
- **Supabase** — Postgres backend

## Run

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```
