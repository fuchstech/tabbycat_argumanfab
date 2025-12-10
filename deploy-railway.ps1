# Tabbycat Railway Deployment Script (PowerShell)
# Windows için Railway deployment scripti

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Tabbycat Railway Deployment" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Railway CLI kontrolü
Write-Host "1. Railway CLI kontrol ediliyor..." -ForegroundColor Yellow
if (!(Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Host "Railway CLI bulunamadı. Yükleniyor..." -ForegroundColor Red
    Write-Host "Aşağıdaki komutu çalıştırın:" -ForegroundColor Yellow
    Write-Host "iwr https://railway.app/install.ps1 | iex" -ForegroundColor Green
    Write-Host ""
    Read-Host "Railway CLI yüklendikten sonra Enter'a basın"
}

# Login kontrolü
Write-Host "2. Railway login kontrol ediliyor..." -ForegroundColor Yellow
$loginCheck = railway whoami 2>&1
if ($loginCheck -like "*not logged in*" -or $LASTEXITCODE -ne 0) {
    Write-Host "Railway'e login olmanız gerekiyor..." -ForegroundColor Red
    railway login
}

# Proje kontrolü
Write-Host "3. Railway projesi kontrol ediliyor..." -ForegroundColor Yellow
$projectCheck = railway status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Railway projesi bulunamadı. Yeni proje oluşturuluyor..." -ForegroundColor Yellow
    railway init
}

# PostgreSQL ekle
Write-Host "4. PostgreSQL ekleniyor..." -ForegroundColor Yellow
Write-Host "Railway dashboard'dan PostgreSQL plugin ekleyin:" -ForegroundColor Green
Write-Host "https://railway.app/dashboard" -ForegroundColor Cyan
Write-Host "Veya: railway add --plugin postgresql" -ForegroundColor Green
Read-Host "PostgreSQL eklendikten sonra Enter'a basın"

# Redis ekle
Write-Host "5. Redis ekleniyor..." -ForegroundColor Yellow
Write-Host "Railway dashboard'dan Redis plugin ekleyin:" -ForegroundColor Green
Write-Host "https://railway.app/dashboard" -ForegroundColor Cyan
Write-Host "Veya: railway add --plugin redis" -ForegroundColor Green
Read-Host "Redis eklendikten sonra Enter'a basın"

# Environment variables
Write-Host "6. Environment variables ayarlanıyor..." -ForegroundColor Yellow

# Secret key oluştur
$secretKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 50 | ForEach-Object {[char]$_})
Write-Host "DJANGO_SECRET_KEY oluşturuldu" -ForegroundColor Green

# Variables'ı ayarla
Write-Host "Environment variables ayarlanıyor..." -ForegroundColor Yellow
railway variables set DJANGO_SECRET_KEY=$secretKey
railway variables set DEBUG=0
railway variables set IN_DOCKER=1
railway variables set DOCKER_REDIS=1
railway variables set TIME_ZONE="Europe/Istanbul"

# Email al
$email = Read-Host "Tab director email adresinizi girin"
railway variables set TAB_DIRECTOR_EMAIL=$email

Write-Host "Environment variables ayarlandı!" -ForegroundColor Green

# Deploy
Write-Host "7. Deploy başlatılıyor..." -ForegroundColor Yellow
Write-Host "Bu işlem 5-10 dakika sürebilir..." -ForegroundColor Yellow
railway up

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Deployment tamamlandı!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Railway dashboard: https://railway.app/dashboard" -ForegroundColor Cyan
Write-Host ""
Write-Host "Logs'u görmek için: railway logs" -ForegroundColor Yellow
Write-Host "Domain görmek için: railway domain" -ForegroundColor Yellow
Write-Host ""
