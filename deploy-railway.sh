#!/bin/bash
# Tabbycat Railway Deployment Script
# macOS/Linux için Railway deployment scripti

set -e

echo "=================================="
echo "Tabbycat Railway Deployment"
echo "=================================="
echo ""

# Railway CLI kontrolü
echo "1. Railway CLI kontrol ediliyor..."
if ! command -v railway &> /dev/null; then
    echo "Railway CLI bulunamadı. Yükleniyor..."
    curl -fsSL https://railway.app/install.sh | sh
    export PATH="$HOME/.railway/bin:$PATH"
fi

# Login kontrolü
echo "2. Railway login kontrol ediliyor..."
if ! railway whoami &> /dev/null; then
    echo "Railway'e login olmanız gerekiyor..."
    railway login
fi

# Proje kontrolü
echo "3. Railway projesi kontrol ediliyor..."
if ! railway status &> /dev/null; then
    echo "Railway projesi bulunamadı. Yeni proje oluşturuluyor..."
    railway init
fi

# PostgreSQL ekle
echo "4. PostgreSQL ekleniyor..."
echo "Railway dashboard'dan PostgreSQL plugin ekleyin:"
echo "https://railway.app/dashboard"
echo "Veya: railway add --plugin postgresql"
read -p "PostgreSQL eklendikten sonra Enter'a basın..."

# Redis ekle
echo "5. Redis ekleniyor..."
echo "Railway dashboard'dan Redis plugin ekleyin:"
echo "https://railway.app/dashboard"
echo "Veya: railway add --plugin redis"
read -p "Redis eklendikten sonra Enter'a basın..."

# Environment variables
echo "6. Environment variables ayarlanıyor..."

# Secret key oluştur
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
echo "DJANGO_SECRET_KEY oluşturuldu"

# Variables'ı ayarla
echo "Environment variables ayarlanıyor..."
railway variables set DJANGO_SECRET_KEY="$SECRET_KEY"
railway variables set DEBUG=0
railway variables set IN_DOCKER=1
railway variables set DOCKER_REDIS=1
railway variables set TIME_ZONE="Europe/Istanbul"

# Email al
read -p "Tab director email adresinizi girin: " EMAIL
railway variables set TAB_DIRECTOR_EMAIL="$EMAIL"

echo "Environment variables ayarlandı!"

# Deploy
echo "7. Deploy başlatılıyor..."
echo "Bu işlem 5-10 dakika sürebilir..."
railway up

echo ""
echo "=================================="
echo "Deployment tamamlandı!"
echo "=================================="
echo ""
echo "Railway dashboard: https://railway.app/dashboard"
echo ""
echo "Logs'u görmek için: railway logs"
echo "Domain görmek için: railway domain"
echo ""
