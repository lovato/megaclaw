FROM mcr.microsoft.com/playwright:v1.41.0-jammy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pnpm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/openclaw/openclaw.git /app && \
    cd /app && \
    pnpm install && \
    pnpm build

WORKDIR /app

ENV OPENCLAW_GATEWAY_PORT=18789

CMD ["node", "dist/index.js", "gateway"]
