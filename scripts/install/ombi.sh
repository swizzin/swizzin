#!/bin/bash
# Ombi installer
# Swizzin gplv3 and all that

function _sources() {
    echo_progress_start "Installing ombi apt sources"
    if [[ "$(_os_distro)" == "debian" ]] && [[ "$(_os_codename)" == "trixie" ]]; then
        # The repo metadata IS signed (InRelease uses SHA-256), but apt on trixie verifies
        # via Sequoia (sqv) instead of gpgv, and Ombi's signing key 028C9194...FAB76C28
        # carries a SHA-1 self-certification. Debian's crypto policy rejects SHA-1 binding
        # signatures from 2026-02-01, so sqv refuses the key itself and signed-by fails with
        # "Signing key ... is not bound". Nothing on our side can repair the upstream key,
        # so fall back to an unverified repo here until Ombi re-signs it.
        echo "deb [trusted=yes] https://apt.ombi.app/master jessie main" > /etc/apt/sources.list.d/ombi.list
        echo_warn "Ombi's apt key uses a SHA-1 self-signature that Debian trixie rejects; installing from this repo WITHOUT signature verification."
    else
        echo "deb [signed-by=/usr/share/keyrings/ombi-archive-keyring.gpg] https://apt.ombi.app/master jessie main" > /etc/apt/sources.list.d/ombi.list
        curl -s https://apt.ombi.app/pub.key | gpg --dearmor > /usr/share/keyrings/ombi-archive-keyring.gpg 2>> ${log}
    fi
    echo_progress_done "Sources installed"
    apt_update
}

function _install() {
    echo_progress_start "Installing Ombi runtime dependencies"
    icu_pkg="$(apt-cache search '^libicu[0-9]+$' | awk '{print $1}' | sort -Vr | sed -n '1p')"
    if [[ -n "${icu_pkg}" ]]; then
        apt_install "${icu_pkg}"
    else
        # Fallback for older or unusual apt metadata where versioned runtime package is not listed.
        apt_install libicu-dev
    fi
    echo_progress_done "Dependencies installed"

    # Ombi's postinst chowns /opt/Ombi/ClientApp/dist/index.html, but since the Angular
    # build output moved under dist/browser/ the package no longer ships that path. The
    # chown then fails, the postinst aborts under `set -e`, and dpkg is left with ombi
    # half-configured -- which makes every later apt call on the box fail too.
    # Pre-create the path so configure succeeds, then point it at the real file.
    mkdir -p /opt/Ombi/ClientApp/dist
    [[ -e /opt/Ombi/ClientApp/dist/index.html ]] || touch /opt/Ombi/ClientApp/dist/index.html

    apt_install ombi

    # The deb's postinst runs `deb-systemd-invoke start ombi.service`, so Ombi is already
    # running and part-way through creating its SQLite databases. Everything below (and the
    # nginx step) rewrites the unit and bounces the service, and an interrupted first run
    # leaves OmbiSettings.db with the migration recorded in __EFMigrationsHistory but its
    # tables never created -- after which every start aborts with
    # "no such table: ApplicationConfiguration". Stop it and discard those partial databases
    # so the single start at the end of this installer migrates from scratch.
    systemctl stop -q ombi 2> /dev/null
    rm -f /etc/Ombi/Ombi.db /etc/Ombi/OmbiSettings.db /etc/Ombi/*.db-shm /etc/Ombi/*.db-wal

    if [[ -f /opt/Ombi/ClientApp/dist/browser/index.html ]]; then
        ln -sf browser/index.html /opt/Ombi/ClientApp/dist/index.html
    fi

    mkdir -p /etc/systemd/system/ombi.service.d
    cat > /etc/systemd/system/ombi.service.d/override.conf << CONF
[Service]
ExecStart=
ExecStart=/opt/Ombi/Ombi --host http://0.0.0.0:3000 --storage /etc/Ombi
CONF
    systemctl daemon-reload
    # Deliberately not started here. The nginx step below rewrites this override and
    # stops/starts ombi; interrupting Ombi's first run leaves OmbiSettings.db with the
    # migration recorded in __EFMigrationsHistory but its tables never created, and every
    # later start then aborts with "no such table: ApplicationConfiguration". Start once,
    # after the final ExecStart is in place.
    systemctl enable -q ombi
}

function _nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /usr/local/bin/swizzin/nginx/ombi.sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "Ombi is accessible under port 3000"
    fi

}

function _start() {
    echo_progress_start "Starting Ombi"
    systemctl start -q ombi
    # First run creates and migrates the SQLite databases, which takes a few seconds.
    # Block until it is actually serving so nothing downstream restarts it mid-migration.
    for _ in $(seq 1 60); do
        ss -tln 2> /dev/null | grep -q ':3000' && break
        sleep 1
    done
    if ss -tln 2> /dev/null | grep -q ':3000'; then
        echo_progress_done "Ombi started"
    else
        echo_warn "Ombi did not start listening on port 3000; check 'journalctl -u ombi'"
    fi
}

_sources
_install
_nginx
_start
touch /install/.ombi.lock
echo_success "Ombi installed"
echo_info "Please continue setting up your administrator user through the browser"
