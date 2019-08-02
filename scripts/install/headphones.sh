#!/bin/bash
#
# [Quick Box :: Install Headphones package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/QB/packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#   QuickBox.IO does not grant the end-user the right to distribute this
#   code in a means to supply commercial monetization. If you would like
#   to include QuickBox in your commercial project, write to echo@quickbox.io
#   with a summary of your project as well as its intended use for moentization.
#

YELLOW='\e[93m'
RED='\e[91m'
ENDCOLOR='\033[0m'
CYAN='\e[96m'
GREEN='\e[92m'

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
USERNAME=$(cut -d: -f1 < /root/.master.info)
PASSWD=$(cut -d: -f2 < /root/.master.info)


APPNAME='headphones'
APPSHORTNAME='hp'
APPPATH='/home/'$USERNAME'/.headphones'
APPTITLE='Headphones'
APPDEPS='git-core python python-cheetah python-pyasn1'
APPGIT='https://github.com/rembo10/headphones.git'
APPDPORT='8004'
APPSETTINGS=$APPPATH'/config.ini'
PORTSEARCH='http_port = '
USERSEARCH='http_username = '
PASSSEARCH='http_password = '
# New password encrypted
NEWPASS='$PASSWD'
# New password unencrypted
APPNEWPASS='$PASSWD'

echo
sleep 1
echo -e "Refreshing packages list ..." >>"${OUTTO}" 2>&1;
echo -e $YELLOW'--->Refreshing packages list...'$ENDCOLOR
sudo apt-get update

echo
sleep 1
echo -e "Installing prerequisites for $APPTITLE ..." >>"${OUTTO}" 2>&1;
echo -e $YELLOW'--->Installing prerequisites for '$APPTITLE'...'$ENDCOLOR
sudo apt-get -y install $APPDEPS

echo
sleep 1
echo -e "Downloading latest $APPTITLE ... " >>"${OUTTO}" 2>&1;
echo -e $YELLOW'--->Downloading latest '$APPTITLE'...'$ENDCOLOR
git clone $APPGIT $APPPATH || { echo -e $RED'Git not found.'$ENDCOLOR ; exit 1; }

echo
sleep 1
echo -e "Setting $APPTITLE permissions for $USERNAME ... " >>"${OUTTO}" 2>&1;
echo -e $YELLOW'--->Setting '$APPTITLE' permissions for '$USERNAME'...'$ENDCOLOR
sudo chown -R $USERNAME:$USERNAME $APPPATH >/dev/null 2>&1
sudo chmod -R 775 $APPPATH >/dev/null 2>&1
sudo chmod -R g+s $APPPATH >/dev/null 2>&1

echo
sleep 1
echo -e "Configuring $APPTITLE Install ..." >>"${OUTTO}" 2>&1;
echo -e $YELLOW'--->Configuring '$APPTITLE' Install...'$ENDCOLOR
APPSHORTNAMEU="${APPSHORTNAME^^}"
DEFAULTFILE='/tmp/'$APPNAME'_default'
echo $APPSHORTNAMEU"_HOME="$APPPATH"/" >> $DEFAULTFILE || { echo 'Could not create '$APPTITLE' default file.' ; exit 1; }
echo $APPSHORTNAMEU"_DATA="$APPPATH"/" >> $DEFAULTFILE
echo -e 'Enabling user '$CYAN$USERNAME$ENDCOLOR' to run '$APPTITLE'...'
echo $APPSHORTNAMEU"_USER="$USERNAME >> $DEFAULTFILE


sudo mv $DEFAULTFILE "/etc/default/"$APPNAME || { echo 'Could not move '$APPTITLE' default file.' ; exit 1; }
cat > /etc/systemd/system/headphones.service <<HEADP
[Unit]
Description=Headphones
Wants=network.target network-online.target
After=network.target network-online.target

[Service]
ExecStart=/usr/bin/python2 /home/USER/.headphones/Headphones.py -d --pidfile /var/run/USER/headphones.pid --datadir /home/USER/.headphones --nolaunch --config /home/USER/.headphones/config.ini --port 8004
PIDFile=/var/run/USER/headphones.pid
Type=forking
User=USER
Group=USER

[Install]
WantedBy=multi-user.target
HEADP
sed -i "s/USER/${USERNAME}/g" /etc/systemd/system/$APPNAME.service

echo -e "Starting $APPTITLE ... " >>"${OUTTO}" 2>&1;
echo -e $YELLOW'--->Starting '$APPTITLE$ENDCOLOR
systemctl enable $APPNAME >/dev/null 2>&1
systemctl start $APPNAME >/dev/null 2>&1
sleep 10

mkdir -p $APPPATH/logs
if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/headphones.sh
  service nginx reload
  echo "Install complete! Please note headphones access url is: https://$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')/headphones/home"
fi


touch /install/.$APPNAME.lock
echo

echo "$APPTITLE Install Complete!" >>"${OUTTO}" 2>&1;
sleep 5
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;

exit
