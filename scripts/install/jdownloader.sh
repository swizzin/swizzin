#!/bin/bash
# JDownloader Installer for swizzin
# Author: Aethaeran

# References
# https://swizzin.ltd/dev/structure/
# https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian-10
# https://support.jdownloader.org/Knowledgebase/Article/View/install-jdownloader-on-nas-and-embedded-devices
# https://support.jdownloader.org/Knowledgebase/Article/View/headless-systemd-autostart-script
# Liara already made a doc for installing JDownloader manually https://docs.swizzin.net/guides/jdownloader/
# https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
# https://linuxize.com/post/bash-check-if-file-exists/

# Functions
function install_jdownloader() {

    echo_progress_start "Downloading and installing JDownloader for the user: $user"
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
    mkdir -p /home/"$user"/jd2
    wget -q http://installer.jdownloader.org/JDownloader.jar -O /home/"$user"/jd2/JDownloader.jar
    # Run JDownloader once to generate the majority of files and dirs.
    # The following SC2154 is disabled because log is included from box when this script is called from it.
    # shellcheck disable=SC2154
    # TODO: This is failing when called from 'box install' for some reason.
    java -jar /home/"$user"/jd2/JDownloader.jar -norestart >> "${log}" 2>&1
    # Check if JDownloader's first run was successful.
    # TODO: Figure out if there is a better file or folder for this test, whichever file is generated last would be best.
    if [[ -e "/home/$user/jd2/build.json" ]]; then
        echo_info "JDownloader's first run was likely successful."
    else
        echo_info "JDownloader's first run likely failed. Exiting."
        exit 2
    fi
    echo_progress_done

    # Pass my.jdownloader.org information to org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json
    echo_progress_start "Adding the users https://my.jdownloader.org/ information to their installation."
    cat > /home/"$user"/jd2/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json << EOF
    {
      "email" : "$myjd_email",
      "password" : "$myjd_password",
      "devicename" : "$myjd_devicename"
    }
EOF
    echo_progress_done
    echo_progress_start "Enabling service jdownloader@$user."

    systemctl enable -q --now jdownloader@"$user"
    echo_progress_done
}

# If there was a variable passed to this script, it isn't the initial installation.
# It is likely being called because a user is being added with "box adduser".
# Install JDownloader for just this user, and exit.
if [[ -n "$1" ]]; then
    user="$1"
    install_jdownloader
    exit 0
fi

# If we made it through the previous block. The script has likely been called from "box install".
# Install Java
if [[ ! -e /usr/bin/java ]]; then
    echo_info "Java was not found. swizzin will need to install it."
    echo_progress_start "Downloading and installing the default Java Runtime Environment for your distribution."
    apt_update
    apt_install default-jre
    # verify installation
    if [[ ! -e /usr/bin/java ]]; then
        echo_info "Java was not installed successfully. Exiting."
        exit 1
    else
        echo_info "Java was installed successfully."
    fi
    echo_progress_done
else
    echo_info "Java is already installed."
fi

# TODO: JDownloader's suggested service file uses a pidfile rather than an environment variable. Which is optimal?
# If it doesn't already exist. Create the systemd service file.
if [[ ! -e /etc/systemd/system/jdownloader.@service ]]; then
    echo_progress_start "Creating jdownloader service file..."
    cat > /etc/systemd/system/jdownloader@.service << EOF
    [Unit]
    Description=JDownloader Service
    After=network.target

    [Service]
    User=%i
    Group=%i
    Environment=JD_HOME=/home/%i/jd2
    ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /home/%i/jd2/JDownloader.jar

    [Install]
    WantedBy=multi-user.target
EOF
    echo_progress_done
fi

# Check for all current swizzin users, and install JDownloader for each user.
users=("$(_get_user_list)")
# The following line cannot follow SC2068 because it will cause the list to become a string.
# shellcheck disable=SC2068
for user in ${users[@]}; do
    install_jdownloader
done

# Finalize installation

echo_progress_start "Creating jdownloader lock file..."
touch /install/.jdownloader.lock
echo_progress_done
echo_success "JDownloader installed."