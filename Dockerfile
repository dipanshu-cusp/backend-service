# syntax=docker/dockerfile:1.6

FROM python:3.13-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

RUN poetry config virtualenvs.create false

ENV POETRY_SYSTEM_GIT_CLIENT=true

# install dependencies before copying source for better layer caching
COPY pyproject.toml poetry.lock ./

RUN --mount=type=secret,id=GCP_TOKEN \
    set -e; \
    if [ -f /run/secrets/GCP_TOKEN ]; then \
        GCP_TOKEN=$(cat /run/secrets/GCP_TOKEN); \
        poetry config http-basic.gcp-repo oauth2accesstoken "${GCP_TOKEN}"; \
        echo "Using GCP Artifact Registry token authentication"; \
    else \
        echo "Missing GCP token secret at /run/secrets/GCP_TOKEN"; \
        exit 1; \
    fi; \
    poetry install --no-root --no-interaction --no-ansi; \
    poetry config --unset http-basic.gcp-repo

COPY . .