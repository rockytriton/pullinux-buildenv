install  -v -m700 -d /var/lib/sshd || true 
chown    -v root:sys /var/lib/sshd || true

groupadd -g 50 sshd        || true
useradd  -c 'sshd PrivSep' \
         -d /var/lib/sshd  \
         -g sshd           \
         -s /bin/false     \
         -u 50 sshd || true

