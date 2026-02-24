FROM mcr.microsoft.com/playwright:v1.41.0-jammy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl build-essential procps file

RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ARG CACHE_BYPASS=latest
RUN echo "Installing OpenClaw at $CACHE_BYPASS"

RUN curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard

WORKDIR /root

ENV HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
ENV PATH=$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH

CMD ["openclaw", "gateway"]
