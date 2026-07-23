#!/system/bin/sh

MODDIR=${0%/*}
CONFIG_FILE="$MODDIR/config.prop"
LOGFILE="/data/local/tmp/simfix_lite.log"

log_msg() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"; }

read_config() {
    FIX_ACTIVE="true"
    CHECK_DATA="true"
    CHECK_VOIP="true"
    INTERVAL_HOUR="3"
    SHOW_NOTIF="false"
    EXCLUDE_PKG=""
    if [ -f "$CONFIG_FILE" ]; then
        while IFS='=' read -r K V; do
            case "$K" in
                FIX_ACTIVE)    FIX_ACTIVE="$V" ;;
                CHECK_DATA)    CHECK_DATA="$V" ;;
                CHECK_VOIP)    CHECK_VOIP="$V" ;;
                INTERVAL_HOUR) INTERVAL_HOUR="$V" ;;
                SHOW_NOTIF)    SHOW_NOTIF="$V" ;;
                EXCLUDE_PKG)   EXCLUDE_PKG="$V" ;;
            esac
        done < "$CONFIG_FILE"
    fi
}

is_in_call() {
    dumpsys telecom 2>/dev/null | grep -q "isInCall=true" && echo "1" || echo "0"
}

is_voip_active() {
    MODE=$(dumpsys audio 2>/dev/null | grep "mMode=" | head -1)
    case "$MODE" in *2*|*3*|*IN_CALL*|*IN_COMMUNICATION*) echo "1" ;; *) echo "0" ;; esac
}

do_fix() {
    log_msg "Fix start."
    DATA_WAS_ON=0
    if [ "$CHECK_DATA" = "true" ] && [ "$(settings get global mobile_data 2>/dev/null)" = "1" ]; then
        svc data disable 2>/dev/null
        DATA_WAS_ON=1
        sleep 2
    fi
    stop ril-daemon 2>/dev/null
    stop rild 2>/dev/null
    sleep 2
    start ril-daemon 2>/dev/null
    start rild 2>/dev/null
    sleep 4
    for iface in $(ip link show 2>/dev/null | grep -oE "rmnet_data[0-9]+" | head -4); do
        ip link set "$iface" down 2>/dev/null
    done
    sleep 1
    for iface in $(ip link show 2>/dev/null | grep -oE "rmnet_data[0-9]+" | head -4); do
        ip link set "$iface" up 2>/dev/null
    done
    if [ "$DATA_WAS_ON" = "1" ]; then
        sleep 1
        svc data enable 2>/dev/null
    fi
    if [ "$SHOW_NOTIF" = "true" ]; then
        TAG="SimFix_$(date '+%s')"
        R=$(cmd notification post -S bigtext -t "Sim Fix" "$TAG" "Network connection refreshed." 2>&1)
        log_msg "Notif: $R"
    fi
    log_msg "Fix done."
}

log_msg "=== SERVICE START ==="

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
sleep 60

pm list packages 2>/dev/null | cut -f2 -d: | tr -d '\r' | sort > "$MODDIR/applist.txt"
chmod 666 "$MODDIR/applist.txt" 2>/dev/null
log_msg "App list: $(wc -l < "$MODDIR/applist.txt") packages."

LAST=$(date '+%s')
log_msg "Loop active."

while true; do
    read_config
    if [ "$FIX_ACTIVE" != "true" ]; then sleep 60; continue; fi

    NOW=$(date '+%s')
    ELAPSED=$((NOW - LAST))
    if [ "$INTERVAL_HOUR" = "test" ]; then
        TARGET=60
    else
        TARGET=$(( ${INTERVAL_HOUR:-3} * 3600 ))
    fi

    if [ "$ELAPSED" -ge "$TARGET" ]; then
        if [ -n "$EXCLUDE_PKG" ]; then
            EXCL_HIT=""
            OLD_IFS="$IFS"
            IFS=','
            for PKG in $EXCLUDE_PKG; do
                if pgrep -f "$PKG" > /dev/null 2>&1; then
                    EXCL_HIT="$PKG"
                    break
                fi
            done
            IFS="$OLD_IFS"
            if [ -n "$EXCL_HIT" ]; then
                log_msg "Guard: $EXCL_HIT running, postpone 5m."
                LAST=$((NOW - TARGET + 300))
                sleep 60; continue
            fi
        fi
        if [ "$(is_in_call)" = "1" ]; then
            log_msg "Guard: call active, postpone 5m."
            LAST=$((NOW - TARGET + 300))
            sleep 60; continue
        fi
        if [ "$CHECK_VOIP" = "true" ] && [ "$(is_voip_active)" = "1" ]; then
            log_msg "Guard: VoIP active, postpone 5m."
            LAST=$((NOW - TARGET + 300))
            sleep 60; continue
        fi
        do_fix
        LAST=$(date '+%s')
    fi
    sleep 60
done
