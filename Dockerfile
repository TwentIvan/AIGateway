# AIGateway — LiteLLM proxy con il config versionato in questo repo.
# Build su GitHub Actions → ghcr.io/twentivan/aigateway → Coolify (porta 4000).
FROM ghcr.io/berriai/litellm:main-stable
COPY config.yaml /app/config.yaml
EXPOSE 4000
CMD ["--config", "/app/config.yaml", "--port", "4000", "--host", "0.0.0.0"]
