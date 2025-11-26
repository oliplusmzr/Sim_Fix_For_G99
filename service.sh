#!/system/bin/sh

LOGFILE="/data/local/tmp/simfix_lite.log"

log_msg() {
    echo "$1"
    echo "$1" >> $LOGFILE
}
echo "
╔══╦╗──╔══╦╗─╔══╗──╔══╦═══╦═══╗
║══╬╬══╣═╦╬╬╦╣═╦╩╦╦╣╔═╣╔═╗║╔═╗║
╠══║║║║║╔╝║╠║╣╔╣╬║╔╣╚╗║╚═╝║╚═╝║
╚══╩╩╩╩╩╝─╚╩╩╩╝╚═╩╝╚══╩══╗╠══╗║
──────────────────────╔══╝╠══╝║
Build: Carmine"

check_log_size() {
    if [ -f "$LOGFILE" ]; then
        FILESIZE=$(stat -c%s "$LOGFILE")
        if [ $FILESIZE -ge 1048576 ]; then
            echo "Log cleared due to size limit." > "$LOGFILE"
        fi
    fi
}

check_normal_call() {
    CHECK_TELECOM=$(dumpsys telecom 2>/dev/null | grep "isInCall=true")
    CHECK_REGISTRY=$(dumpsys telephony.registry 2>/dev/null | grep "mCallState=" | head -n 1 | grep -v "=0")

    if [ -n "$CHECK_TELECOM" ]; then
        echo "1" 
    elif [ -n "$CHECK_REGISTRY" ]; then
        echo "1" 
    else
        echo "0" 
    fi
}

check_voip_call() {
    AUDIO_MODE=$(dumpsys audio 2>/dev/null | grep "mMode=" | head -n 1)
    case "$AUDIO_MODE" in
        *"2"*|*"3"*|*"IN_CALL"*|*"IN_COMMUNICATION"*)
            echo "1"
            ;;
        *)
            echo "0"
            ;;
    esac
}

check_data_status() {
    settings get global mobile_data 2>/dev/null
}

echo "SIM FIX LITE STARTED: $(date)" > $LOGFILE

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

sleep 60
log_msg "$(date '+%H:%M') - Boot ok. Timer start."

LAST_RESET_TIME=$(date '+%s')

while true; do
    sleep 60
    
    CURRENT_TIME=$(date '+%s')
    TIME_SINCE_LAST_RESET=$((CURRENT_TIME - LAST_RESET_TIME))
    
    if [ $TIME_SINCE_LAST_RESET -ge 10800 ]; then
    
        check_log_size
        
        log_msg "$(date '+%H:%M') - 3H Check..."
        
        NORMAL_CALL=$(check_normal_call)
        if [ "$NORMAL_CALL" = "1" ]; then
            log_msg "Call detected. Postponing 5m."
            LAST_RESET_TIME=$((CURRENT_TIME - 10500)) 
            continue
        fi

        VOIP_CALL=$(check_voip_call)
        if [ "$VOIP_CALL" = "1" ]; then
            log_msg "VoIP detected. Postponing 5m."
            LAST_RESET_TIME=$((CURRENT_TIME - 10500))
            continue
        fi
        
        log_msg "No calls. Resetting..."
        
        DATA_STATUS=$(check_data_status)
        
        if [ "$DATA_STATUS" = "1" ]; then
            svc data disable
            sleep 1
            stop ril-daemon
            sleep 1
            start ril-daemon
            sleep 5
            svc data enable
        else
            stop ril-daemon
            sleep 1
            start ril-daemon
            sleep 5
        fi
        
        log_msg "$(date '+%H:%M') - Done."
        LAST_RESET_TIME=$(date '+%s')
    fi
    
done
