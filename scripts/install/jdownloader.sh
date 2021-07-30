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
# https://superuser.com/questions/402979/kill-program-after-it-outputs-a-given-line-from-a-shell-script

# Functions
function install_jdownloader() {

    echo_progress_start "Configuring, downloading and installing JDownloader for this user: $user"

    # Get my.jdownloader info for user
    # TODO: Should double check to confirm everything is accurate, and loop back if anything isn't filled out. swizzin likely has utils for this already
    echo_info "An account from https://my.jdownloader.org/ is required in order to access the web UI.\nUse a randomly generated password at registration as the password is stored in plain text."
    echo_query "Enter the e-mail used to access this account once one is created:"
    read -r 'myjd_email'
    echo_query "Please enter the password for the account."
    read -r 'myjd_password'
    echo_query "Please enter the desired device name"
    read -r 'myjd_devicename'

    # Pass my.jdownloader.org information to org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json
    JD_HOME="/home/$user/jd2"
    echo_info "Adding the users https://my.jdownloader.org/ information to their installation."
    mkdir -p "$JD_HOME/cfg"
    cat > "$JD_HOME/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json" << EOF
    {
      "email" : "$myjd_email",
      "password" : "$myjd_password",
      "devicename" : "$myjd_devicename"
    }
EOF

    # Install JDownloader
    JD_HOME="/home/$user/jd2"
    echo "Make dir"
    mkdir -p "$JD_HOME/cfg"
    echo "get jar"
    if [[ ! -e "$JD_HOME/JDownloader.jar" ]]; then
      wget -q http://installer.jdownloader.org/JDownloader.jar -O "$JD_HOME/JDownloader.jar"
    fi
    # TODO: Would this make a good function in other instances?
    # Run command until a certain file is created.
    command="java -jar $JD_HOME/JDownloader.jar -norestart >> '${log}' "
    # TODO: Don't know if this tmp log is really necessary. I just don't want it to be reading anything from previous runs.
    tmp_log="/tmp/jdownloader_install.log"
    touch $tmp_log
    while [ ! -e "$JD_HOME/build.json" ]
    do
    echo_info "$JD_HOME/build.json doesn't exist yet. Run JDownloader to generate files."
    $command > "$tmp_log" 2>&1 &
    pid=$!
    trap "kill $pid 2> /dev/null" EXIT
    # While background command is running...
    # If any of specified strings are found in the log, kill the last called background command.
    while kill -0 $pid 2> /dev/null; do
        # TODO: Some case handling would be good here.  (( My.Jdownloader login failed \\ first run finished \\ started successfully? ))
        # TODO: Another alternative could be to have it iterate a list of strings instead of being spread out like this.
        # Pace out the fgrep by pausing for a second
        sleep 1
        if fgrep -q "No Console Available!" "$tmp_log" || fgrep -q "Shutdown Hooks Finished" "$tmp_log" || fgrep -q "Start HTTP Server" "$tmp_log"
        then
            # Kill the background command
            kill $pid
            # Remove the tmp log
            rm $tmp_log
            # Disable the trap on a normal exit.
            trap - EXIT
            echo_info "Killed JDownloader."
        fi
    done
    done
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
