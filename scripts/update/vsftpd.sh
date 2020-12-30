if islocked "vsftpd"; then
    . /etc/swizzin/sources/functions/letsencrypt
    le_vsftpd_hook
fi
