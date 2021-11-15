#!/bin/bash
#################################################################################
# Installation script for swizzin
# Many credits to QuickBox for the package repo
#
# Package installers copyright QuickBox.io (2017) where applicable.
# All other work copyright Swizzin (2017)
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

echo "Starting Swizzin installation"

if [[ $EUID -ne 0 ]]; then
    echo "Swizzin setup requires user to be root. su or sudo -s and run again ..."
    exit 1
fi

export log=/root/logs/swizzin.log
mkdir -p /root/logs
touch $log

# Setting up /etc/swizzin
#shellcheck disable=SC2120
function _source_setup() {
    echo -e "...\tInstalling git"      # The one true dependency
    apt-get update -q >> $log 2>&1     # Force update just in case sources were never pulled
    apt-get install git -y -qq >> $log # DO NOT PUT MORE DEPENDENCIES HERE
    echo -e "\tGit Installed"          # All dependencies go to scripts/update/10-dependencies.sh

    if [[ "$*" =~ '--local' ]]; then
        RelativeScriptPath=$(dirname "${BASH_SOURCE[0]}")
        if [[ ! -e /etc/swizzin ]]; then # If there is no valid file or dir there...
            ln -sr "$RelativeScriptPath" /etc/swizzin
            echo "The directory where the setup script is located is symlinked to /etc/swizzin"
        else
            touch /etc/swizzin/.dev.lock
            echo "/etc/swizzin/.dev.lock created"
        fi
        echo "Best of luck and please follow the contribution guidelines cheerio"
    else
        echo -e "...\tCloning swizzin repo to localhost"
        git clone https://github.com/swizzin/swizzin.git /etc/swizzin >> ${log} 2>&1
        echo -e "\tSwizzin cloned!"
    fi

    ln -s /etc/swizzin/scripts/ /usr/local/bin/swizzin
    #shellcheck source=sources/globals.sh
    . /etc/swizzin/sources/globals.sh

    # Set correct permissions on swizzin files
    bash /etc/swizzin/scripts/update/04-setpermissions.sh
    echo
}
_source_setup "$@"

function _arch_check() {
    if [[ ! $(uname -m) =~ ("x86_64"|"aarch64") ]]; then
        echo_warn "$(_os_arch) detected!"
        echo_warn "This is an unsupported architecture and THINGS MIGHT BREAK.\nDO NOT CREATE ISSUES ON GITHUB."
        ask "Agree with the above and continue?" N || exit 1
        echo
    else
        echo_log_only "Arch detected as $(_os_arch)"
    fi
}
_arch_check
function _option_parse() {
    while test $# -gt 0; do
        case "$1" in
            --user)
                shift
                user="$1"
                echo_info "User = $user"
                ;;
            --pass | --password)
                shift
                pass="$1"
                echo -e "\tPass = $pass" #Not an echo_info as we don't want this to hit the logs
                ;;
            --skip-cracklib)
                if check_installed libpam-cracklib; then
                    echo_warn "Can't skip password check as libpam-cracklib is installed"
                else
                    export SKIPCRACKLIB=true
                    echo_info "Cracklib will be skipped"
                fi
                ;;
            --domain)
                shift
                export LE_HOSTNAME="$1"
                export LE_DEFAULTCONF=yes
                export LE_BOOL_CF=no
                echo_info "Domain = $LE_HOSTNAME, Used in default nginx config = $LE_DEFAULTCONF"
                ;;
            --local)
                LOCAL=true
                echo_info "Local = $LOCAL"
                ;;
            --test)
                export test=true
                echo_info "test = $test"
                ;;
            --rmgrsec)
                rmgrsec=yes
                echo_info "OVH Kernel nuke = $rmgrsec"
                ;;
            --env)
                shift
                if [[ ! -f $1 ]]; then
                    echo_error "File does not exist"
                    exit 1
                fi
                envfile="$1"
                echo_info "Parsing env variables from $envfile:\n$(grep -v '^#' "$envfile")"

                # anything which begins with a cap is exported
                if grep -v '^#' "$envfile" | grep '^[A-Z]' -q; then
                    export $(grep -v '^#' "$envfile" | grep '^[A-Z]' | tr '\n' ' ')
                fi

                # anything with a lowercase will get sourced
                if grep -v '^#' "$envfile" | grep '^[a-z]' -q; then
                    source <(grep -v '^#' "$envfile" | grep '^[a-z]') # | read -d $'\x04' name -
                fi

                # If packages were in env, make the installArray
                if [[ -n $packages ]]; then
                    readarray -td: installArray < <(printf '%s' "$packages")
                fi
                unattend=true
                export SKIPCRACKLIB=true
                ;;
            --unattend)
                unattend=true
                ;;
            --post-command)
                shift
                postcommand="$1"
                echo_info "Post-install command = \"$postcommand\""
                ;;
            -*)
                echo_error "Error: Invalid option: $1"
                exit 1
                ;;
            *)
                installArray+=("$1")
                ;;
        esac
        shift
    done

    if [[ -z $pass && "${pass+x}" ]]; then # Generate a password if it is specifically empty
        pass="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)"
        echo_info "Generating random password"
        echo -e "\tPass = $pass"
    fi

    if [[ $unattend = "true" ]]; then
        # hushes errors that happen when no package is being
        touch /root/results
        touch /root/results2
    fi

    if [[ ${#installArray[@]} -gt 0 ]]; then
        echo_info "Application install picker will be skipped"
        priority=(nginx rtorrent deluge qbittorrent)
        for i in "${installArray[@]}"; do
            #shellcheck disable=SC2199,SC2076
            if [[ " ${priority[@]} " =~ " ${i} " ]]; then
                echo "$i" >> /root/results
                echo_log_only "$i added to install queue 1"
                touch /tmp/."$i".lock
            else
                echo "$i" >> /root/results2
                echo_log_only "$i added to install queue 2"
            fi
        done
    fi
}
_option_parse "$@"

_os() {
    if [ ! -d /install ]; then mkdir /install; fi
    if [ ! -d /root/logs ]; then mkdir /root/logs; fi
    if ! which lsb_release > /dev/null; then
        echo -e "...\tInstalling lsb-release"      # Okay MAYBE there's one more depend until we gut this app in favour of /etc/os-release
        apt-get install lsb-release -y -qq >> $log # DO NOT PUT MORE DEPENDENCIES HERE
    fi
    distribution=$(lsb_release -is)
    codename=$(lsb_release -cs)
    if [[ ! $distribution =~ ^(Debian|Ubuntu)$ ]]; then
        echo_error "Your distribution ($distribution) is not supported. Swizzin requires Ubuntu or Debian."
        exit 1
    fi
    if [[ ! $codename =~ ^(bionic|stretch|buster|focal|bullseye)$ ]]; then
        echo_error "Your release ($codename) of $distribution is not supported."
        exit 1
    fi
}

function _preparation() {
    echo_info "Preparing system"
    apt-get install uuid-runtime -yy >> $log 2>&1
    apt_update # Do this because sometimes the system install is so fresh it's got a good stam but it is "empty"
    apt_upgrade

    if ! bash /etc/swizzin/scripts/update/10-dependencies.sh; then
        echo_error "Dependencies failed to install\nPlease reveiw the log file and try again.\nFeel free to visit our Discord in case you need assistance."
        exit 1
    fi

    nofile=$(grep "DefaultLimitNOFILE=500000" /etc/systemd/system.conf)
    if [[ ! "$nofile" ]]; then echo "DefaultLimitNOFILE=500000" >> /etc/systemd/system.conf; fi
    echo_progress_done "Setup succesful"
    echo
}

#FYI code duplication from `box rmgrsec`
function _nukeovh() {
    bash /etc/swizzin/scripts/nukeovh
}

function _intro() {
    whiptail --title "Swizzin seedbox installer" --msgbox "Yo, what's up? Let's install this swiz." 7 43
}

function _adduser() {
    echo_info "Creating master user"
    export SETUP_USER=true                                     # This sets whiptail in box adduser
    bash /etc/swizzin/scripts/box adduser "$user" "$pass" || { # TODO make it so that the password does not hit the logs
        echo_error "Installation aborted!"
        exit 1
    }
    unset SETUP_USER
    pass=
    unset pass
    echo_log_only "User initialised"
}

function _choices() {
    packages=()
    extras=()
    guis=()
    locks=(nginx rtorrent deluge qbittorrent autodl panel vsftpd ffmpeg quota transmission)
    for i in "${locks[@]}"; do
        app=${i}
        if [[ ! -f /install/.$app.lock ]]; then
            packages+=("$i" '""')
        fi
    done
    whiptail --title "Install Software" --checklist --noitem --separate-output "Choose your clients and core features." 15 26 7 "${packages[@]}" 2> /root/results || exit 1
    results=/root/results
    if grep -q rtorrent "$results"; then
        gui=(rutorrent flood)
        for i in "${gui[@]}"; do
            app=${i}
            if [[ ! -f /install/.$app.lock ]]; then
                guis+=("$i" '""')
            fi
        done
        whiptail --title "rTorrent GUI" --checklist --noitem --separate-output "Optional: Select a GUI for rtorrent" 15 26 7 "${guis[@]}" 2> /root/guis || exit 1
        readarray guis < /root/guis
        for g in "${guis[@]}"; do
            g=$(echo $g)
            sed -i "/rtorrent/a $g" /root/results
        done
        rm -f /root/guis
    fi
    while IFS= read -r result; do
        touch /tmp/.$result.lock
    done < "$results"

    locksextra=($(find /usr/local/bin/swizzin/install -type f -printf "%f\n" | cut -d "." -f 1 | sort -d))
    for i in "${locksextra[@]}"; do
        app=${i}
        if [[ ! -f /tmp/.$app.lock ]]; then
            extras+=("$i" '""')
        fi
    done
    whiptail --title "Install Software" --checklist --noitem --separate-output "Make some more choices ^.^ Or don't. idgaf" 15 26 7 "${extras[@]}" 2> /root/results2 || exit 1
}

function _check_results() {
    results=/root/results
    if grep -q nginx "$results"; then
        if [[ -n $(pidof apache2) ]]; then
            if (whiptail --title "apache2 conflict" --yesno --yes-button "Purge it!" --no-button "Disable it" "WARNING: The installer has detected that apache2 is already installed. To continue, the installer must either purge apache2 or disable it." 8 78); then
                export apache2=purge
            else
                export apache2=disable
            fi
        fi
    fi
    if grep -q rtorrent "$results"; then
        . /etc/swizzin/sources/functions/rtorrent
        whiptail_rtorrent
    fi
    if grep -q deluge "$results"; then
        . /etc/swizzin/sources/functions/deluge
        whiptail_deluge
    fi
    if grep -q qbittorrent "$results"; then
        . /etc/swizzin/sources/functions/qbittorrent
        whiptail_qbittorrent
    fi
    if grep -q transmission "$results"; then
        #shellcheck source=sources/functions/transmission
        . /etc/swizzin/sources/functions/transmission
        whiptail_transmission_source
    fi

    if [[ $(grep -s rutorrent "$gui") ]] && [[ ! $(grep -s nginx "$results") ]]; then # Check nginx requirement for more than rutorrent
        if (whiptail --title "nginx conflict" --yesno --yes-button "Install nginx" --no-button "Remove ruTorrent" "WARNING: The installer has detected that ruTorrent is to be installed without nginx. To continue, the installer must either install nginx or remove ruTorrent from the packages to be installed." 8 78); then
            sed -i '1s/^/nginx\n/' /root/results
            touch /tmp/.nginx.lock
        else
            sed -i '/rutorrent/d' /root/results
        fi
    fi
}

function _prioritize_results() {
    if grep -q nginx "$results"; then
        sed -i '/nginx/d' /root/results
        echo "" >> /root/results
        sed -i '1s/^/nginx\n/' /root/results
    fi
}

function _install() {
    begin=$(date +"%s")
    if [[ -s /root/results ]]; then
        bash /etc/swizzin/scripts/box install $(< /root/results) && rm /root/results
        showTimer=true
    fi
    if [[ -s /root/results2 ]]; then
        bash /etc/swizzin/scripts/box install $(< /root/results2) && rm /root/results2
        showTimer=true
    fi
    termin=$(date +"%s")
    difftimelps=$((termin - begin))
    [[ $showTimer = true ]] && echo_info "Package installation took $((difftimelps / 60)) minutes and $((difftimelps % 60)) seconds"
}

function _post() {
    echo
    echo

    user=$(_get_master_username)

    ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
    if ! grep -q -ow '^export PATH=$PATH:/usr/local/bin/swizzin$' ~/.bashrc; then
        echo "export PATH=\$PATH:/usr/local/bin/swizzin" >> /root/.bashrc
    fi
    #echo "export PATH=\$PATH:/usr/local/bin/swizzin" >> /home/$user/.bashrc
    #chown ${user}: /home/$user/.profile
    echo "Defaults    secure_path = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/swizzin" > /etc/sudoers.d/secure_path
    if [[ $distribution = "Ubuntu" ]]; then
        echo 'Defaults  env_keep -="HOME"' > /etc/sudoers.d/env_keep
    fi

    ring_the_bell
    echo_success "Swizzin installation complete!"
    if [[ -f /install/.nginx.lock ]]; then
        echo_info "Seedbox can be accessed at https://${user}@${ip}"
    fi

    if [[ -f /install/.deluge.lock ]]; then
        delugewebport=$(grep port /home/"${user}"/.config/deluge/web.conf | cut -d: -f2 | cut -d"," -f1)
        delugedaemonport=$(grep daemon_port /home/"${user}"/.config/deluge/core.conf | cut -d: -f2 | cut -d"," -f1)
        echo_info "Your deluge daemon port is $delugedaemonport\nYour deluge web port is $delugewebport"
    fi

    if [[ -f /var/run/reboot-required ]]; then
        echo_warn "The server requires a reboot to finalise this installation. Please reboot now."
    else
        echo_info "You can now use the box command to manage swizzin features, e.g. \`box install nginx panel\`"
    fi
    echo_docs getting-started/box-basics
    #
    # Run the bash_completion installer from the update folder
    bash /etc/swizzin/scripts/update/bash_completion.sh
}

_run_tests() {
    if [[ $test = "true" ]] || [ -f /etc/swizzin/.test.lock ]; then
        bash /etc/swizzin/scripts/box test || return 1
    fi

}

_run_post() {
    if [[ -z $postcommand ]]; then
        echo_progress_start "Executing post-install commands"
        $postcommand
        echo_progress_done "Post-install commands finished"
    fi
}

_os
_preparation
## If install is attended, do the nice intro
if [[ $unattend != "true" ]]; then
    if [[ -z "$user" ]] && [[ -z "$pass" ]]; then # If password AND username are empty
        _intro
    fi
fi

## If the user asked for rmgrsec or the install is not being attended, get into the kernel business
if [[ -n $rmgrsec ]] || [[ $unattend != "true" ]]; then _nukeovh; fi
_adduser
#If setup is attended and there are no choices, go get some apps
if [[ $unattend != "true" ]] && [[ ${#installArray[@]} -eq 0 ]]; then _choices; fi
_check_results
_prioritize_results
_install
_post
_run_post
_run_tests || exit 1
