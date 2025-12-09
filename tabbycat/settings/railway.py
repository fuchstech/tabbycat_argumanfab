import logging
import os

import dj_database_url
import sentry_sdk
from sentry_sdk.integrations.logging import LoggingIntegration
from sentry_sdk.integrations.django import DjangoIntegration
from sentry_sdk.integrations.redis import RedisIntegration

from .core import TABBYCAT_VERSION

# ==============================================================================
# Railway Configuration
# ==============================================================================

# Store Tab Director Emails for reporting purposes
if os.environ.get('TAB_DIRECTOR_EMAIL', ''):
    TAB_DIRECTOR_EMAIL = os.environ.get('TAB_DIRECTOR_EMAIL')

if os.environ.get('DJANGO_SECRET_KEY', ''):
    SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')

# https://docs.djangoproject.com/en/3.0/ref/settings/#allowed-hosts
ALLOWED_HOSTS = ['*']

# Honor the 'X-Forwarded-Proto' header for request.is_secure()
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

RAILWAY_PUBLIC_DOMAIN = os.environ.get('RAILWAY_PUBLIC_DOMAIN')
if RAILWAY_PUBLIC_DOMAIN:
    ALLOWED_HOSTS.append(RAILWAY_PUBLIC_DOMAIN)

# ==============================================================================
# Postgres
# ==============================================================================

# Parse database configuration from $DATABASE_URL
DATABASES = {
    'default': dj_database_url.config(
        # Railway automatically provides DATABASE_URL
        default='postgresql://postgres:postgres@localhost:5432/mysite',
        conn_max_age=600
    )
}

# ==============================================================================
# Redis
# ==============================================================================

# Railway provides REDIS_URL in format: redis://host:port
REDIS_URL = os.environ.get('REDIS_URL', '')

if REDIS_URL:
    # Parse Redis URL
    import re
    redis_match = re.match(r'redis://([^:]+):(\d+)', REDIS_URL)
    if redis_match:
        REDIS_HOST = redis_match.group(1)
        REDIS_PORT = redis_match.group(2)
    else:
        # Fallback to individual variables
        REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
        REDIS_PORT = os.environ.get('REDIS_PORT', '6379')
else:
    REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
    REDIS_PORT = os.environ.get('REDIS_PORT', '6379')

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://" + REDIS_HOST + ":" + REDIS_PORT,
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
            "SOCKET_CONNECT_TIMEOUT": 5,
            "SOCKET_TIMEOUT": 60,
            "IGNORE_EXCEPTIONS": True,  # Don't crash on say ConnectionError due to limits
        },
    },
}

CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {
            "hosts": ["redis://" + REDIS_HOST + ":" + REDIS_PORT],
        },
    },
}

# ==============================================================================
# Sentry
# ==============================================================================

if not os.environ.get('DISABLE_SENTRY'):
    DISABLE_SENTRY = False
    sentry_sdk.init(
        dsn="https://6bf2099f349542f4b9baf73ca9789597@o85113.ingest.sentry.io/185382",
        integrations=[
            DjangoIntegration(),
            LoggingIntegration(event_level=logging.WARNING),
            RedisIntegration(),
        ],
        send_default_pii=True,
        release=TABBYCAT_VERSION,
    )
