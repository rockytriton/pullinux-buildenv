useradd -c "Print Service User" -d /var/spool/cups -g lp -s /bin/false -u 9 lp || true

groupadd -g 19 lpadmin || true

gtk-update-icon-cache -qtf /usr/share/icons/hicolor
