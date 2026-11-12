FROM python:3.12.12-slim
COPY --from=ghcr.io/astral-sh/uv:0.13.7 /uv /bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
COPY main.py config.py ./
ARG APP_VERSION=1.0.0
ENV APP_VERSION=$APP_VERSION PATH="/app/.venv/bin:$PATH"
RUN useradd --uid 10001 --create-home app
USER app
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
