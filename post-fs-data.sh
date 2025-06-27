#!/system/bin/sh

(
set -x
exec > /data/local/tmp/simfix_debug.log 2>&1

LOGFILE="/data/local/tmp/simfix_log.txt"
DATEFILE="/data/local/tmp/simfix_log_date.txt"

log -p i -t SIM_FIX "Boot bekleniyor..."
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 5
done

log -p i -t SIM_FIX "Boot tamamland?. 2 dakika bekleniyor..."
sleep 120

echo "====== $(date) ======" >> $LOGFILE
echo "Initial SIM reset started" >> $LOGFILE

settings put global mobile_data 0
sleep 1
settings put global mobile_data 1
stop ril-daemon
sleep 1
start ril-daemon

echo "$(date) - Initial SIM reset completed after boot." >> $LOGFILE
echo "" >> $LOGFILE

log -p i -t SIM_FIX "Initial SIM reset completed."

while true; do
  TODAY=$(date +%Y-%m-%d)
  [ -f "$DATEFILE" ] && LAST_DATE=$(cat "$DATEFILE")
  [ "$TODAY" != "$LAST_DATE" ] && echo "" > "$LOGFILE"
  echo "$TODAY" > "$DATEFILE"

  CALL_STATE=$(dumpsys telephony.registry | grep -m 1 'mCallState=' | awk -F= '{print $2}' | tr -d '\r')
  if [ "$CALL_STATE" = "0" ]; then
    log -p i -t SIM_FIX "No active call. SIM reset initiated."
    echo "$(date) - SIM reset started" >> $LOGFILE

    settings put global mobile_data 0
    sleep 1
    settings put global mobile_data 1
    stop ril-daemon
    sleep 1
    start ril-daemon

    echo "$(date) - SIM reset complete." >> $LOGFILE
    echo "" >> $LOGFILE
  else
    log -p i -t SIM_FIX "Call active. Reset delayed."
    echo "$(date) - Call active. Reset delayed." >> $LOGFILE
  fi

  sleep 18000
done

) &
