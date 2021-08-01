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

function get_myjd_info() {

    # TODO: Give the option to skip this, and have user do it manually later.
    # TODO: Should double check to confirm everything is accurate, and loop back if anything isn't filled out. swizzin likely has utils for this already

    echo_info "An account from https://my.jdownloader.org/ is required in order to access the web UI.\nUse a randomly generated password at registration as the password is stored in plain text"
    if [[ -z "${MYJD_EMAIL}" ]]; then
        echo_query "Please enter the e-mail used to access this account once created:"
        read -r 'MYJD_EMAIL'
    else
        echo_info "Using email = $MYJD_EMAIL"
    fi

    if [[ -z "${MYJD_PASSWORD}" ]]; then
        echo_query "Please enter the password for the account"
        read -r 'MYJD_PASSWORD'
    else
        echo_info "Using password = $MYJD_EMAIL"
    fi

    if [[ -z "${MYJD_DEVICENAME}" ]]; then
        echo_query "Please enter the desired device name"
        read -r 'MYJD_DEVICENAME'
    else
        echo_info "Using device name = $MYJD_DEVICENAME"
    fi

    mkdir -p "$JD_HOME/cfg"
    cat > "$JD_HOME/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json" << EOF
{
    "email" : "$MYJD_EMAIL",
    "password" : "$MYJD_PASSWORD",
    "devicename" : "$MYJD_DEVICENAME"
}
EOF
}

function install_jdownloader() {

    echo_info "Setting up JDownloader for $user"
    JD_HOME="/home/$user/jd2"

    get_myjd_info # Get account info for this user. and insert it into this installation

    echo_progress_start "Downloading JDownloader.jar"
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

    echo_progress_start "Attempting JDownloader2 initialisation"
    while [ ! -e "$JD_HOME/build.json" ]; do # Run command until a certain file is created.
        touch "$tmp_log"
        echo_log_only "Oh shit here we go again"
        $command > "$tmp_log" 2>&1 &
        pid=$!
        #shellcheck disable=SC2064
        trap "kill $pid 2> /dev/null" EXIT
        while kill -0 $pid 2> /dev/null; do # While background command is still running...

            # TODO: Some case handling would be good here.  (( My.Jdownloader login failed \\ first run finished \\ started successfully? ))
            # TODO: Another alternative could be to have it iterate a list of strings instead of being spread out like this.

            kill_me="false"
            # If any of specified strings are found in the log, kill the last called background command.
            if [[ -e "$tmp_log" ]]; then # If the
                if grep -q "Shutdown Hooks Finished" -F "$tmp_log"; then # JDownloader exited gracefully on it's own. Usually this will only happen first run.
                    echo_info "JDownloader exited gracefully."
                fi
                if grep -q "Initialisation finished" -F "$tmp_log"; then #
                    echo_info "JDownloader started successfully."
                    if grep -q "No Console Available" -F "$tmp_log"; then # I believe this only happens when MyJD details are incorrect. If so, we can use this to verify the details were correct.
                        echo_error "https://my.jdownloader.org/ account details were incorrect. Try again."
                        # TODO: Give the option to skip this, and have user do it manually later.
                        kill_me="true"
                        find "$JD_HOME" -type f -not -name 'JDownloader.jar' -print0 | xargs -0  -I {} rm {} # Remove anything that isn't JDownloader.jar
                        get_myjd_info # Get account info for this user. and insert it into this installation
                    fi
                fi
                if [[ "$kill_me" = "true" ]]; then
                    kill $pid     # Kill the background command
                    rm "$tmp_log" # Remove the tmp log
                    trap - EXIT   # Disable the trap on a normal exit.
                fi
            fi
            sleep 1 # Pace out the grep by pausing for a second
        done
    done
    echo_progress_done "Initialisation concluded"

    chown -R "$user": "$JD_HOME" # Set owner on JDownloader folder.
    chmod 700 -R "$JD_HOME" # Set permissions on JDownloader folder.

    echo_progress_start "Enabling service jdownloader@$user"
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
