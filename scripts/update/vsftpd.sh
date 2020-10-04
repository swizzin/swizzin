if [[ -f /install/.vsftpd.lock ]]; then
    . /etc/swizzin/sources/functions/letsencrypt
    le_vsftpd_hook
fi