# Base image with Playwright and browsers preinstalled
FROM mcr.microsoft.com/playwright:v1.41.0-jammy

# Avoid Python buffering issues
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# Create non-root user
RUN useradd -m -u 10001 openclaw

WORKDIR /app

# Install Python
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency file first for layer caching
COPY requirements.txt .

# Install dependencies
RUN pip3 install --upgrade pip && \
    pip3 install -r requirements.txt

# Copy application code
COPY app/ /app/

# Create runtime folders
RUN mkdir -p /data /config && \
    chown -R openclaw:openclaw /app /data /config

USER openclaw

# Default environment (override in docker run if needed)
ENV LMSTUDIO_URL=http://host.docker.internal:1234/v1
ENV OPENCLAW_DATA_DIR=/data
ENV OPENCLAW_CONFIG_DIR=/config

CMD ["python3", "main.py"]
