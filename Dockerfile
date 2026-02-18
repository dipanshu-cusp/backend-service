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

ARG GITHUB_TOKEN

RUN --mount=type=ssh \
    set -e; \
    if [ -n "${GITHUB_TOKEN}" ]; then \
        git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "ssh://git@github.com/"; \
        git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"; \
        echo "Using GitHub token authentication"; \
    else \
        echo "Using SSH authentication"; \
    fi; \
    poetry install --no-root --no-interaction --no-ansi