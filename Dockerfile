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
RUN poetry config system-git-client true

# avoid host verification issues
RUN mkdir -p -m 0700 /root/.ssh \
    && ssh-keyscan github.com >> /root/.ssh/known_hosts

COPY . .

ARG GITHUB_TOKEN

ARG GITHUB_TOKEN

RUN --mount=type=ssh \
    --mount=type=secret,id=github_token,required=false \
    set -e; \
    if [ -f /run/secrets/github_token ]; then \
        GITHUB_TOKEN=$(cat /run/secrets/github_token); \
        git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "ssh://git@github.com/"; \
        git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"; \
        echo "Using GitHub token authentication"; \
    else \
        echo "Using SSH authentication"; \
    fi; \
    poetry install --no-root --no-interaction --no-ansi