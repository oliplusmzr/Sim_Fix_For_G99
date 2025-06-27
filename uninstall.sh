#!/system/bin/sh
rm -f /sdcard/simfix_log.txt
rm -f /sdcard/simfix_log_date.txt
rm -f /sdcard/simfix.log
rm -f /sdcard/Download/simfix_log.txt
rm -f /data/local/tmp/simfix
rm -f /data/local/tmp/simfix.log
rm -f /data/local/tmp/simfix_log.txt
rm -f /data/local/tmp/simfix_log_date.txt
rm -f /data/local/tmp/debug_service.log
# Don't modify anything after this
if [ -f $INFO ]; then
  while read LINE; do
    if [ "$(echo -n $LINE | tail -c 1)" == "~" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f $LINE~ $LINE
    else
      rm -f $LINE
      while true; do
        LINE=$(dirname $LINE)
        [ "$(ls -A $LINE 2>/dev/null)" ] && break 1 || rm -rf $LINE
      done
    fi
  done < $INFO
  rm -f $INFO
fi
#Goodbye my Boi
