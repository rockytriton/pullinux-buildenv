cat >> /etc/ld.so.conf << EOF
# Begin rustc addition

/opt/rustc/lib

# End rustc addition
EOF

ldconfig

cat > /etc/profile.d/rustc.sh << "EOF"
# Begin /etc/profile.d/rustc.sh

pathprepend /opt/rustc/bin           PATH

# Include /opt/rustc/man in the MANPATH variable to access manual pages
pathappend  /opt/rustc/share/man     MANPATH

# End /etc/profile.d/rustc.sh
EOF

source /etc/profile.d/rustc.sh
