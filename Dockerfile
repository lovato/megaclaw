FROM mcr.microsoft.com/playwright:v1.41.0-jammy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard

WORKDIR /app

ENV OPENCLAW_GATEWAY_PORT=18789

CMD ["openclaw", "gateway", "--host", "0.0.0.0"]
