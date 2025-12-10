# Tabbycat Railway Deployment Rehberi

## Gerekli Adımlar

### 1. Railway Hesabı Oluştur
1. https://railway.app adresine git
2. GitHub hesabınla giriş yap
3. Email doğrulaması yap

### 2. Railway CLI Kurulumu

**Windows (PowerShell):**
```powershell
iwr https://railway.app/install.ps1 | iex
```

**macOS/Linux:**
```bash
curl -fsSL https://railway.app/install.sh | sh
```

### 3. Railway'e Login

```bash
railway login
```

Bu komut tarayıcıda bir pencere açacak, orada login yapın.

### 4. Yeni Proje Oluştur

```bash
# Railway projesini başlat
railway init

# Proje adı: tabbycat (veya istediğiniz bir ad)
```

### 5. PostgreSQL Ekle

```bash
# Railway dashboard'a git: https://railway.app/dashboard
# Veya CLI ile:
railway add --plugin postgresql
```

### 6. Redis Ekle

```bash
railway add --plugin redis
```

### 7. Environment Variables Ayarla

Railway dashboard'dan veya CLI ile:

```bash
# Gerekli environment variables
railway variables set DJANGO_SECRET_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(50))")
railway variables set DEBUG=0
railway variables set IN_DOCKER=1
railway variables set DOCKER_REDIS=1
railway variables set TIME_ZONE="Europe/Istanbul"
railway variables set TAB_DIRECTOR_EMAIL="your-email@example.com"

# PostgreSQL otomatik ayarlanır (DATABASE_URL)
# Redis otomatik ayarlanır (REDIS_URL)
```

### 8. Deploy Et

```bash
# İlk deployment
railway up

# Veya GitHub ile otomatik deployment için:
# Railway dashboard'da GitHub repo'nuzu bağlayın
```

### 9. Database Migration

Deploy sonrası database migration otomatik çalışacak (docker-run-honcho.sh içinde).
Ama manuel yapmak isterseniz:

```bash
railway run python tabbycat/manage.py migrate
```

### 10. Superuser Oluştur (Opsiyonel)

```bash
railway run python tabbycat/manage.py createsuperuser
```

### 11. Domain Ayarla

Railway otomatik bir domain verecek: `your-app.up.railway.app`

Özel domain için:
1. Railway dashboard'a git
2. Settings > Domains
3. Custom domain ekle

## Servisler

Railway'de 3 servis olacak:
- **Web Service**: Tabbycat web app (Dockerfile ile)
- **PostgreSQL**: Database
- **Redis**: Cache/Sessions

## Maliyetler

- **Free Tier**: İlk 500 saat/ay ($5 kredi) ÜCRETSİZ
- **Developer Plan**: $5/ay (sonrası kullanıma göre)
- **Starter Plan**: $20/ay (daha fazla kaynak)

Küçük bir turnuva için Free Tier yeterli olabilir.

## Monitoring

Railway dashboard'dan:
- Logs
- Metrics (CPU, Memory, Network)
- Deployment history
- Database backups

## Güncelleme

```bash
# Kod değişikliklerini push et
git add .
git commit -m "Update"
git push

# Railway otomatik deploy edecek (GitHub bağlıysa)
# Veya manuel:
railway up
```

## Sorun Giderme

### Logs'a Bakma
```bash
railway logs
```

### Shell Açma
```bash
railway shell
```

### Servis Restart
```bash
railway restart
```

## Önemli Notlar

1. **Python Version**: Dockerfile Python 3.6 kullanıyor. Daha yeni sürüm için Dockerfile'ı güncelleyin.
2. **Static Files**: Otomatik collectstatic build sırasında çalışıyor.
3. **Worker Process**: Background tasks için worker servisi de deploy edilmeli.
4. **Backups**: PostgreSQL için Railway otomatik backup alıyor.

## Worker Servisi (Opsiyonel)

Worker için ayrı bir servis oluşturun:

```bash
# Railway dashboard'da yeni servis ekle
# Start command:
./bin/docker-run-worker.sh
```

## Güvenlik

- `DEBUG=0` olduğundan emin olun
- `DJANGO_SECRET_KEY` mutlaka random olmalı
- `ALLOWED_HOSTS` ayarını kontrol edin

## Destek

Railway Discord: https://discord.gg/railway
Tabbycat Docs: https://tabbycat.readthedocs.io/
