groupadd -fg 84 avahi || true
useradd -c "Avahi Daemon Owner" -d /var/run/avahi-daemon -u 84 \
        -g avahi -s /bin/false avahi || true

groupadd -fg 86 netdev || true

