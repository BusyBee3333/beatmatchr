# beatmatchr backend

A lightweight FastAPI service that powers beatmatchr. This guide walks through
the steps required to run the backend locally.

## Prerequisites

- Python 3.10 or newer installed and available on your `PATH`.
- [`ffmpeg`](https://ffmpeg.org/) installed (macOS: `brew install ffmpeg`,
  Ubuntu/Debian: `sudo apt install ffmpeg`).
- Docker and Docker Compose (v2) for running Postgres and Redis.

## 1. Create and activate a virtual environment

```bash
python3 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
```

## 2. Install Python dependencies

With the virtual environment active, install the requirements:

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

## 3. Start Postgres and Redis via Docker Compose

A `docker-compose.yml` file is provided at the repository root. Launch the
services in the background:

```bash
docker compose up -d
```

This spins up:

- Postgres on port `5432` with database/user/password `beatmatchr`.
- Redis on port `6379` for task queue usage.

If you need to tear everything down (including volumes), run:

```bash
docker compose down -v
```

## 4. Configure environment variables

Export environment variables that the backend expects. The defaults line up with
`docker-compose.yml`, so you can simply create a `.env` file (or export them in
your shell):

```bash
export POSTGRES_USER=beatmatchr
export POSTGRES_PASSWORD=beatmatchr
export POSTGRES_DB=beatmatchr
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export REDIS_HOST=localhost
export REDIS_PORT=6379
export REDIS_DB=0
export CELERY_BROKER_URL=redis://localhost:6379/0
export CELERY_RESULT_BACKEND=redis://localhost:6379/0
```

Feel free to adjust these if you change the Docker Compose configuration.

## 5. Run database migrations / initialize tables

If you have Alembic migrations configured, apply them with:

```bash
alembic upgrade head
```

If migrations are not available yet, you can run your project-specific database
bootstrap script (for example `python -m backend.db init_db`) to create tables
manually. Ensure the `DATABASE_URL` environment variable is pointing at the
Postgres instance from the Docker Compose stack.

## 6. Start the FastAPI application

Launch the app with `uvicorn` (hot reload optional):

```bash
uvicorn backend.main:app --reload
```

The API will be available at <http://localhost:8000/>.

## 7. Start the Celery/RQ worker

For Celery, point to the Celery app defined in your project (replace the module
path if needed):

```bash
celery -A backend.worker.celery_app worker --loglevel=info
```

If you are using RQ instead of Celery, start a worker referencing the same Redis
instance:

```bash
rq worker beatmatchr --url redis://localhost:6379/0
```

## 8. Example API usage

Replace `PROJECT_ID` with the UUID returned from the *create project* call.

### Create a project

```bash
curl -X POST "http://localhost:8000/projects" \
  -H "Content-Type: application/json" \
  -d '{"name": "Demo Project", "description": "My first beatmatch"}'
```

### Upload audio to a project

```bash
curl -X POST "http://localhost:8000/projects/PROJECT_ID/audio" \
  -F "file=@/path/to/local/file.wav"
```

### Add a source clip by URL

```bash
curl -X POST "http://localhost:8000/projects/PROJECT_ID/sources" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/audio.mp3", "start": 0, "end": 30}'
```

### Fetch lyrics for a track

```bash
curl "http://localhost:8000/projects/PROJECT_ID/lyrics"
```

With the services running and environment variables configured, you should be
able to follow the steps above to interact with the beatmatchr backend locally.
