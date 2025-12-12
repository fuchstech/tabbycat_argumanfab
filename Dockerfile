# Docker file lists all the commands needed to setup a fresh linux instance to
# run the application specified. docker-compose does not use this.

# Use Python 3.9 for better performance and security
FROM python:3.9-slim

# Just needed for all things python (note this is setting an env variable)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    nginx \
    git \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Setup Node/NPM (use Node 16 LTS)
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
RUN mkdir /tcd
WORKDIR /tcd

# Set git to use HTTPS (SSH is often blocked by firewalls)
RUN git config --global url."https://".insteadOf git://

# Copy dependency files first for better layer caching
COPY package*.json ./
COPY config/requirements_docker.txt ./config/

# Install Node dependencies
RUN npm install -g npm@8 && \
    npm ci --only=production

# Install Python dependencies
RUN pip install --no-cache-dir -r ./config/requirements_docker.txt

# Copy application code
COPY . /tcd/

# Compile all the static files
RUN npm run build
RUN python ./tabbycat/manage.py collectstatic --noinput -v 0

# Create non-root user for security
RUN useradd -m -u 1000 tabbycat && \
    chown -R tabbycat:tabbycat /tcd
USER tabbycat

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1
