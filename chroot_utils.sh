#!/bin/bash

export PLX="/"
export DL_PATH=/build/dl
export SRC_PATH=/build/src
export STAT_PATH=/build/src/status
export MAKEFLAGS="-j$(nproc)"

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

if [ -f /etc/profile ]; then
    source /etc/profile
    echo "Init profile"
fi

xrm_cur() {
    CD=$(pwd)
    cd ..
    rm -rf $CD
}

xis_installed() {
    if [ "$(grep -Fx $1 $STAT_PATH)" == "$1" ]; then
        return 0
    else
        return 1
    fi
}

xset_installed() {
    echo $1 >> $STAT_PATH
}

init_config() {( set -e 
    export PLX=""

    if is_installed "init_config" ; then
        echo "init_config already installed"
        return 0
    fi

mkdir -pv /{boot,home,mnt,opt,srv}

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

set_installed "init_config"
)}

build_libstdcpp_p2() {( set -e 

    if is_installed "build_libstdcpp_p2" ; then
        echo "build_libstdcpp_p2 already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz"

    ln -s gthr-posix.h libgcc/gthr-default.h

    mkdir -v build
    cd       build

    ../libstdc++-v3/configure            \
        CXXFLAGS="-g -O2 -D_GNU_SOURCE"  \
        --prefix=/usr                    \
        --disable-multilib               \
        --disable-nls                    \
        --host=$(uname -m)-plx-linux-gnu \
        --disable-libstdcxx-pch

    make
    make install

    cd ..

    rm_cur

    set_installed "build_libstdcpp_p2"
)}


build_cross_gettext() {( set -e 

    if is_installed "build_cross_gettext" ; then
        echo "build_cross_gettext already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/gettext/gettext-0.21.tar.xz"

    ./configure --disable-shared

    make

    cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

    rm_cur

    set_installed "build_cross_gettext"
)}

build_cross_bison() {( set -e 

    if is_installed "build_cross_bison" ; then
        echo "build_cross_bison already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"

    ./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2

    make 
    make install

    rm_cur

    set_installed "build_cross_bison"
)}

build_cross_perl() {( set -e 

    if is_installed "build_cross_perl" ; then
        echo "build_cross_perl already installed"
        return 0
    fi

    prepare_build "https://www.cpan.org/src/5.0/perl-5.34.0.tar.xz"

    sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Dprivlib=/usr/lib/perl5/5.34/core_perl     \
             -Darchlib=/usr/lib/perl5/5.34/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.34/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.34/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl
    make
    make install

    rm_cur

    set_installed "build_cross_perl"
)}

build_cross_python() {( set -e 

    if is_installed "build_cross_python" ; then
        echo "build_cross_python already installed"
        return 0
    fi

    prepare_build "https://www.python.org/ftp/python/3.10.2/Python-3.10.2.tar.xz"

    ./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
    
    make
    make install

    rm_cur

    set_installed "build_cross_python"
)}

build_cross_texinfo() {( set -e 

    if is_installed "build_cross_texinfo" ; then
        echo "build_cross_texinfo already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/texinfo/texinfo-6.8.tar.xz"

    sed -e 's/__attribute_nonnull__/__nonnull/' \
        -i gnulib/lib/malloc/dynarray-skeleton.c

    ./configure --prefix=/usr

    make
    make install

    rm_cur

    set_installed "build_cross_texinfo"
)}

build_cross_util_linux() {( set -e 

    if is_installed "build_cross_util_linux" ; then
        echo "build_cross_util_linux already installed"
        return 0
    fi

    prepare_build "https://www.kernel.org/pub/linux/utils/util-linux/v2.37/util-linux-2.37.4.tar.xz"

    mkdir -pv /var/lib/hwclock

    ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
                --libdir=/usr/lib    \
                --docdir=/usr/share/doc/util-linux-2.37.4 \
                --disable-chfn-chsh  \
                --disable-login      \
                --disable-nologin    \
                --disable-su         \
                --disable-setpriv    \
                --disable-runuser    \
                --disable-pylibmount \
                --disable-static     \
                --without-python     \
                runstatedir=/run

    make
    make install

    rm_cur

    set_installed "build_cross_util_linux"
)}

build_libtasn1() {( set -e 

    if is_installed "build_libtasn1" ; then
        echo "build_libtasn1 already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.18.0.tar.gz"

    ./configure --prefix=/usr --disable-static
    make
    make install

    rm_cur

    set_installed "build_libtasn1"
)}

build_p11_kit() {( set -e 

    if is_installed "build_p11_kit" ; then
        echo "build_p11_kit already installed"
        return 0
    fi

    prepare_build "https://github.com/p11-glue/p11-kit/releases/download/0.24.1/p11-kit-0.24.1.tar.xz"

sed '20,$ d' -i trust/trust-extract-compat
cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF
    ./configure --help

    ./configure --prefix=/usr       \
        --with-trust-paths=trust_paths=/etc/pki/anchors
    make
    make install

    ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
            /usr/bin/update-ca-certificates

    cd ..
    rm_cur

    set_installed "build_p11_kit"
)}

build_make_ca() {( set -e 

    if is_installed "build_make_ca" ; then
        echo "build_make_ca already installed"
        return 0
    fi

    prepare_build "https://github.com/lfs-book/make-ca/releases/download/v1.10/make-ca-1.10.tar.xz"

    make install
    install -vdm755 /etc/ssl/local
    /usr/sbin/make-ca -g

    rm_cur

    set_installed "build_make_ca"
)}



build_wget() {( set -e 

    if is_installed "build_wget" ; then
        echo "build_wget already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/wget/wget-1.21.2.tar.gz"

    ./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl
    make
    make install
    
    rm_cur

    set_installed "build_wget"
)}

build_meson() {( set -e 

    if is_installed "build_meson" ; then
        echo "build_meson already installed"
        return 0
    fi

    prepare_build "https://github.com/mesonbuild/meson/releases/download/0.61.1/meson-0.61.1.tar.gz"

    python3 setup.py build
    python3 setup.py install --root=dest
    cp -rv dest/* /

    rm_cur

    set_installed "build_meson"
)}

build_ninja() {( set -e 

    if is_installed "build_ninja" ; then
        echo "build_ninja already installed"
        return 0
    fi

    prepare_build "https://github.com/ninja-build/ninja/archive/v1.10.2/ninja-1.10.2.tar.gz"

    sed -i '/int Guess/a \
        int   j = 0;\
        char* jobs = getenv( "NINJAJOBS" );\
        if ( jobs != NULL ) j = atoi( jobs );\
        if ( j > 0 ) return j;\
        ' src/ninja.cc

    python3 configure.py --bootstrap

    install -vm755 ninja /usr/bin/
    install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
    install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

    rm_cur

    set_installed "build_ninja"
)}

build_zlib() {( set -e 

    if is_installed "build_zlib" ; then
        echo "build_zlib already installed"
        return 0
    fi

    prepare_build "https://zlib.net/zlib-1.2.12.tar.xz"

    ./configure --prefix=/usr
    make
    make install

    rm_cur

    set_installed "build_zlib"
)}

build_pyyaml() {( set -e 

    if is_installed "build_pyyaml" ; then
        echo "build_pyyaml already installed"
        return 0
    fi

    prepare_build "http://pyyaml.org/download/pyyaml/PyYAML-5.3.1.tar.gz"

    python3 setup.py install

    rm_cur

    set_installed "build_pyyaml"
)}

finalize() {( set -e 

    if is_installed "finalize" ; then
        echo "finalize already installed"
        return 0
    fi

ln -s /dev/null /etc/systemd/network/99-default.link || true

cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
[Match]
Name=eth0

[Network]
DHCP=ipv4

[DHCP]
UseDomains=true
EOF

echo "plx" > /etc/hostname

cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

cat > /etc/adjtime << "EOF"
0.0 0 0.0
0
LOCAL
EOF

cat > /etc/locale.conf << "EOF"
LANG=en_US.UTF-8
EOF

cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

mkdir -pv /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf << EOF
[Service]
TTYVTDisallocate=no
EOF

ln -sfv /dev/null /etc/systemd/system/tmp.mount || true

echo "Enter root partition: "
read pname

cat > /etc/fstab << EOF
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

$pname    /            ext4    defaults            1     1

# End /etc/fstab
EOF

echo 1.3.0-aarch64 > /etc/plx-release

cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Pullinux"
DISTRIB_RELEASE="1.3.0-aarch64"
DISTRIB_CODENAME="M1"
DISTRIB_DESCRIPTION="Pullinux"
EOF

cat > /etc/os-release << "EOF"
NAME="Pullinux"
VERSION="1.3.0-aarch64"
ID=plx
PRETTY_NAME="Pullinux 1.3.0-aarch64 M1"
VERSION_CODENAME="M1-R1"
EOF

    set_installed "finalize"
)}


inst_base() {( set -e 

    if is_installed "inst_base" ; then
        echo "inst_base already installed"
        return 0
    fi

    mkdir -p /usr/share/plx
    echo "base" > /usr/share/plx/installed

    set_installed "inst_base"
)}

config_shell() {( set -e 

    if is_installed "config_shell" ; then
        echo "config_shell already installed"
        return 0
    fi

cat > /etc/profile << "EOF"
# Begin /etc/profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# modifications by Dagmar d'Surreal <rivyqntzne@pbzpnfg.arg>

# System wide environment variables and startup programs.

# System wide aliases and functions should go in /etc/bashrc.  Personal
# environment variables and startup programs should go into
# ~/.bash_profile.  Personal aliases and functions should go into
# ~/.bashrc.

# Functions to help us manage paths.  Second argument is the name of the
# path variable to be modified (default: PATH)
pathremove () {
        local IFS=':'
        local NEWPATH
        local DIR
        local PATHVARIABLE=${2:-PATH}
        for DIR in ${!PATHVARIABLE} ; do
                if [ "$DIR" != "$1" ] ; then
                  NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
                fi
        done
        export $PATHVARIABLE="$NEWPATH"
}

pathprepend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
}

pathappend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
}

export -f pathremove pathprepend pathappend

# Set the initial path
export PATH=/usr/bin

# Attempt to provide backward compatibility with LFS earlier than 11
if [ ! -L /bin ]; then
        pathappend /bin
fi

if [ $EUID -eq 0 ] ; then
        pathappend /usr/sbin
        if [ ! -L /sbin ]; then
                pathappend /sbin
        fi
        unset HISTFILE
fi

# Setup some environment variables.
export HISTSIZE=1000
export HISTIGNORE="&:[bf]g:exit"

# Set some defaults for graphical systems
export XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/share/}
export XDG_CONFIG_DIRS=${XDG_CONFIG_DIRS:-/etc/xdg/}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}

# Setup a red prompt for root and a green one for users.
NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

for script in /etc/profile.d/*.sh ; do
        if [ -r $script ] ; then
                . $script
        fi
done

unset script RED GREEN NORMAL

# End /etc/profile
EOF

install --directory --mode=0755 --owner=root --group=root /etc/profile.d

cat > /etc/profile.d/bash_completion.sh << "EOF"
# Begin /etc/profile.d/bash_completion.sh
# Import bash completion scripts

# If the bash-completion package is installed, use its configuration instead
if [ -f /usr/share/bash-completion/bash_completion ]; then

  # Check for interactive bash and that we haven't already been sourced.
  if [ -n "${BASH_VERSION-}" -a -n "${PS1-}" -a -z "${BASH_COMPLETION_VERSINFO-}" ]; then

    # Check for recent enough version of bash.
    if [ ${BASH_VERSINFO[0]} -gt 4 ] || \
       [ ${BASH_VERSINFO[0]} -eq 4 -a ${BASH_VERSINFO[1]} -ge 1 ]; then
       [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion" ] && \
            . "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion"
       if shopt -q progcomp && [ -r /usr/share/bash-completion/bash_completion ]; then
          # Source completion code.
          . /usr/share/bash-completion/bash_completion
       fi
    fi
  fi

else

  # bash-completions are not installed, use only bash completion directory
  if shopt -q progcomp; then
    for script in /etc/bash_completion.d/* ; do
      if [ -r $script ] ; then
        . $script
      fi
    done
  fi
fi

# End /etc/profile.d/bash_completion.sh
EOF

install --directory --mode=0755 --owner=root --group=root /etc/bash_completion.d

cat > /etc/profile.d/dircolors.sh << "EOF"
# Setup for /bin/ls and /bin/grep to support color, the alias is in /etc/bashrc.
if [ -f "/etc/dircolors" ] ; then
        eval $(dircolors -b /etc/dircolors)
fi

if [ -f "$HOME/.dircolors" ] ; then
        eval $(dircolors -b $HOME/.dircolors)
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
EOF

cat > /etc/profile.d/extrapaths.sh << "EOF"
if [ -d /usr/local/lib/pkgconfig ] ; then
        pathappend /usr/local/lib/pkgconfig PKG_CONFIG_PATH
fi
if [ -d /usr/local/bin ]; then
        pathprepend /usr/local/bin
fi
if [ -d /usr/local/sbin -a $EUID -eq 0 ]; then
        pathprepend /usr/local/sbin
fi

if [ -d /usr/local/share ]; then
        pathprepend /usr/local/share XDG_DATA_DIRS
fi

# Set some defaults before other applications add to these paths.
pathappend /usr/share/man  MANPATH
pathappend /usr/share/info INFOPATH
EOF

cat > /etc/profile.d/readline.sh << "EOF"
# Setup the INPUTRC environment variable.
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
        INPUTRC=/etc/inputrc
fi
export INPUTRC
EOF

cat > /etc/profile.d/umask.sh << "EOF"
# By default, the umask should be set.
if [ "$(id -gn)" = "$(id -un)" -a $EUID -gt 99 ] ; then
  umask 002
else
  umask 022
fi
EOF

cat > /etc/profile.d/i18n.sh << "EOF"
# Set up i18n variables
. /etc/locale.conf
export LANG
EOF

cat > /etc/bashrc << "EOF"
# Begin /etc/bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# System wide aliases and functions.

# System wide environment variables and startup programs should go into
# /etc/profile.  Personal environment variables and startup programs
# should go into ~/.bash_profile.  Personal aliases and functions should
# go into ~/.bashrc

# Provides colored /bin/ls and /bin/grep commands.  Used in conjunction
# with code in /etc/profile.

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Provides prompt for non-login shells, specifically shells started
# in the X environment. [Review the LFS archive thread titled
# PS1 Environment Variable for a great case study behind this script
# addendum.]

NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

unset RED GREEN NORMAL

# End /etc/bashrc
EOF

cat > ~/.bash_profile << "EOF"
# Begin ~/.bash_profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# Personal environment variables and startup programs.

# Personal aliases and functions should go in ~/.bashrc.  System wide
# environment variables and startup programs are in /etc/profile.
# System wide aliases and functions are in /etc/bashrc.

if [ -f "$HOME/.bashrc" ] ; then
  source $HOME/.bashrc
fi

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Having . in the PATH is dangerous
#if [ $EUID -gt 99 ]; then
#  pathappend .
#fi

# End ~/.bash_profile
EOF

mkdir -p /etc/skel

cat > /etc/skel/.bash_profile << "EOF"
# Begin ~/.bash_profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# Personal environment variables and startup programs.

# Personal aliases and functions should go in ~/.bashrc.  System wide
# environment variables and startup programs are in /etc/profile.
# System wide aliases and functions are in /etc/bashrc.

if [ -f "$HOME/.bashrc" ] ; then
  source $HOME/.bashrc
fi

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Having . in the PATH is dangerous
#if [ $EUID -gt 99 ]; then
#  pathappend .
#fi

# End ~/.bash_profile
EOF

cat > ~/.profile << "EOF"
# Begin ~/.profile
# Personal environment variables and startup programs.

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.profile
EOF

cat > /etc/skel/.profile << "EOF"
# Begin ~/.profile
# Personal environment variables and startup programs.

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.profile
EOF

cat > ~/.bashrc << "EOF"
# Begin ~/.bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal aliases and functions.

# Personal environment variables and startup programs should go in
# ~/.bash_profile.  System wide environment variables and startup
# programs are in /etc/profile.  System wide aliases and functions are
# in /etc/bashrc.

if [ -f "/etc/bashrc" ] ; then
  source /etc/bashrc
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.bashrc
EOF

cat > /etc/skel/.bashrc << "EOF"
# Begin ~/.bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal aliases and functions.

# Personal environment variables and startup programs should go in
# ~/.bash_profile.  System wide environment variables and startup
# programs are in /etc/profile.  System wide aliases and functions are
# in /etc/bashrc.

if [ -f "/etc/bashrc" ] ; then
  source /etc/bashrc
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.bashrc
EOF

cat > ~/.bash_logout << "EOF"
# Begin ~/.bash_logout
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal items to perform on logout.

# End ~/.bash_logout
EOF

cat > /etc/skel/.bash_logout << "EOF"
# Begin ~/.bash_logout
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal items to perform on logout.

# End ~/.bash_logout
EOF

dircolors -p > /etc/dircolors

    set_installed "config_shell"
)}




xbuild_template() {( set -e 

    if is_installed "build_template" ; then
        echo "build_template already installed"
        return 0
    fi

    prepare_build ""

    rm_cur

    set_installed "build_template"
)}



