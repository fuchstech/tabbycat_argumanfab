# Docker file lists all the commands needed to setup a fresh linux instance to
# run the application specified. docker-compose does not use this.

# Grab a python image (updated to 3.8 for better compatibility)
FROM python:3.8

# Just needed for all things python (note this is setting an env variable)
ENV PYTHONUNBUFFERED 1

# Setup Node/NPM
RUN apt-get update && apt-get install -y \
    curl \
    nginx \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get update && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

# Copy all our files into the baseimage and cd to that directory
RUN mkdir /tcd
WORKDIR /tcd

# Copy dependency files first for better caching
COPY requirements.txt ./
COPY config/requirements_*.txt ./config/
COPY package*.json ./

# Set git to use HTTPS (SSH is often blocked by firewalls)
RUN git config --global url."https://".insteadOf git://

# Install our node/python requirements
# Using Node.js 16 for compatibility with node-sass 5.x
RUN pip install --no-cache-dir -r ./config/requirements_docker.txt
RUN npm install --only=production

# Copy the rest of the application
COPY . /tcd/

# Compile all the static files
RUN npm run build
RUN python ./tabbycat/manage.py collectstatic --noinput -v 0

# Expose port
EXPOSE 8000

# Start command for Sliplane (using gunicorn + daphne via honcho)
CMD ["honcho", "-f", "ProcfileMulti", "start"]
