import logging
from os import environ

import dj_database_url
import sentry_sdk
from sentry_sdk.integrations.logging import LoggingIntegration
from sentry_sdk.integrations.django import DjangoIntegration
from sentry_sdk.integrations.redis import RedisIntegration

from .core import TABBYCAT_VERSION


# ==============================================================================
# DigitalOcean App Platform
# ==============================================================================

# Store Tab Director Emails for reporting purposes
if 'TAB_DIRECTOR_EMAIL' in environ:
    TAB_DIRECTOR_EMAIL = environ.get('TAB_DIRECTOR_EMAIL', '')

# Get key from environment
if environ.get('DJANGO_SECRET_KEY'):
    SECRET_KEY = environ.get('DJANGO_SECRET_KEY')

# Allow configured hosts
ALLOWED_HOSTS = environ.get('ALLOWED_HOSTS', '*').split(',')

# Honor the 'X-Forwarded-Proto' header for request.is_secure()
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Require HTTPS in production
if 'DJANGO_SECRET_KEY' in environ and environ.get('DISABLE_HTTPS_REDIRECTS', '') != 'disable':
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

# ==============================================================================
# Postgres
# ==============================================================================

# Parse database configuration from $DATABASE_URL
DATABASES = {
    'default': dj_database_url.config(
        default='postgres://localhost',
        conn_max_age=600,
        ssl_require=True
    ),
}

# ==============================================================================
# Redis
# ==============================================================================

# DigitalOcean provides REDIS_URL from the redis service
REDIS_URL = environ.get('REDIS_URL', 'redis://redis:6379/1')

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": REDIS_URL,
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
            "SOCKET_CONNECT_TIMEOUT": 5,
            "SOCKET_TIMEOUT": 60,
        },
    },
}

CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {
            "hosts": [REDIS_URL],
            # Remove channels from groups after 3 hours
            # This matches websocket_timeout in Daphne
            "group_expiry": 10800,
        },
    },
}

# ==============================================================================
# Email Configuration
# ==============================================================================

if environ.get('EMAIL_HOST', ''):
    SERVER_EMAIL = environ.get('DEFAULT_FROM_EMAIL', 'noreply@tabbycat.app')
    DEFAULT_FROM_EMAIL = environ.get('DEFAULT_FROM_EMAIL', 'noreply@tabbycat.app')
    EMAIL_HOST = environ['EMAIL_HOST']
    EMAIL_HOST_USER = environ.get('EMAIL_HOST_USER', '')
    EMAIL_HOST_PASSWORD = environ.get('EMAIL_HOST_PASSWORD', '')
    EMAIL_PORT = int(environ.get('EMAIL_PORT', 587))
    EMAIL_USE_TLS = environ.get('EMAIL_USE_TLS', 'True').lower() in ('true', '1', 'yes')

# ==============================================================================
# Sentry Error Tracking
# ==============================================================================

if not environ.get('DISABLE_SENTRY'):
    DISABLE_SENTRY = False
    sentry_dsn = environ.get('SENTRY_DSN', 'https://6bf2099f349542f4b9baf73ca9789597@o85113.ingest.sentry.io/185382')
    sentry_sdk.init(
        dsn=sentry_dsn,
        integrations=[
            DjangoIntegration(),
            LoggingIntegration(event_level=logging.WARNING),
            RedisIntegration(),
        ],
        send_default_pii=True,
        release=TABBYCAT_VERSION,
        environment='digitalocean-production',
    )

# ==============================================================================
# Logging
# ==============================================================================

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': environ.get('DJANGO_LOG_LEVEL', 'INFO'),
            'propagate': False,
        },
    },
}

# ==============================================================================
# Static Files
# ==============================================================================

# If using a CDN, set STATIC_URL in environment
if environ.get('STATIC_URL'):
    STATIC_URL = environ.get('STATIC_URL')
