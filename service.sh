#!/system/bin/sh
#!/system/bin/sh

# Log dosyası yolu
LOG_FILE="/data/local/tmp/simfix_debug.log"
# Son kaydedilen günün tutulacağı dosya
LAST_LOG_DAY_FILE="/data/local/tmp/simfix_last_log_day"

# Mevcut günü al
CURRENT_DAY=$(date '+%Y%m%d')

# Son kaydedilen günü oku
if [ -f "$LAST_LOG_DAY_FILE" ]; then
  LAST_LOG_DAY=$(cat "$LAST_LOG_DAY_FILE")
else
  LAST_LOG_DAY=""
fi

# Eğer gün değiştiyse veya dosya yoksa, log dosyasını temizle
if [ "$CURRENT_DAY" != "$LAST_LOG_DAY" ]; then
  echo "" > "$LOG_FILE" # Log dosyasını boşalt
  echo "$CURRENT_DAY" > "$LAST_LOG_DAY_FILE" # Yeni günü kaydet
fi

# Loglama yönlendirmesi (bu kısım eski betikteki ile aynı)
exec > "$LOG_FILE" 2>&1

# Hata ayıklama için her komutu loga yazdırır. İstemediğinizde kaldırabilirsiniz.
set -x

{
  echo ""
  echo "================================================="
  echo "== SIM BUG FIXER vORANGE by @oliplusmzr (service.sh)=="
  echo "== $(date '+%Y-%m-%d %H:%M:%S') =="
  echo "================================================="
} &

(
  echo "$(date '+%Y-%m-%d %H:%M:%S') - service.sh başlatıldı. Önyükleme tamamlanmasını bekliyor..."

  # sys.boot_completed zaten Magisk'in service.sh'i başlatmadan önce beklenir,
  # ancak ek bir güvenlik katmanı olarak bırakılabilir veya kaldırılabilir.
  # Bu kısım genellikle service.sh için gerekli değildir.
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
  done
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Önyükleme tamamlandı. Başlangıç SIM sıfırlaması başlıyor..."
  sleep 10 # Servislerin tam olarak oturması için kısa bir bekleme

  # Başlangıç SIM ve Mobil Veri Sıfırlama
  settings put global mobile_data 0
  sleep 2
  settings put global mobile_data 1
  stop ril-daemon
  sleep 1
  start ril-daemon
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Başlangıç SIM sıfırlaması tamamlandı."

  LAST_RESET_TIME=$(date +%s) # Son sıfırlama zamanını kaydet

  while true; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Planlanmış döngü başladı."
    CURRENT_TIME=$(date +%s)
    TIME_SINCE_LAST_RESET=$((CURRENT_TIME - LAST_RESET_TIME))

    # Arama kontrol döngüsü
    while true; do
      CALL_STATE=$(dumpsys telephony.registry | grep -m 1 'mCallState=' | awk -F= '{print $2}' | tr -d '\r')

      if [ "$CALL_STATE" = "0" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Arama yok."
        break # Arama yoksa ana döngüye geri dön
      else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Arama aktif ($CALL_STATE). Sıfırlama atlandı, 60 saniye sonra tekrar kontrol edilecek."
        sleep 60 # Arama varken 60 saniyede bir kontrol et
      fi
    done

    # Arama bittiğine göre veya zaten yoksa, 3 saatlik aralığı kontrol et
    if [ "$TIME_SINCE_LAST_RESET" -ge 10800 ]; then # 10800 saniye = 3 saat
      echo "$(date '+%Y-%m-%d %H:%M:%S') - 3 saatlik aralık doldu. SIM sıfırlaması başlatıldı."

      settings put global mobile_data 0
      sleep 2
      settings put global mobile_data 1
      stop ril-daemon
      sleep 1
      start ril-daemon

      echo "$(date '+%Y-%m-%d %H:%M:%S') - SIM sıfırlaması tamamlandı."
      LAST_RESET_TIME=$(date +%s) # Sıfırlama sonrası zamanı güncelle
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') - 3 saatlik aralık henüz dolmadı ($((TIME_SINCE_LAST_RESET / 60)) dakika geçti). Sıfırlama atlandı."
    fi

    # Bir sonraki kontrol için bekleme (Arama kontrolü olduğu için bu sleep daha kısa olabilir)
    # Burada döngünün ne kadar sıklıkta döneceğini ayarlayabilirsiniz.
    # Örneğin, her 5 dakikada bir kontrol edilebilir.
    sleep 300 # 300 saniye = 5 dakika
  done
) &
