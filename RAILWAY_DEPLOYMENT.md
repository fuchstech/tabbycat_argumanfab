# Railway Deployment Talimatları

Bu belge, Tabbycat projesini Railway platformuna deploy etmek için gerekli adımları içerir.

## Ön Koşullar

1. [Railway hesabı](https://railway.app/) oluşturun
2. GitHub hesabınızı Railway'e bağlayın
3. Projeyi GitHub'a push edin

## Railway'de Proje Oluşturma

### Adım 1: Yeni Proje Oluştur

1. Railway dashboard'una gidin: https://railway.app/dashboard
2. "New Project" butonuna tıklayın
3. "Deploy from GitHub repo" seçeneğini seçin
4. Repository'nizi seçin (tabbycat_argumanfab)
5. Branch'i seçin (örn: `crazy-hamilton` veya `develop`)

### Adım 2: PostgreSQL Ekle

1. Proje sayfasında "New" butonuna tıklayın
2. "Database" → "Add PostgreSQL" seçin
3. PostgreSQL otomatik olarak oluşturulacak
4. Railway otomatik olarak `DATABASE_URL` environment variable'ını ekleyecek

### Adım 3: Redis Ekle

1. Proje sayfasında "New" butonuna tıklayın
2. "Database" → "Add Redis" seçin
3. Redis otomatik olarak oluşturulacak
4. Railway otomatik olarak `REDIS_URL` environment variable'ını ekleyecek

### Adım 4: Environment Variables Ayarla

Ana servisinize (web servisi) aşağıdaki environment variable'ları ekleyin:

#### Gerekli Variables:

```bash
RAILWAY_ENVIRONMENT=production
DJANGO_SECRET_KEY=<rastgele-güvenli-key-buraya>
TAB_DIRECTOR_EMAIL=your-email@example.com
TIME_ZONE=Europe/Istanbul
PYTHON_VERSION=3.11
WEB_CONCURRENCY=4
USING_NGINX=0
```

#### Django Secret Key Oluşturma:

Python ile rastgele bir secret key oluşturun:

```python
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
```

Veya online bir generator kullanın: https://djecrety.ir/

#### Opsiyonel Variables:

```bash
# Sentry'yi devre dışı bırakmak isterseniz:
DISABLE_SENTRY=true

# Debug mode (SADECE test için, production'da KULLANMAYIN):
DEBUG=false
```

### Adım 5: Worker Servisi Ekle (Opsiyonel ama Önerilen)

Background worker'lar için ayrı bir servis oluşturun:

1. Proje sayfasında "New" butonuna tıklayın
2. "Empty Service" seçin
3. Aynı GitHub repository'sini seçin
4. Settings'e gidin ve:
   - **Custom Start Command**: `python manage.py runworker notifications adjallocation venues`
   - Aynı environment variable'ları ekleyin (yukarıdaki adım 4'teki gibi)

### Adım 6: Build ve Deploy Ayarları

Railway otomatik olarak `railway.json` dosyasını algılayacak ve kullanacaktır.

**Build Command**: `./bin/railway-compile.sh`
**Start Command**: `npm run railway-serve`

Bu ayarlar `railway.json` dosyasında tanımlıdır.

### Adım 7: Deploy

1. Railway otomatik olarak deploy işlemini başlatacak
2. Build loglarını izleyin
3. Herhangi bir hata varsa, environment variable'ları kontrol edin

### Adım 8: İlk Kurulum

Deploy başarılı olduktan sonra, Railway CLI veya web terminal ile:

```bash
# Süper kullanıcı oluştur
python tabbycat/manage.py createsuperuser

# Örnek turnuva verileri yükle (opsiyonel)
python tabbycat/manage.py importtournament data/minimal8team
```

## Veritabanı Yönetimi

### Backup Alma

Railway dashboard'undan PostgreSQL servisine girin ve "Backups" sekmesinden backup alabilirsiniz.

### Migration Çalıştırma

Railway CLI ile:

```bash
railway run python tabbycat/manage.py migrate
```

Veya web servisinin Settings → Deploy → "Add Custom Build Command" kısmında otomatik çalıştırılır (zaten `railway-compile.sh` içinde var).

## Maliyet Optimizasyonu

Railway kullanım bazlı ücretlendirme yapar. Maliyeti düşürmek için:

1. **Sleep Mode**: Servisler 10 dakika trafik almadığında otomatik olarak uyur
2. **Resource Limits**: Settings'den CPU ve Memory limitlerini ayarlayın
3. **Monitoring**: Dashboard'dan kullanımı izleyin

### Tahmini Maliyetler (Aylık):

- **Web Service** (512MB RAM, düşük trafik): ~$3-5
- **Worker Service** (256MB RAM): ~$2-3
- **PostgreSQL** (256MB): ~$2
- **Redis** (128MB): ~$1

**Toplam: ~$8-11/ay** (düşük-orta trafik için)

## Troubleshooting

### Build Başarısız Oluyor

1. Build loglarını kontrol edin
2. Python versiyonunu kontrol edin (`PYTHON_VERSION=3.11`)
3. `railway-compile.sh` script'inin executable olduğundan emin olun

### Redis Bağlantı Hatası

1. `REDIS_URL` environment variable'ının doğru set edildiğini kontrol edin
2. Redis servisinin çalıştığını kontrol edin
3. Railway'de servisler arasında network bağlantısının olduğunu doğrulayın

### Static Files Yüklenmiyor

1. `collectstatic` komutunun build sırasında çalıştığını kontrol edin
2. `USING_NGINX=0` olarak ayarlandığından emin olun

### WebSocket Bağlantıları Çalışmıyor

1. Railway WebSocket'leri destekler ama custom domain kullanıyorsanız SSL ayarlarını kontrol edin
2. Channel layers için Redis'in düzgün çalıştığından emin olun

## Domain Bağlama

1. Railway dashboard'dan servisinize gidin
2. "Settings" → "Networking" → "Generate Domain" veya "Custom Domain" ekleyin
3. Custom domain için DNS ayarlarını yapın (Railway size CNAME kaydı verecek)

## Güvenlik Önerileri

1. ✅ `DEBUG=false` olarak ayarlayın (production'da)
2. ✅ Güçlü bir `DJANGO_SECRET_KEY` kullanın
3. ✅ Düzenli olarak backup alın
4. ✅ `ALLOWED_HOSTS` ayarını kontrol edin (railway.py'de otomatik yapılıyor)
5. ✅ SSL/TLS otomatik olarak Railway tarafından sağlanır

## Daha Fazla Bilgi

- [Railway Documentation](https://docs.railway.app/)
- [Railway Discord](https://discord.gg/railway)
- [Tabbycat Documentation](https://tabbycat.readthedocs.io/)

## Destek

Sorun yaşarsanız:
- Railway Community: https://discord.gg/railway
- Tabbycat GitHub Issues: https://github.com/TabbycatDebate/tabbycat/issues
