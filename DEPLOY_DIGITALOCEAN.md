# DigitalOcean Deployment Guide - Tabbycat

Bu dokümantasyon Tabbycat projesini DigitalOcean App Platform üzerinde deploy etmek için adım adım talimatlar içerir.

## İçindekiler

1. [Gereksinimler](#gereksinimler)
2. [Deployment Yöntemleri](#deployment-yöntemleri)
3. [Hızlı Başlangıç](#hızlı-başlangıç)
4. [Detaylı Kurulum](#detaylı-kurulum)
5. [Ortam Değişkenleri](#ortam-değişkenleri)
6. [Veritabanı Yapılandırması](#veritabanı-yapılandırması)
7. [Sorun Giderme](#sorun-giderme)

## Gereksinimler

- DigitalOcean hesabı
- GitHub hesabı (otomatik deploy için)
- Git yüklü
- doctl CLI (opsiyonel, komut satırı deployment için)

## Deployment Yöntemleri

### Yöntem 1: DigitalOcean App Platform (Önerilen)

DigitalOcean App Platform, GitHub repository'nizi otomatik olarak deploy eder ve yönetir.

#### Avantajlar:
- Otomatik build ve deployment
- Zero-downtime deployments
- Otomatik SSL sertifikaları
- Kolay ölçeklendirme
- Entegre veritabanı ve Redis

### Yöntem 2: Docker ile Manuel Deployment

Kendi Droplet'ınızda Docker kullanarak manuel deployment.

## Hızlı Başlangıç

### App Platform ile Deployment

1. **GitHub Repository'yi Hazırlayın**

```bash
# Repository'yi fork edin veya kendi repository'nize push edin
git remote add origin https://github.com/KULLANICI_ADINIZ/tabbycat.git
git push -u origin main
```

2. **DigitalOcean App Platform'da Uygulama Oluşturun**

   - [DigitalOcean Console](https://cloud.digitalocean.com/apps) üzerinden yeni bir App oluşturun
   - GitHub repository'nizi seçin
   - "Edit Plan" yapın ve spec file'ı kullanın

3. **App Spec File'ı Kullanın**

`.do/app.yaml` dosyasını düzenleyin:

```yaml
# .do/app.yaml içinde aşağıdaki satırları güncelleyin:
github:
  repo: GITHUB_KULLANICI_ADINIZ/tabbycat
  branch: main
```

4. **Environment Variables'ı Ayarlayın**

DigitalOcean Console'da App Settings > Environment Variables:

```
DJANGO_SECRET_KEY=<güçlü-bir-secret-key-üretin>
ALLOWED_HOSTS=${APP_DOMAIN}
DEBUG=0
```

5. **Deploy Edin**

App Platform otomatik olarak build ve deploy işlemini başlatacaktır.

## Detaylı Kurulum

### Adım 1: Projeyi Hazırlayın

```bash
# Repository'yi klonlayın
git clone https://github.com/SIZIN_KULLANICI_ADINIZ/tabbycat.git
cd tabbycat

# Yeni branch oluşturun (opsiyonel)
git checkout -b production
```

### Adım 2: App Platform Spec File'ı Düzenleyin

`.do/app.yaml` dosyasını açın ve şunları güncelleyin:

1. `github.repo`: GitHub kullanıcı adınız ve repository adı
2. `region`: Tercih ettiğiniz bölge (fra, nyc, sfo, sgp vb.)
3. `instance_size_slug`: İhtiyacınıza göre instance boyutu

### Adım 3: DigitalOcean CLI ile Deploy (Opsiyonel)

```bash
# doctl CLI'yi yükleyin
# macOS
brew install doctl

# Linux
snap install doctl

# Windows
# https://docs.digitalocean.com/reference/doctl/how-to/install/ adresinden indirin

# DigitalOcean'a giriş yapın
doctl auth init

# App'i oluşturun
doctl apps create --spec .do/app.yaml

# App ID'yi alın
doctl apps list

# Deployment durumunu kontrol edin
doctl apps get <APP_ID>
```

### Adım 4: Veritabanı Oluşturun

DigitalOcean Console'da:

1. **Databases** > **Create Database**
2. PostgreSQL 14 seçin
3. Aynı bölgeyi seçin (maliyet optimizasyonu için)
4. Plan seçin (Development için Basic, Production için Production)
5. Database adını `tabbycat-db` olarak belirleyin

### Adım 5: Environment Variables'ı Yapılandırın

`.env.production.example` dosyasını referans alarak gerekli değişkenleri ayarlayın:

```bash
# Django Secret Key oluşturun
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

DigitalOcean App Settings'de şu değişkenleri ekleyin:

```
# Zorunlu
DJANGO_SECRET_KEY=<yukarıda-ürettiğiniz-key>
DATABASE_URL=${tabbycat-db.DATABASE_URL}
REDIS_URL=${redis.PRIVATE_URL}

# Önerilen
ALLOWED_HOSTS=${APP_DOMAIN},yourdomain.com
DEBUG=0
IN_DOCKER=1
DOCKER_REDIS=1

# Opsiyonel - Email
EMAIL_HOST=smtp.sendgrid.net
EMAIL_HOST_USER=apikey
EMAIL_HOST_PASSWORD=<sendgrid-api-key>
EMAIL_USE_TLS=True
DEFAULT_FROM_EMAIL=noreply@yourdomain.com

# Opsiyonel - Sentry
DISABLE_SENTRY=1  # Veya kendi Sentry DSN'inizi kullanın
```

### Adım 6: Django Settings'i Yapılandırın

`tabbycat/settings/__init__.py` dosyasını kontrol edin ve DigitalOcean için ayarları ekleyin:

```python
# tabbycat/settings/__init__.py
import os

# Önce çevre değişkenini kontrol et
if 'DIGITALOCEAN_APP_URL' in os.environ or 'APP_URL' in os.environ:
    from .digitalocean import *
elif 'IN_DOCKER' in os.environ:
    from .docker import *
elif 'DYNO' in os.environ:
    from .heroku import *
else:
    from .local import *
```

### Adım 7: İlk Deploy

```bash
# Değişiklikleri commit edin
git add .
git commit -m "Configure for DigitalOcean deployment"
git push origin main
```

DigitalOcean otomatik olarak build ve deploy işlemini başlatacaktır.

### Adım 8: İlk Kullanıcıyı Oluşturun

Deploy tamamlandıktan sonra:

```bash
# App Console > Console sekmesinden
python tabbycat/manage.py createsuperuser

# Veya doctl ile
doctl apps run <APP_ID> --component web -- python tabbycat/manage.py createsuperuser
```

## Ortam Değişkenleri

### Zorunlu Değişkenler

| Değişken | Açıklama | Örnek |
|----------|----------|-------|
| `DJANGO_SECRET_KEY` | Django güvenlik anahtarı | `django-insecure-...` |
| `DATABASE_URL` | PostgreSQL bağlantı URL'i | `postgres://user:pass@host:port/db` |
| `REDIS_URL` | Redis bağlantı URL'i | `redis://host:port/db` |

### Önerilen Değişkenler

| Değişken | Açıklama | Örnek |
|----------|----------|-------|
| `ALLOWED_HOSTS` | İzin verilen host'lar | `app.ondigitalocean.app,example.com` |
| `DEBUG` | Debug modu (production'da 0) | `0` |
| `TIME_ZONE` | Zaman dilimi | `Europe/Istanbul` |

### Opsiyonel Değişkenler

| Değişken | Açıklama | Örnek |
|----------|----------|-------|
| `EMAIL_HOST` | SMTP sunucusu | `smtp.sendgrid.net` |
| `EMAIL_HOST_USER` | SMTP kullanıcı adı | `apikey` |
| `EMAIL_HOST_PASSWORD` | SMTP şifresi | `SG.xxx` |
| `SENTRY_DSN` | Sentry error tracking | `https://xxx@sentry.io/xxx` |
| `TAB_DIRECTOR_EMAIL` | Tab direktörü e-posta | `director@example.com` |

## Veritabanı Yapılandırması

### PostgreSQL Connection Pooling

DigitalOcean'da connection pooling için PgBouncer kullanın:

1. Database > Connection Pools
2. Pool oluşturun (Mode: Transaction)
3. Pool size: 25-50 arası
4. `DATABASE_URL`'i pool connection string ile güncelleyin

### Backup Ayarları

1. Database > Settings > Backups
2. Daily backups'ı etkinleştirin
3. Retention period: 7-30 gün

### Database Migrations

Migrations otomatik olarak pre-deploy job ile çalışır:

```bash
# Manuel migration gerekirse
doctl apps run <APP_ID> --component migrate -- python tabbycat/manage.py migrate
```

## Ölçeklendirme

### Horizontal Scaling

```bash
# Web instance sayısını artırın
# .do/app.yaml içinde
services:
  - name: web
    instance_count: 3  # 1'den 3'e çıkarın
```

### Vertical Scaling

Instance boyutunu değiştirin:

```bash
# .do/app.yaml içinde
services:
  - name: web
    instance_size_slug: professional-xs  # basic-xs'den upgrade
```

## Monitoring ve Logs

### Log'ları Görüntüleme

```bash
# Web interface
# App > Runtime Logs

# CLI ile
doctl apps logs <APP_ID> --type run --follow
```

### Metrics

DigitalOcean Console > App > Insights:
- CPU kullanımı
- Memory kullanımı
- Request count
- Response time

## Custom Domain

1. **Domain Ekleyin**

   App Settings > Domains > Add Domain

2. **DNS Ayarları**

   Domain sağlayıcınızda CNAME kaydı ekleyin:
   ```
   CNAME @ your-app.ondigitalocean.app
   ```

3. **SSL Sertifikası**

   Otomatik olarak Let's Encrypt sertifikası oluşturulur.

## Sorun Giderme

### Build Hataları

```bash
# Log'ları kontrol edin
doctl apps logs <APP_ID> --type build

# Node/npm versiyonu kontrolü
# Dockerfile'da Node versiyon güncellemesi yapın
```

### Database Bağlantı Hataları

```bash
# DATABASE_URL'in doğru olduğunu kontrol edin
echo $DATABASE_URL

# PostgreSQL'in çalıştığını kontrol edin
doctl databases list

# Connection pool kullanın
```

### Redis Bağlantı Hataları

```bash
# REDIS_URL'in doğru olduğunu kontrol edin
# App içinde Redis service'in çalıştığını doğrulayın
```

### Static Files Sorunları

```bash
# collectstatic komutunu manuel çalıştırın
doctl apps run <APP_ID> --component web -- python tabbycat/manage.py collectstatic --noinput
```

### Migration Sorunları

```bash
# Migration durumunu kontrol edin
doctl apps run <APP_ID> --component web -- python tabbycat/manage.py showmigrations

# Manuel migration
doctl apps run <APP_ID> --component web -- python tabbycat/manage.py migrate --noinput
```

### 502 Bad Gateway

- Health check ayarlarını kontrol edin
- Application'ın 8000 portunda çalıştığını doğrulayın
- Log'larda application crash kontrolü yapın

### Yavaş Performance

- Instance boyutunu artırın
- Redis cache'i etkinleştirin
- Connection pooling kullanın
- CDN ekleyin (static files için)

## Güvenlik Önerileri

1. **Secret Key**: Güçlü ve unique bir secret key kullanın
2. **HTTPS**: SECURE_SSL_REDIRECT=True olmalı
3. **ALLOWED_HOSTS**: Sadece gerçek domain'lerinizi ekleyin
4. **Database**: Strong password ve restricted access
5. **Environment Variables**: Asla git'e commit etmeyin
6. **Regular Updates**: Dependencies'i düzenli güncelleyin

## Yedekleme ve Recovery

### Database Backup

```bash
# Manuel backup oluştur
doctl databases backup <DATABASE_ID>

# Backup'ları listele
doctl databases backup list <DATABASE_ID>

# Backup'tan restore
doctl databases restore <DATABASE_ID> <BACKUP_ID>
```

### Application Backup

```bash
# Git üzerinden version control
git tag -a v1.0.0 -m "Production release v1.0.0"
git push origin v1.0.0

# Rollback için
git checkout v1.0.0
git push origin main
```

## Maliyet Optimizasyonu

1. **Instance Sizing**: İhtiyacınız kadar kaynak kullanın
2. **Auto-scaling**: Traffic'e göre otomatik ölçeklendirme
3. **Database**: Development için Basic plan yeterli
4. **Region**: Kullanıcılarınıza yakın region seçin
5. **Reserved Instances**: Uzun vadeli kullanım için indirim

## İletişim ve Destek

- **Tabbycat Dokümantasyonu**: https://tabbycat.readthedocs.io/
- **DigitalOcean Dokümantasyonu**: https://docs.digitalocean.com/
- **GitHub Issues**: Repository'nizde issue açın
- **DigitalOcean Support**: Enterprise plan ile 24/7 destek

## Sonraki Adımlar

1. Custom domain ekleyin
2. Email servisi yapılandırın (SendGrid, Mailgun)
3. Monitoring ekleyin (Sentry, DataDog)
4. CDN ekleyin (DigitalOcean Spaces + CDN)
5. Backup stratejisi oluşturun
6. CI/CD pipeline kurun (GitHub Actions)

## Faydalı Komutlar

```bash
# App durumunu kontrol et
doctl apps get <APP_ID>

# Yeniden deploy et
doctl apps create-deployment <APP_ID>

# Environment variables'ı listele
doctl apps spec get <APP_ID>

# Console'a bağlan
doctl apps run <APP_ID> --component web -- /bin/bash

# Database'e bağlan
doctl databases connect <DATABASE_ID>

# Redis'e bağlan
redis-cli -u $REDIS_URL
```

## License

Bu deployment guide Tabbycat projesinin bir parçasıdır ve aynı lisans altındadır.
