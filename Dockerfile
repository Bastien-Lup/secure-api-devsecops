FROM python:3.13-slim-trixie@sha256:16f75ad0fbc6c4883a8afd63b2d700c3cf68ccffc1aaeca5304ca0a3a908451f AS builder

WORKDIR /build

COPY requirements.txt .

RUN python -m pip install \
    --no-cache-dir \
    --disable-pip-version-check \
    --target=/opt/python \
    -r requirements.txt


FROM gcr.io/distroless/python3-debian13:nonroot@sha256:2da46b943456ad2544a03426474f593aacb6af587c64fa3229c7b16987bb30e2 AS runtime

ENV PYTHONPATH=/opt/python \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY --from=builder --chown=65532:65532 /opt/python /opt/python
COPY --chown=65532:65532 app/ ./app/

USER 65532:65532

EXPOSE 8000

HEALTHCHECK \
    --interval=30s \
    --timeout=3s \
    --start-period=5s \
    --retries=3 \
    CMD ["/usr/bin/python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).read()"]

ENTRYPOINT ["/usr/bin/python"]

CMD ["-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]