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

OUTTO=/srv/rutorrent/home/db/output.log
USERNAME=$(cat /srv/rutorrent/home/db/master.txt)
PASSWD=$(cat /root/$USERNAME.info | cut -d ":" -f 3 | cut -d "@" -f 1)
local_setup=/etc/QuickBox/setup/


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
chown www-data: /etc/apache2/sites-enabled/$APPNAME.conf  >/dev/null 2>&1
sudo chown -R $USERNAME:$USERNAME $APPPATH >/dev/null 2>&1
sudo chmod -R 775 $APPPATH >/dev/null 2>&1
sudo chmod -R g+s $APPPATH >/dev/null 2>&1
sudo mkdir -p /var/run/$APPNAME >/dev/null 2>&1
sudo chmod 755 /var/run/$APPNAME >/dev/null 2>&1
sudo chown -R $USERNAME /var/run/$APPNAME >/dev/null 2>&1

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
cp ${local_setup}templates/sysd/$APPNAME.template /etc/systemd/system/$APPNAME.service
sed -i "s/USER/${USERNAME}/g" /etc/systemd/system/$APPNAME.service
systemctl enable $APPNAME >/dev/null 2>&1
systemctl start $APPNAME >/dev/null 2>&1
systemctl stop $APPNAME >/dev/null 2>&1
#/etc/init.d/$APPNAME start >/dev/null 2>&1
#/etc/init.d/$APPNAME stop >/dev/null 2>&1
#sudo cp $APPPATH/init-scripts/init.ubuntu /etc/init.d/$APPNAME || { echo $RED'Creating init file failed.'$ENDCOLOR ; exit 1; }

cat > /etc/apache2/sites-enabled/$APPNAME.conf <<EOF
<Location /$APPNAME>
ProxyPass http://localhost:$APPDPORT
ProxyPassReverse http://localhost:$APPDPORT
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user $USERNAME
</Location>
EOF

echo
sleep 1
echo -e "Enabling $APPTITLE Autostart at Boot ... " >>"${OUTTO}" 2>&1;
echo -e $YELLOW'--->Enabling '$APPTITLE' Autostart at Boot...'$ENDCOLOR
sudo chown $USERNAME:$USERNAME /etc/systemd/system/$APPNAME.service
sudo chmod +x /etc/systemd/system/$APPNAME.service
sudo update-rc.d $APPNAME defaults

echo
sleep 1
echo -e "Starting $APPTITLE ... " >>"${OUTTO}" 2>&1;
echo -e $YELLOW'--->Starting '$APPTITLE$ENDCOLOR
systemctl start $APPNAME >/dev/null 2>&1
sleep 10
systemctl stop $APPNAME >/dev/null 2>&1

mkdir -p $APPPATH/logs
cp ${local_setup}configs/headphones/config.ini $APPPATH/config.ini
sudo chown -R $USERNAME:$USERNAME $APPPATH

sudo sed -i "s/USER/${USERNAME}/g" $APPSETTINGS ## || { echo -e $RED'Modifying config file failed.'$ENDCOLOR; exit 1; }
#sudo sed -i 's@http_host = localhost@http_host = 0.0.0.0@g' $APPSETTINGS  || { echo -e $RED'Modifying http_host in config file failed.'$ENDCOLOR; exit 1; }

systemctl start $APPNAME

touch /install/.$APPNAME.lock
echo

echo "$APPTITLE Install Complete!" >>"${OUTTO}" 2>&1;
sleep 5
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
service apache2 reload > /dev/null 2>&1

exit
