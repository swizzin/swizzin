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

    echo_info "Configuring, downloading and installing JDownloader for $user"

    # Get my.jdownloader info for user
    # TODO: Should double check to confirm everything is accurate, and loop back if anything isn't filled out. swizzin likely has utils for this already
    # TODO: Add environment variable that will allow for this to be bypassed?
    echo_info "An account from https://my.jdownloader.org/ is required in order to access the web UI.\nUse a randomly generated password at registration as the password is stored in plain text."
    echo_query "Please enter the e-mail used to access this account once created:"
    read -r 'myjd_email'
    echo_query "Please enter the password for the account."
    read -r 'myjd_password'
    echo_query "Please enter the desired device name"
    read -r 'myjd_devicename'

    # Pass https://my.jdownloader.org/ account information to org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json
    JD_HOME="/home/$user/jd2"
    # echo_info "Making the JDownloader directory."
    mkdir -p "$JD_HOME/cfg"
    # echo_info "Adding the users https://my.jdownloader.org/ information to their installation."
    cat > "$JD_HOME/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json" << EOF
    {
      "email" : "$myjd_email",
      "password" : "$myjd_password",
      "devicename" : "$myjd_devicename"
    }
EOF

    # Install JDownloader
    echo_progress_start "Downloading JDownloader.jar."
    if [[ ! -e "$JD_HOME/JDownloader.jar" ]]; then
        wget -q http://installer.jdownloader.org/JDownloader.jar -O "$JD_HOME/JDownloader.jar" || {
            echo_error "Failed to download"
            exit 1
        }
    fi
    echo_progress_done "Jar downloaded"

    # TODO: Would this make a good function in other instances? Could be prettier though.
    # Run command until a certain file is created.
    command="java -jar $JD_HOME/JDownloader.jar -norestart"
    tmp_log="/tmp/jdownloader_install-${user}.log"

    echo_progress_start "Attempting jdownloader2 initialisation"
    while [ ! -e "$JD_HOME/build.json" ]; do
        touch "$tmp_log"
        echo_log_only "Oh shit here we go again"
        $command > "$tmp_log" 2>&1 &
        pid=$!
        trap "kill $pid 2> /dev/null" EXIT
        # While background command is still running...
        while kill -0 $pid 2> /dev/null; do
            # Pace out the fgrep by pausing for a second
            sleep 1
            # TODO: Some case handling would be good here.  (( My.Jdownloader login failed \\ first run finished \\ started successfully? ))
            # TODO: Another alternative could be to have it iterate a list of strings instead of being spread out like this.
            # If any of specified strings are found in the log, kill the last called background command.
            if grep -q "No Console Available!" -F "$tmp_log" || grep -q "Shutdown Hooks Finished" -F "$tmp_log" || grep -q -F "Initialisation finished" "$tmp_log"; then
                # Kill the background command
                kill $pid
                # Remove the tmp log
                rm $tmp_log
                # Disable the trap on a normal exit.
                trap - EXIT
            fi
        done
    done
    echo_progress_done "Initialisation concluded"

    chown -R "$user": "$JD_HOME"
    chmod 700 -R "$JD_HOME"

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
#shellcheck source=sources/functions/java
. /etc/swizzin/sources/functions/java
install_java8

_systemd() {

    # TODO: JDownloader's suggested service file uses a pidfile rather than an environment variable. Which is optimal?
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
}
_systemd

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
