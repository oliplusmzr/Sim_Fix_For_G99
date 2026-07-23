#!/system/bin/sh

MODDIR=${0%/*}
CONFIG_FILE="$MODDIR/config.prop"
LOG_FILE="/data/local/tmp/simfix_lite.log"
ACTION=$1
if [ -z "$ACTION" ]; then ACTION="status"; fi

case "$ACTION" in

    get_config)
        if [ -f "$CONFIG_FILE" ]; then
            OUT=""
            while IFS='=' read -r K V; do
                case "$K" in
                    FIX_ACTIVE|CHECK_DATA|CHECK_VOIP|INTERVAL_HOUR|ROM_TYPE|SHOW_NOTIF|EXCLUDE_PKG)
                        OUT="${OUT}${K}=${V}###"
                    ;;
                esac
            done < "$CONFIG_FILE"
            echo "$OUT"
        else
            echo "FIX_ACTIVE=false###CHECK_DATA=false###CHECK_VOIP=false###INTERVAL_HOUR=3###ROM_TYPE=AUTO###SHOW_NOTIF=false###"
        fi
        ;;

    save_config)
        SAVED_EXCLUDE=""
        if [ -f "$CONFIG_FILE" ]; then
            while IFS='=' read -r K V; do
                if [ "$K" = "EXCLUDE_PKG" ] && [ -n "$V" ]; then
                    SAVED_EXCLUDE="$V"
                fi
            done < "$CONFIG_FILE"
        fi
        printf 'FIX_ACTIVE=%s\n'    "$2" >  "$CONFIG_FILE"
        printf 'CHECK_DATA=%s\n'    "$3" >> "$CONFIG_FILE"
        printf 'CHECK_VOIP=%s\n'    "$4" >> "$CONFIG_FILE"
        printf 'INTERVAL_HOUR=%s\n' "$5" >> "$CONFIG_FILE"
        printf 'ROM_TYPE=%s\n'      "$6" >> "$CONFIG_FILE"
        printf 'SHOW_NOTIF=%s\n'    "$7" >> "$CONFIG_FILE"
        if [ -n "$SAVED_EXCLUDE" ]; then
            printf 'EXCLUDE_PKG=%s\n' "$SAVED_EXCLUDE" >> "$CONFIG_FILE"
        fi
        chmod 666 "$CONFIG_FILE" 2>/dev/null
        echo "OK"
        ;;

    search_apps)
        QUERY="$2"
        if [ -f "$MODDIR/applist.txt" ] && [ -s "$MODDIR/applist.txt" ]; then
            SRC="$MODDIR/applist.txt"
        else
            pm list packages 2>/dev/null | cut -f2 -d: | tr -d '\r' | sort > "$MODDIR/applist.txt"
            chmod 666 "$MODDIR/applist.txt" 2>/dev/null
            SRC="$MODDIR/applist.txt"
        fi
        if [ -z "$QUERY" ]; then
            RESULTS=$(head -30 "$SRC" | tr '\n' '###')
        else
            RESULTS=$(grep -i "$QUERY" "$SRC" 2>/dev/null | head -30 | tr '\n' '###')
        fi
        TOTAL=$(wc -l < "$SRC" 2>/dev/null | tr -d ' ')
        echo "TOTAL=${TOTAL}###${RESULTS}"
        ;;

    refresh_apps)
        pm list packages 2>/dev/null | cut -f2 -d: | tr -d '\r' | sort > "$MODDIR/applist.txt"
        chmod 666 "$MODDIR/applist.txt" 2>/dev/null
        LINES=$(wc -l < "$MODDIR/applist.txt" | tr -d ' ')
        echo "OK###LINES=${LINES}"
        ;;

    save_exclude)
        NEW_PKG="$2"
        CURRENT=""
        if [ -f "$CONFIG_FILE" ]; then
            while IFS='=' read -r K V; do
                if [ "$K" = "EXCLUDE_PKG" ] && [ -n "$V" ]; then
                    CURRENT="$V"
                fi
            done < "$CONFIG_FILE"
        fi
        case ",$CURRENT," in
            *",$NEW_PKG,"*)
                echo "ALREADY_EXISTS"
                ;;
            *)
                if [ -z "$CURRENT" ]; then
                    MERGED="$NEW_PKG"
                else
                    MERGED="$CURRENT,$NEW_PKG"
                fi
                if [ -f "$CONFIG_FILE" ]; then
                    sed -i '/^EXCLUDE_PKG=/d' "$CONFIG_FILE"
                fi
                printf 'EXCLUDE_PKG=%s\n' "$MERGED" >> "$CONFIG_FILE"
                echo "OK"
                ;;
        esac
        ;;

    remove_exclude)
        PKG_TO_REMOVE="$2"
        if [ -f "$CONFIG_FILE" ]; then
            if [ -z "$PKG_TO_REMOVE" ]; then
                sed -i '/^EXCLUDE_PKG=/d' "$CONFIG_FILE"
            else
                CURRENT=""
                while IFS='=' read -r K V; do
                    if [ "$K" = "EXCLUDE_PKG" ]; then CURRENT="$V"; fi
                done < "$CONFIG_FILE"
                UPDATED=$(echo "$CURRENT" | tr ',' '\n' | grep -vxF "$PKG_TO_REMOVE" | tr '\n' ',' | sed 's/,$//')
                sed -i '/^EXCLUDE_PKG=/d' "$CONFIG_FILE"
                if [ -n "$UPDATED" ]; then
                    printf 'EXCLUDE_PKG=%s\n' "$UPDATED" >> "$CONFIG_FILE"
                fi
            fi
        fi
        echo "OK"
        ;;

    manual_fix)
        DATA_WAS_ON=0
        if [ "$(settings get global mobile_data 2>/dev/null)" = "1" ]; then
            svc data disable 2>/dev/null
            DATA_WAS_ON=1
            sleep 2
        fi
        stop ril-daemon 2>/dev/null
        stop rild 2>/dev/null
        sleep 2
        start ril-daemon 2>/dev/null
        start rild 2>/dev/null
        sleep 3
        for iface in $(ip link show 2>/dev/null | grep -oE "rmnet_data[0-9]+" | head -4); do
            ip link set "$iface" down 2>/dev/null
            sleep 1
            ip link set "$iface" up 2>/dev/null
        done
        if [ "$DATA_WAS_ON" = "1" ]; then
            svc data enable 2>/dev/null
        fi
        echo "OK"
        ;;

    test_notif)
        R=$(cmd notification post -S bigtext -t "Sim Fix" "SimTest_$$" "Notification is working." 2>&1)
        E=$?
        echo "exit=${E}###out=${R}"
        ;;

    clear_log)
        printf '' > "$LOG_FILE"
        chmod 666 "$LOG_FILE" 2>/dev/null
        echo "OK"
        ;;

    debug_info)
        RIL=$(pgrep -f ril-daemon 2>/dev/null | head -1)
        RILD=$(pgrep -f rild 2>/dev/null | head -1)
        IFACES=$(ip link show 2>/dev/null | grep -E "rmnet|wlan" | awk '{print $2}' | tr -d ':' | tr '\n' ',')
        CFG=""
        if [ -f "$CONFIG_FILE" ]; then
            CFG=$(cat "$CONFIG_FILE" | tr '\n' '|')
        fi
        APPLINES=""
        if [ -f "$MODDIR/applist.txt" ]; then
            APPLINES=$(wc -l < "$MODDIR/applist.txt" | tr -d ' ')
        fi
        LOG=""
        if [ -f "$LOG_FILE" ]; then
            LOG=$(tail -6 "$LOG_FILE" | tr '\n' '|')
        fi
        echo "MODEL=$(getprop ro.product.model)###ANDROID=$(getprop ro.build.version.release)###SDK=$(getprop ro.build.version.sdk)###RIL_PID=${RIL:-none}###RILD_PID=${RILD:-none}###IFACES=${IFACES:-none}###MOBILE_DATA=$(settings get global mobile_data 2>/dev/null)###AIRPLANE=$(settings get global airplane_mode_on 2>/dev/null)###CONFIG=${CFG}###APP_LINES=${APPLINES:-0}###LOG=${LOG}###"
        ;;

    status)
        if [ -f "$CONFIG_FILE" ]; then
            cat "$CONFIG_FILE"
        else
            echo "no config"
        fi
        ;;

esac
