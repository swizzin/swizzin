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
# Import Sources
##########################################################################

. /etc/swizzin/sources/functions/java
. /etc/swizzin/sources/functions/jdownloader
. /etc/swizzin/sources/functions/utils

##########################################################################
# Functions
##########################################################################

function install_jdownloader() {

    echo_info "Setting up JDownloader for $user"
    JD_HOME="/home/$user/jd2"
    mkdir -p "$JD_HOME"

    # TODO: Test environment variable 'MYJD_BYPASS' to bypass the following block. For unattended installs.
    if [[ ! -z $MYJD_BYPASS ]]; then
        if ask "Do you want to inject MyJDownloader details for $user?" N; then
            inject="true"
            echo_info "Injecting MyJDownloader details for $user"
            inject_myjdownloader # Get account info for this user. and insert it into this installation
        else
            inject="false"
        fi
    else
        echo_info "Bypassing MyJDownloader detail entering because of unattended variable."
    fi

    echo_progress_start "Downloading JDownloader.jar..."
    while [[ ! -e "/tmp/JDownloader.jar" ]]; do
        if wget -q http://installer.jdownloader.org/JDownloader.jar -O "/tmp/JDownloader.jar"; then
            echo_info "Jar downloaded..."
            if ! java -jar "/tmp/JDownloader.jar" 2>/dev/null;then # Java will detect if a .jar is corrupt
                echo_info ".jar is corrupt. Removing, and trying again."
                rm "/tmp/JDownloader.jar"
            else
                echo_info ".jar is valid."
            fi
        else
            echo_error "Failed to download"
        fi
    done

    echo_progress_done "JDownloader.jar downloaded."

    if [[ ! -e "$JD_HOME/JDownloader.jar" ]]; then
        cp "/tmp/JDownloader.jar" "$JD_HOME/JDownloader.jar"
    fi

    # TODO: Currently, we need something here to disable all currently running JDownloader installations, or the MyJD verification logic will cause a loop. Would rather we didn't.
    for each_user in "${users[@]}"; do # disable all instances
        systemctl disable --now "jdownloader@$each_user" --quiet
    done

    # TODO: Figure out if this would be a WHOLE lot simpler if I didn't run the `-norestart` flag *facepalm*
    command="java -jar $JD_HOME/JDownloader.jar -norestart"

    echo_progress_start "Attempting JDownloader2 initialisation"
    end_initialisation_loop="false"
    while [[ $end_initialisation_loop == "false" ]]; do # Run command until a certain file is created.
        echo_info "Running temporary JDownloader process..." # TODO: This should be echo_log_only at PR end.
        if [[ -e "$tmp_log" ]]; then # Remove the tmp log if exists
            rm "$tmp_log"
        fi
        if [[ -e "$JD_HOME"/logs ]]; then
            tmp_log="$(get_most_recent_dir "$JD_HOME"/logs)/Log.L.log.0"
            $command >"$tmp_log" 2>&1 &
        else
            $command >"/dev/null" 2>&1 &
        fi
        kill_process="false"
        pid=$!
        #shellcheck disable=SC2064
        trap "kill $pid 2> /dev/null" EXIT # Set trap to kill background process if this script ends.
        process_died="false"
        while [[ $process_died == "false" ]]; do # While background command is still running...

            echo_info "Background command is still running..." # TODO: This should be removed at PR end.
            sleep 1 # Pace this out a bit, no need to check what JDownloader is doing more frequently than this.
            # If any of specified strings are found in the log, kill the last called background command.
            if [[ -e "$tmp_log" ]]; then

                if grep -q "Create ExitThread" -F "$tmp_log"; then # JDownloader exited gracefully on it's own. Usually this will only happen first run.
                    echo_info "JDownloader exited gracefully." # TODO: This should be echo_log_only at PR end.
                fi

                if grep -q "Initialisation finished" -F "$tmp_log"; then #
                    echo_info "JDownloader started successfully." # TODO: This should be echo_log_only at PR end.

                    # Pretty sure this will remove the long pause.
                    keep_sleeping="true"
                    while [[ ! $keep_sleeping == "false" ]]; do
                        if grep -q "No Console Available" -F "$tmp_log" || grep -q "Start HTTP Server" -F "$tmp_log"; then
                            keep_sleeping="false"
                        else
                            sleep 1 # Wait until JDownloader has attempted launching the HTTP server.
                        fi
                    done

                    if grep -q "No Console Available" -F "$tmp_log"; then
                        echo_warn "MyJDownloader account details were incorrect. They won't be able to use the web UI."
                        if [[ $inject == "true" ]]; then
                            echo_info "Please enter the MyJDownloader details again."
                            inject_myjdownloader # Get account info for this user. and insert it into this installation
                        else
                            end_initialisation_loop="true"
                        fi
                        kill_process="true"
                    fi

                    # This only works for verification if it is the first JDownloader instance to attempt connecting to MyJDownloader. I assume other instances use the same HTTP server.

                    if grep -q "Start HTTP Server" -F "$tmp_log"; then
                        echo_info "MyJDownloader account details verified."
                        kill_process="true"
                        end_initialisation_loop="true"
                    fi

                fi
            fi

            if kill -0 $pid 2>/dev/null; then
                if [[ $kill_process == "true" ]]; then
                    echo_info "Kill JDownloader..." # TODO: This should be echo_log_only at PR end.
                    kill $pid     # Kill the background command
                    sleep 1       # Give it a second to actually die.
                    process_died="true"
                fi
            else
                echo_info "Background command died without being killed." # TODO: This should be echo_log_only at PR end.
                process_died="true"
            fi

        done
        trap - EXIT   # Disable the trap on a normal exit.
    done
    echo_progress_done "Initialisation concluded"

    chown -R "$user": "$JD_HOME" # Set owner on JDownloader folder.
    chmod 700 -R "$JD_HOME"      # Set permissions on JDownloader folder.

}

_systemd() {
    # JD_HOME should be setting the working directory for this instance of JDownloader.
    # JDownloader will automatically create a pid file when running. That way, systemd can use it to ensure it is disabling the correct process.
    cat >/etc/systemd/system/jdownloader@.service <<EOF
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

##########################################################################
# Script Main
##########################################################################

if [[ -n "$1" ]]; then # Install JDownloader for JUST the user that was passed to script as arg (i.e. box adduser $user)
    user="$1"
    install_jdownloader
    exit 0
fi

install_java8 # Install Java as it is a dependency.

readarray -t users < <(_get_user_list) # Install a separate JDownloader instance for each user
for user in "${users[@]}"; do
    install_jdownloader
done

_systemd # Insert service file to /etc/systemd/system

# Don't start services until after each user is installed. Due to current verification process.
for user in "${users[@]}"; do # Enable a separate service for each swizzin user
    echo_progress_start "Enabling service jdownloader@$user"
    systemctl enable -q --now jdownloader@"$user" --quiet
    echo_progress_done
done

touch /install/.jdownloader.lock # Create lock file so that swizzin knows JDownloader is installed.
echo_success "JDownloader installed" # Winner winner. Chicken dinner.
