set -e

echo "Creating PLX user for ${PLX:?}"

groupadd plx || echo "plx group exists"
useradd -s /bin/bash -g plx -m -k /dev/null plx || echo "plx user exists"
passwd plx

HM=$(eval echo ~plx)

cat > $HM/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > $HM/.bashrc << EOF
set +h
umask 022
PLX=$PLX
EOF

cat >> $HM/.bashrc << "EOF"
LC_ALL=POSIX
PLX_TGT=$(uname -m)-plx-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$PLX/tools/bin:$PATH
CONFIG_SITE=$PLX/usr/share/config.site
export PLX LC_ALL PLX_TGT PATH CONFIG_SITE
export MAKEFLAGS="-j$(nproc)"
EOF
