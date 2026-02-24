FROM mcr.microsoft.com/playwright:v1.41.0-jammy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl build-essential procps file && \
    curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard

RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

WORKDIR /app

CMD ["openclaw", "gateway"]
