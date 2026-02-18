# syntax=docker/dockerfile:1.6

FROM python:3.13-slim

RUN apt-get update \
    && apt-get install -y curl git openssh-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pyproject.toml poetry.lock ./

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

RUN poetry config virtualenvs.create false

ENV POETRY_SYSTEM_GIT_CLIENT=true

# avoid host verification issues
RUN mkdir -p -m 0700 /root/.ssh \
    && ssh-keyscan github.com >> /root/.ssh/known_hosts

COPY . .

RUN --mount=type=ssh \
    --mount=type=secret,id=github_token \
    set -e; \
    if [ -f /run/secrets/github_token ]; then \
        GITHUB_TOKEN=$(cat /run/secrets/github_token); \
        git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "ssh://git@github.com/"; \
        git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"; \
        sed -i "s|ssh://git@github.com/|https://${GITHUB_TOKEN}@github.com/|g" poetry.lock; \
        sed -i "s|git@github.com:|https://${GITHUB_TOKEN}@github.com/|g" poetry.lock; \
        echo "Using GitHub token authentication"; \
    else \
        echo "Using SSH authentication"; \
    fi; \
    poetry install --no-root --no-interaction --no-ansi