#!/bin/bash
if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
USERNAME=$(cut -d: -f1 < /root/.master.info)
APPNAME='headphones'
APPPATH='/home/'$USERNAME'/.headphones'
APPTITLE='Headphones'

echo
sleep 1
# for output to box
echo -e "Disabling and stopping $APPTITLE ..."
# for output to dashboard
echo -e "Disabling and stopping $APPTITLE ..." >>"${OUTTO}" 2>&1;
systemctl disable $APPNAME
systemctl stop $APPNAME

# for output to box
echo -e "Removing service and configuration files for $APPTITLE ..."
# for output to dashboard
echo -e "Removing service and configuration files for $APPTITLE ..." >>"${OUTTO}" 2>&1;
rm /etc/systemd/system/$APPNAME.service
rm -f /etc/nginx/apps/$APPNAME.conf
rm -rf /etc/default/$APPNAME
rm -rf $APPPATH

# for output to box
echo -e "Removing $APPTITLE lock file ..."
# for output to dashboard
echo -e "Removing $APPTITLE lock file ..." >>"${OUTTO}" 2>&1;
rm -f /install/.$APPNAME.lock

# for output to box
echo -e "Reloading apache ..."
# for output to dashboard
echo -e "Reloading apache ..." >>"${OUTTO}" 2>&1;
service nginx reload

# for output to box
echo "$APPTITLE has been removed"
echo
echo
# for output to dashboard
echo "$APPTITLE has been removed" >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
