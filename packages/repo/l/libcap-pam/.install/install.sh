mv -v /etc/pam.d/system-auth{,.bak} &&
cat > /etc/pam.d/system-auth << "EOF" &&
# Begin /etc/pam.d/system-auth

auth      optional    pam_cap.so
EOF

tail -n +3 /etc/pam.d/system-auth.bak >> /etc/pam.d/system-auth

