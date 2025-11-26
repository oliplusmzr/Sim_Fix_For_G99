set -x
exec > /data/local/tmp/simfix_debug.log 2>&1
LOGFILE="/data/local/tmp/simfix_action.txt"
{
  echo "====== $(date) ======"
  echo "Manual SIM reset started"
} >> $LOGFILE
echo "         **** $(date) **** "
echo " Service Started"
sleep 1
echo "
                      ᴴᵉˡⁱᵒ
╔══╦╗──╔══╦╗─╔══╗──╔══╦═══╦═══╗
║══╬╬══╣═╦╬╬╦╣═╦╩╦╦╣╔═╣╔═╗║╔═╗║
╠══║║║║║╔╝║╠║╣╔╣╬║╔╣╚╗║╚═╝║╚═╝║
╚══╩╩╩╩╩╝─╚╩╩╩╝╚═╩╝╚══╩══╗╠══╗║
──────────────────────╔══╝╠══╝║"
sleep 1
echo " Version Carmine"
svc data disable
sleep 1
svc data enable
stop ril-daemon
sleep 1
start ril-daemon
sleep 10
echo " Manual SIM reset completed."
sleep 2
echo " Feedback = > Telegram @oliplusmzr"
sleep 1 
echo "Manual SIM reset completed." >> $LOGFILE
echo "" >> $LOGFILE
log -p i -t SIM_FIX "Manual SIM reset done via ACTION button"
