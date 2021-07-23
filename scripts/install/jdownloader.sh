#!/bin/bash

# References
# https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian-10
# https://support.jdownloader.org/Knowledgebase/Article/View/install-jdownloader-on-nas-and-embedded-devices
# Liara already made a doc for installing JDownloader manually https://docs.swizzin.net/guides/jdownloader/

# Get my.jdownloader info from end user
# TODO: Not sure if the following echo_query statements require the second argument of "hidden"
# TODO: Should double check to confirm everything is accurate, and loop back if anything isn't filled out.
echo_query "You will require an account at https://my.jdownloader.org/ in order to access your JDownloader installation's web UI.\nEnter the e-mail used to access this account once you have created one:" "hidden"
read 'myjd_email'
echo_query "Please enter the password for your account." "hidden"
read 'myjd_password'
echo_query "Please enter the device name you would like this installation to show up as." "hidden"
read 'myjd_devicename'

# Install Java
# TODO: use "java -version" to check if it even needs installation
echo_progress_start "Downloading and installing a Java runtime environment."
# TODO: This is going to echo a lot. Should disable that somehow probably. None of it is necessary afaik.
sudo apt update
sudo apt install default-jre -y
# TODO: use "java -version" to verify installation
echo_progress_start "Downloading and installing jdownloader"
mkdir -p /home/$user/jd
wget -q http://installer.jdownloader.org/JDownloader.jar -O /home/$user/jd/JDownloader.jar
# TODO: This is going to echo a lot. Should disable that somehow probably. None of it is necessary afaik.
java -jar /home/$user/jd/JDownloader.jar -norestart

# pass my.jdownloader information to /home/$user/jd/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json
echo_progress_start "Adding your my.jdownloader information to the installation."
cat > /home/$user/jd/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json << EOF
{
  "email" : "$myjd_email",
  "password" : "$myjd_password",
  "devicename" : "$myjd_devicename"
}
EOF

# Create systemd service file, and enable
echo_progress_start "Adding jdownloader multi-user service, and starting the service."
cat > /etc/systemd/system/jdownloader@.service << EOF
[Unit]
Description=JDownloader Service
After=network.target

[Service]
User=%i
Group=%i
Environment=JD_HOME=/home/%i/jd
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /home/%i/jd/JDownloader.jar

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now jdownloader@$user

echo_progress_done
touch /install/.jdownloader.lock
echo_success "JDownloader installed for $user"
