#!/system/bin/sh

MODDIR=${0%/*}

(
exec > /data/local/tmp/simfix_debug.log 2>&1
set -x

LOGFILE="/data/local/tmp/simfix_log.txt"
DATEFILE="/data/local/tmp/simfix_log_date.txt"

log -p i -t SIM_FIX "Waiting for boot completion..."
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 5
done

log -p i -t SIM_FIX "Boot completed. Waiting 2 minutes..."
sleep 120

echo "====== $(date) ======" >> $LOGFILE
echo "Initial SIM reset started" >> $LOGFILE

settings put global mobile_data 0
sleep 2
settings put global mobile_data 1
stop ril-daemon
sleep 1
start ril-daemon

echo "$(date) - Initial SIM reset completed." >> $LOGFILE
log -p i -t SIM_FIX "Initial SIM reset completed."

while true; do
  TODAY=$(date +%Y-%m-%d)
  if [ -f "$DATEFILE" ]; then
    LAST_DATE=$(cat "$DATEFILE")
    if [ "$TODAY" != "$LAST_DATE" ]; then
      echo "" > "$LOGFILE"
    fi
  fi
  echo "$TODAY" > "$DATEFILE"

  CALL_STATE=$(dumpsys telephony.registry | grep -m 1 'mCallState=' | awk -F= '{print $2}' | tr -d '\r')

  if [ "$CALL_STATE" = "0" ]; then
    log -p i -t SIM_FIX "No call. Starting scheduled SIM reset..."
    echo "$(date) - SIM reset started" >> $LOGFILE

    settings put global mobile_data 0
    sleep 2
    settings put global mobile_data 1
    stop ril-daemon
    sleep 1
    start ril-daemon

    echo "$(date) - SIM reset completed." >> $LOGFILE
    echo "" >> $LOGFILE
  else
    log -p i -t SIM_FIX "Call active. Reset postponed."
    echo "$(date) - Call active. SIM reset skipped." >> $LOGFILE
  fi

  sleep 18000
done

) &
