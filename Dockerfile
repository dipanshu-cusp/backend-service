# syntax=docker/dockerfile:1.6

FROM python:3.13-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git openssh-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

RUN poetry config virtualenvs.create false

ENV POETRY_SYSTEM_GIT_CLIENT=true

# avoid host verification issues
RUN mkdir -p -m 0700 /root/.ssh \
    && ssh-keyscan github.com >> /root/.ssh/known_hosts

# install dependencies before copying source for better layer caching
COPY pyproject.toml poetry.lock ./

RUN --mount=type=ssh \
    --mount=type=secret,id=github_token \
    set -e; \
    cp poetry.lock poetry.lock.bak; \
    if [ -f /run/secrets/github_token ]; then \
        GITHUB_TOKEN=$(cat /run/secrets/github_token); \
        sed -i "s|ssh://git@github.com/|https://${GITHUB_TOKEN}@github.com/|g" poetry.lock; \
        sed -i "s|git@github.com:|https://${GITHUB_TOKEN}@github.com/|g" poetry.lock; \
        echo "Using GitHub token authentication"; \
    else \
        echo "Using SSH authentication"; \
    fi; \
    poetry install --no-root --no-interaction --no-ansi; \
    mv poetry.lock.bak poetry.lock

COPY . .