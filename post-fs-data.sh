#!/system/bin/sh

set -x
exec > /data/local/tmp/simfix_debug.log 2>&1

{
  echo ""
  echo "============================================="
  echo "== SIM BUG FIXER v1.0 by @oliplusmzr loaded =="
  echo "== $(date '+%Y-%m-%d %H:%M:%S') =="
  echo "============================================="
} &

(
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for boot..."
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
  done

  echo "$(date '+%Y-%m-%d %H:%M:%S') - Boot completed. Initial SIM reset starting..."
  sleep 10

  settings put global mobile_data 0
  sleep 2
  settings put global mobile_data 1
  stop ril-daemon
  sleep 1
  start ril-daemon

  echo "$(date '+%Y-%m-%d %H:%M:%S') - Initial SIM reset done."

  while true; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Scheduled loop started."
    CALL_STATE=$(dumpsys telephony.registry | grep -m 1 'mCallState=' | awk -F= '{print $2}' | tr -d '\r')

    if [ "$CALL_STATE" = "0" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') - No call. SIM reset initiated."

      settings put global mobile_data 0
      sleep 2
      settings put global mobile_data 1
      stop ril-daemon
      sleep 1
      start ril-daemon

      echo "$(date '+%Y-%m-%d %H:%M:%S') - SIM reset completed."
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') - Call active. Reset skipped."
    fi

    sleep 10800
  done
) &
