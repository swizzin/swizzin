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

function install_jdownloader() {

    echo_info "Setting up JDownloader for $user"

    # TODO: Should double check to confirm everything is accurate, and loop back if anything isn't filled out. swizzin likely has utils for this already
    # TODO: Add environment variable that will allow for this to be bypassed?
    echo_info "An account from https://my.jdownloader.org/ is required in order to access the web UI.\nUse a randomly generated password at registration as the password is stored in plain text."
    echo_query "Please enter the e-mail used to access this account once created:"
    read -r 'myjd_email'
    echo_query "Please enter the password for the account."
    read -r 'myjd_password'
    echo_query "Please enter the desired device name"
    read -r 'myjd_devicename'

    JD_HOME="/home/$user/jd2"
    mkdir -p "$JD_HOME/cfg"

    cat > "$JD_HOME/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json" << EOF
{
    "email" : "$myjd_email",
    "password" : "$myjd_password",
    "devicename" : "$myjd_devicename"
}
EOF

    echo_progress_start "Downloading JDownloader.jar."
    if [[ ! -e "$JD_HOME/JDownloader.jar" ]]; then
        wget -q http://installer.jdownloader.org/JDownloader.jar -O "$JD_HOME/JDownloader.jar" || {
            echo_error "Failed to download"
            exit 1
        }
    fi
    echo_progress_done "Jar downloaded"

    # TODO: Would this make a good function in other instances? Could be prettier though.
    command="java -jar $JD_HOME/JDownloader.jar -norestart"
    tmp_log="/tmp/jdownloader_install-${user}.log"

    echo_progress_start "Attempting jdownloader2 initialisation"
    while [ ! -e "$JD_HOME/build.json" ]; do # Run command until a certain file is created.

        touch "$tmp_log"
        echo_log_only "Oh shit here we go again"
        $command > "$tmp_log" 2>&1 &
        pid=$!
        trap "kill $pid 2> /dev/null" EXIT
        while kill -0 $pid 2> /dev/null; do # While background command is still running...

            sleep 1 # Pace out the fgrep by pausing for a second

            # TODO: Some case handling would be good here.  (( My.Jdownloader login failed \\ first run finished \\ started successfully? ))
            # TODO: Another alternative could be to have it iterate a list of strings instead of being spread out like this.

            # If any of specified strings are found in the log, kill the last called background command.
            if grep -q "No Console Available!" -F "$tmp_log" || grep -q "Shutdown Hooks Finished" -F "$tmp_log" || grep -q -F "Initialisation finished" "$tmp_log"; then
                kill $pid     # Kill the background command
                rm "$tmp_log" # Remove the tmp log
                trap - EXIT   # Disable the trap on a normal exit.

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

if [[ -n "$1" ]]; then # Install jd2 for user that was passed to script as arg (i.e. box adduser <user>) and do not execute the rest
    user="$1"
    install_jdownloader
    exit 0
fi

#shellcheck source=sources/functions/java
. /etc/swizzin/sources/functions/java
install_java8

_systemd() {
    # TODO: JDownloader's suggested service file uses a pidfile rather than an environment variable. Which is optimal?
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
    # Service starting is handled in per-user installer
}
_systemd

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do # Install a separate instance for each user
    install_jdownloader
done

touch /install/.jdownloader.lock
echo_success "JDownloader installed"
