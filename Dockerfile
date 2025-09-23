FROM python:3.13.7-slim-bookworm

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=from=ghcr.io/astral-sh/uv,source=/uv,target=/bin/uv \
    uv sync --locked --compile-bytecode --no-editable --no-dev

COPY . /app

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.9.1 /lambda-adapter /opt/extensions/lambda-adapter

CMD ["/app/.venv/bin/uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]