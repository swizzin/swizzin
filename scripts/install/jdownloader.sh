#!/bin/bash
# JDownloader Installer for swizzin
# Author: Aethaeran

##########################################################################
# References
##########################################################################
# Liara already made a doc for installing JDownloader manually:
# https://docs.swizzin.net/guides/jdownloader/
# swizzin docs
# https://swizzin.ltd/dev/structure/
# Swizzin environment variables
# https://swizzin.ltd/guides/advanced-setup/
# JDownloader docs
# https://support.jdownloader.org/Knowledgebase/Article/View/install-jdownloader-on-nas-and-embedded-devices
# https://support.jdownloader.org/Knowledgebase/Article/View/headless-systemd-autostart-script
# https://board.jdownloader.org/showthread.php?t=81420
# Some of the logic used here
# https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian-10
# https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
# https://linuxize.com/post/bash-check-if-file-exists/
# https://superuser.com/questions/402979/kill-program-after-it-outputs-a-given-line-from-a-shell-script
# https://board.jdownloader.org/showthread.php?t=81433


##########################################################################
# Functions
##########################################################################

# TODO: Make $get_most_recent_dir_in_folder function
function get_most_recent_dir() {
    #shellcheck disable=2012
    ls -td -- "$1"/* | head -n 1
}
# TODO: Move this function to another file so the end user could use it to inject their details as well.

function get_myjd_info() {

    # TODO: The way this is currently handled causes information to be passed to EACH user that it is installed for.

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
        echo_info "Using password = $MYJD_PASSWORD"
    fi

    if [[ -z "${MYJD_DEVICENAME}" ]]; then
        echo_query "Please enter the desired device name"
        read -r 'MYJD_DEVICENAME'
    else
        echo_info "Using device name = $MYJD_DEVICENAME"
    fi

    mkdir -p "$JD_HOME/cfg"

    if [[ -e "$JD_HOME/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json" ]]; then
        rm "$JD_HOME/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json"
    fi

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
    # TODO: Should we move this to .config instead?
    $JD_HOME="/home/$user/jd2"

    if [[ $BYPASS_MYJDOWNLOADER == "false" ]]; then
        if ask "Do you want to inject MyJDownloader details for $user?" N; then
            inject="true"
            echo_info "Injecting MyJDownloader details for $user"
            get_myjd_info # Get account info for this user. and insert it into this installation
        else
            inject="false"
        fi
    fi

    # TODO: Have this store the first downloader JDownlaoder in /opt/jdownloader, all further instances can just copy it from there.
    # TODO: JDownloader will detect if JDownlaoder.jar is corrupt, we could use that to our advantage.
    echo_progress_start "Downloading JDownloader.jar"
    mkdir -p "$JD_HOME"
    if [[ ! -e "$JD_HOME/JDownloader.jar" ]]; then
        wget -q http://installer.jdownloader.org/JDownloader.jar -O "$JD_HOME/JDownloader.jar" || {
            echo_error "Failed to download"
            exit 1
        }
    fi
    echo_progress_done "Jar downloaded"

    command="java -jar $JD_HOME/JDownloader.jar -norestart"
    # TODO: The following line can probably use the most recent JDownloader log instead. /home/$user/jd2/logs/$get_most_recent_dir_in_folder/Log.L.log.0
    tmp_log="/tmp/jdownloader_install-${user}.log"
    echo $(get_most_recent_dir $JD_HOME/logs)

    # TODO: Currently, we need something here to disable all currently running JDownloader installations, or the MyJD verification logic will cause a loop. Would rather we didn't.
    for each_user in "${users[@]}"; do # disable all instances
        systemctl disable --now "jdownloader@$each_user" --quiet
    done

    echo_progress_start "Attempting JDownloader2 initialisation"
    end_loop="false"
    while [[ $end_loop == "false" ]]; do # Run command until a certain file is created.
        echo_info "Oh shit! Here we go again!" # TODO: This should be echo_log_only at PR end.
        if [[ -e "$tmp_log" ]]; then # Remove the tmp log if exists
            rm "$tmp_log"
        fi
        touch "$tmp_log" # Create the tmp log
        kill_process="false"
        $command > "$tmp_log" 2>&1 &
        pid=$!
        #shellcheck disable=SC2064
        trap "kill $pid 2> /dev/null" EXIT # Set trap to kill background process if this script ends.
        while kill -0 $pid 2> /dev/null; do # While background command is still running...
            sleep 2 # Pace this out a bit
            # If any of specified strings are found in the log, kill the last called background command.
            if [[ -e "$tmp_log" ]]; then # If the
                # TODO: Seems to be missing this detection if the background command closes too quickly. Increased previous sleep to 2 seconds to see if it helps.
                if grep -q "Create ExitThread" -F "$tmp_log"; then # JDownloader exited gracefully on it's own. Usually this will only happen first run.
                    echo_info "JDownloader exited gracefully." # TODO: This should be echo_log_only at PR end.
                    trap - EXIT   # Disable the trap on a normal exit.
                fi
                if grep -q "Initialisation finished" -F "$tmp_log"; then
                    echo_info "JDownloader started successfully." # TODO: This should be echo_log_only at PR end.

                    # Pretty sure this will remove the long pause.
                    keep_sleeping="true"
                    while [[ ! $keep_sleeping == "false" ]]; do
                        if [[ grep -q "No Console Available" -F "$tmp_log" || grep -q "Start HTTP Server" -F "$tmp_log" ]]; then
                            keep_sleeping="false"
                        else
                            sleep 1 # Wait until JDownloader has attempted launching the HTTP server.
                        fi
                    done

                    if grep -q "No Console Available" -F "$tmp_log"; then
                        echo_warn "MyJDownloader account details were incorrect. They won't be able to use the web UI."
                        if [[ $inject == "true" ]]; then
                            echo_info "Please enter the MyJDownloader details again."
                            get_myjd_info # Get account info for this user. and insert it into this installation
                        else
                            end_loop="true"
                        fi
                        kill_process="true"
                    fi
                    # This only works for verification if it is the first JDownloader instance to attempt connecting to MyJDownloader. I assume other instances use the same HTTP server.
                    if grep -q "Start HTTP Server" -F "$tmp_log"; then
                        echo_info "MyJDownloader account details verified."
                        kill_process="true"
                        end_loop="true"
                    fi
                fi
                if [[ $kill_process == "true" ]]; then
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

}

##########################################################################
# Script Main
##########################################################################

if [[ -n "$1" ]]; then # Install jd2 for user that was passed to script as arg (i.e. box adduser <user>) and do not execute the rest
    user="$1"
    install_jdownloader
    exit 0
fi

#shellcheck source=sources/functions/java
. /etc/swizzin/sources/functions/java
install_java8

_systemd() {
    # JDownloader will automatically create a pidfile when running. That way, systemd can use it to ensure it is disabling the correct process.
    cat > /etc/systemd/system/jdownloader@.service << EOF
[Unit]
Description=JDownloader Service
After=network.target

[Service]
User=%i
Group=%i
Environment=JD_HOME=/home/%i/jd2
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /home/%i/jd2/JDownloader.jar
PIDFile=/home/%i/jdownloader/JDownloader.pid

[Install]
WantedBy=multi-user.target
EOF
}
_systemd

# Add environment variable 'BYPASS_MYJDOWNLOADER' to bypass the following block. For unattended installs.
if [[ -n "${BYPASS_MYJDOWNLOADER}" ]]; then
    if ask "Do you want to add ANY MyJDownloader account information for users?\nIt is required for them to access the web UI." N; then
        BYPASS_MYJDOWNLOADER="false" # If no
    else
        BYPASS_MYJDOWNLOADER="true" # If yes
    fi
fi

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do # Install a separate instance for each user
    install_jdownloader
done
# Don't start services until after each user is installed.
for user in "${users[@]}"; do # Install a separate instance for each user
    echo_progress_start "Enabling service jdownloader@$user"
    systemctl enable -q --now jdownloader@"$user" --quiet
    echo_progress_done
done

touch /install/.jdownloader.lock
echo_success "JDownloader installed"
