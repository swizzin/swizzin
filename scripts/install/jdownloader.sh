#!/bin/bash
# JDownloader Installer for swizzin
# Author: Aethaeran

# References
# https://swizzin.ltd/dev/structure/
# https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian-10
# https://support.jdownloader.org/Knowledgebase/Article/View/install-jdownloader-on-nas-and-embedded-devices
# Liara already made a doc for installing JDownloader manually https://docs.swizzin.net/guides/jdownloader/
# https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
# https://linuxize.com/post/bash-check-if-file-exists/

# Functions
function install_jdownloader() {

    # Get my.jdownloader info for user
    # TODO: Should double check to confirm everything is accurate, and loop back if anything isn't filled out.
    # TODO: swizzin likely has utils for this already
    echo_info "An account from https://my.jdownloader.org/ is required in order to access the web UI.\nUse a randomly generated password at registration as the password is stored in plain text."
    echo_query "Enter the e-mail used to access this account once one is created:"
    read -r 'myjd_email'
    echo_query "Please enter the password for the account."
    read -r 'myjd_password'
    echo_query "Please enter the desired device name"
    read -r 'myjd_devicename'

    # Install JDownloader
    echo_progress_start "Downloading and installing JDownloader for $user"
    mkdir -p /home/"$user"/jd
    wget -q http://installer.jdownloader.org/JDownloader.jar -O /home/"$user"/jd/JDownloader.jar
    # Run JDownloader once to generate the majority of files and dirs.
    java -jar /home/"$user"/jd/JDownloader.jar -norestart >> ${log} 2>&1
    # Check if JDownloader's first run was successful.
    # TODO: Figure out if there is a better file or folder for this test, whichever file is generated last would be best.
    if [[ -e "/home/$user/jd/cfg" ]]; then
        echo_info "JDownloader's first run was likely successful."
    else
        echo_info "JDownloader's first run likely failed. Exiting."
        exit 2
    fi

    # Pass my.jdownloader.org information to org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json
    echo_progress_start "Adding the users https://my.jdownloader.org/ information to their installation."
    cat > /home/"$user"/jd/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json << EOF
    {
      "email" : "$myjd_email",
      "password" : "$myjd_password",
      "devicename" : "$myjd_devicename"
    }
EOF

    systemctl enable -q --now jdownloader@"$user"
}

# If there was a variable passed to this script, it isn't the initial installation.
# It is likely being called because a user is being added with "box adduser".
# Install JDownloader for just this user, and exit.
if [[ -n $1 ]]; then
    user=$1
    install_jdownloader "${user}"
    exit 0
fi

# If we made it through the previous block. The script has likely been called from "box install".
# Install Java
# use "java -version" to check if it even needs installation
STR=$(java --version)
SUB='not found'
if [[ "$STR" == *"$SUB"* ]]; then
    echo_info "Java was not found. swizzin will need to install it."
    echo_progress_start "Downloading and installing a Java runtime environment."
    apt_update
    apt_install default-jre
    # use "java -version" to verify installation
    STR=$(java --version)
    SUB='not found'
    if [[ "$STR" == *"$SUB"* ]]; then
        echo_info "Java was not installed correctly. Check the swizzin log for details. Exiting."
        exit 1
    else
        echo_info "Java was installed successfully."
    fi
else
    echo_info "Java was found. No need to install."
fi

# Create systemd service file, and enable
echo_progress_start "Adding jdownloader@.service file..."
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

# Check for all current swizzin users, and install JDownloader for each user.
users=("$(_get_user_list)")

for user in "${users[@]}"; do
    install_jdownloader "${user}"
done

# Finalize installation
echo_progress_done
touch /install/.jdownloader.lock
echo_success "JDownloader installed"
