# Task Management App

A production-oriented starter for the AWS Infrastructure Automation Platform workload.

## Architecture
- `frontend/`: React + Vite SPA; calls the FastAPI REST API (no browser storage as the source of truth).
- `backend/`: FastAPI, SQLAlchemy 2, PostgreSQL, Alembic migrations, pytest.
- PostgreSQL is the only supported application database. Configure it through `DATABASE_URL`.
- API uses UTC for stored timestamps; date-based views use `APP_TIMEZONE` (default `Asia/Kolkata`) to define local calendar boundaries.

## Local setup

### 1. PostgreSQL
Install PostgreSQL 15+ locally, or use Docker:
```bash
docker run --name task-manager-postgres \
  -e POSTGRES_DB=taskmanager -e POSTGRES_USER=taskapp \
  -e POSTGRES_PASSWORD=change-this-local-password \
  -p 5432:5432 -d postgres:16
```

### 2. Backend
```bash
cd backend
python -m venv .venv
# Windows PowerShell: .venv\Scripts\Activate.ps1
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Set DATABASE_URL in .env to your PostgreSQL connection string.
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
API docs: http://localhost:8000/docs. Health: http://localhost:8000/health.

### 3. Frontend
```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```
Open the URL printed by Vite (usually http://localhost:5173). Set `VITE_API_BASE_URL=http://localhost:8000/api/v1` if needed.

### Tests and build
```bash
cd backend
pip install -r requirements-dev.txt
pytest -q
```
```bash
cd frontend
npm run build
```
Tests use PostgreSQL-compatible SQLAlchemy models; the default test suite can use SQLite only as an isolated test adapter when configured by the test fixture, not as the app's runtime database.

## Features
Tasks: CRUD, status, priority, due dates, goal links, search/filter/sort and dynamic date views. Goals: CRUD, short/long-term type, target date, status and task-derived progress. Milestones: CRUD and goal-derived progress. Dashboard statistics are computed from database rows.

## AWS deployment notes
Recommended flow: Internet → ALB → EC2/Auto Scaling Group → RDS PostgreSQL.
1. Deploy the API and frontend assets behind a web server/reverse proxy (or serve built frontend from a dedicated static origin).
2. Configure `DATABASE_URL` from AWS Secrets Manager at instance boot or via the deployment platform; never commit credentials.
3. Restrict RDS inbound PostgreSQL (5432) to the application security group only. Do not expose RDS publicly.
4. Configure ALB target health check to `/health`; configure the app's `PORT` (default 8000).
5. Run `alembic upgrade head` as a controlled release step before routing traffic; do not run concurrent migrations independently on every instance.
6. Send stdout/stderr logs to CloudWatch using the CloudWatch Agent or your runtime logging integration.
7. Use IAM instance profiles for AWS access; do not put AWS keys in `.env`.
8. Use TLS at the ALB, least-privilege IAM, private subnets for application/database where possible, and RDS backups.
9. The app stores no durable user data on the EC2 filesystem and is stateless across instances.

## Configuration
See `backend/.env.example`. `DATABASE_URL` must be a PostgreSQL URL such as `postgresql+psycopg://user:password@host:5432/taskmanager`. The app does not silently fall back to SQLite.

## Troubleshooting
- `database_unavailable`: verify the PostgreSQL service, security groups, DNS, credentials, database name, and `DATABASE_URL`.
- Migration error: activate the backend environment, run `alembic current`, then `alembic upgrade head` once from the release environment.
- CORS error: set `CORS_ORIGINS` to the exact frontend origin, comma-separated if multiple.
- Frontend cannot reach API: check `VITE_API_BASE_URL`, API health endpoint and browser network panel.
- ALB unhealthy: confirm target port matches `PORT`, `/health` is reachable, and EC2 security group allows traffic from the ALB security group.
- RDS timeout: confirm DB subnet routing and inbound security-group rule; do not open 5432 to the internet.

## Scope and security
This initial project intentionally does not include authentication or authorization. Do not expose it publicly until an authentication layer and authorization policies are implemented. AWS resources are not created or changed by this repository.
