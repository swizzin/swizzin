#!/bin/bash

# References
# https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian-10
# https://support.jdownloader.org/Knowledgebase/Article/View/install-jdownloader-on-nas-and-embedded-devices
# Liara already made a doc for installing JDownloader manually https://docs.swizzin.net/guides/jdownloader/

# Get my.jdownloader info from end user
# TODO: Should double check to confirm everything is accurate, and loop back if anything isn't filled out.
echo_query "You will require an account at https://my.jdownloader.org/ in order to access your JDownloader installation's web UI.\nIt is recommended to use a randomly generated password for your account since the password is save in plain text on the server.\nEnter the e-mail used to access this account once you have created one:"
read 'myjd_email'
echo_query "Please enter the password for your account."
read 'myjd_password'
echo_query "Please enter the device name you would like this installation to show up as."
read 'myjd_devicename'

# Install Java
# TODO: use "java -version" to check if it even needs installation
echo_progress_start "Downloading and installing a Java runtime environment."
apt_update
apt_install default-jre
# TODO: use "java -version" to verify installation

# Install JDownloader
echo_progress_start "Downloading and installing jdownloader"
mkdir -p /home/$1/jd
wget -q http://installer.jdownloader.org/JDownloader.jar -O /home/$1/jd/JDownloader.jar

# Run JDownloader once to generate the majority of files and dirs.
java -jar /home/$1/jd/JDownloader.jar -norestart >> ${log} 2>&1
# TODO: Check if it ran correctly.

# Pass my.jdownloader information to /home/$1/jd/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json
echo_progress_start "Adding your my.jdownloader information to the installation."
cat > /home/$1/jd/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json << EOF
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
systemctl enable -q --now jdownloader@$1

# Finalize installation
echo_progress_done
touch /install/.jdownloader.lock
echo_success "JDownloader installed"
