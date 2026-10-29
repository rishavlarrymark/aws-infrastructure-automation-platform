# Keep your Dockerfile exactly as it is for now. Do not add, remove, or modify any instructions.

# It already defines your Python runtime, dependencies, application source, non-root user, port, and startup command for your Task Management API.

# You do not need to rebuild the Docker image as long as you haven't changed your Dockerfile, application code, or dependencies.

FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install application dependencies first for better build caching.
COPY requirements.txt .

RUN python -m pip install --upgrade pip \
    && python -m pip install -r requirements.txt

# Copy application source, not local secrets or virtual environments.
COPY app/ ./app/

# Run as a non-root user.
RUN useradd --create-home --uid 10001 appuser \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]