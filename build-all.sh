CURDIR="$(dirname "$0")"

( set -e

echo "Building PLX in ${PLX:?}"

CURDIR="$(dirname "$0")"

. "$CURDIR/utils.sh"

if ! id "plx" &>/dev/null; then
    $CURDIR/setup-user.sh
fi

$CURDIR/create.sh
sudo -u plx $CURDIR/build-xtools.sh

echo "Completing filesystem..."

chown -R root:root $PLX/{usr,lib,var,etc,bin,sbin,tools,lib64}
mkdir -pv $PLX/{dev,proc,sys,run}
mknod -m 600 $PLX/dev/console c 5 1 || echo "console exists"
mknod -m 666 $PLX/dev/null c 1 3 || echo "devnull exists"
echo "nameserver 8.8.8.8" > $PLX/etc/resolv.conf

$CURDIR/vmount.sh

cp $CURDIR/chroot_utils.sh $PLX/build/src/
cp $CURDIR/utils.sh $PLX/build/src/

do_chroot_build() { (set -e
    CMD=". /build/src/utils.sh && . /build/src/chroot_utils.sh && $1"

    chroot "$PLX" /bin/bash -c "$CMD"
)}

#pre-download these as no wget in chroot env.
download_file "https://ftp.gnu.org/gnu/gettext/gettext-0.21.tar.xz"
download_file "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"
download_file "https://www.cpan.org/src/5.0/perl-5.34.0.tar.xz"
download_file "https://www.python.org/ftp/python/3.10.2/Python-3.10.2.tar.xz"
download_file "https://ftp.gnu.org/gnu/texinfo/texinfo-6.8.tar.xz"
download_file "https://www.kernel.org/pub/linux/utils/util-linux/v2.37/util-linux-2.37.4.tar.xz"
download_file "https://zlib.net/zlib-1.2.12.tar.xz"
download_file "http://pyyaml.org/download/pyyaml/PyYAML-5.3.1.tar.gz"
download_file "https://github.com/Mic92/iana-etc/releases/download/20220207/iana-etc-20220207.tar.gz"

do_chroot_build "init_config"
do_chroot_build "build_libstdcpp_p2"
do_chroot_build "build_cross_gettext"
do_chroot_build "build_cross_bison"
do_chroot_build "build_cross_perl"
do_chroot_build "build_cross_python"
do_chroot_build "build_cross_texinfo"
do_chroot_build "build_cross_util_linux"
do_chroot_build "build_pyyaml"

#At this point, the cross env is complete.  Now start building packages.
#First build things so we can get wget

create_package() {( set -e
    if is_installed "pck_$1" ; then
        echo "pck_$1 already packaged"
        return 0
    fi

    do_chroot_build "python3 /build/scripts/build.py $1 /build"

    set_installed "pck_$1"
)}

mkdir -p $PLX/build/bin
cp -r packages/* $PLX/build/

#pre-download files since no wget yet
for f in $(cat $CURDIR/precache-packages)
do
    download_file "$f"
done;

create_package "man-pages"
create_package "iana-etc"
create_package "glibc"
create_package "zlib"
create_package "bzip2"
create_package "xz"
create_package "zstd"
create_package "file"
create_package "readline"
create_package "m4"
create_package "bc"
create_package "flex"
create_package "tcl"
create_package "expect"
create_package "dejagnu"
create_package "binutils"
create_package "gmp"
create_package "mpfr"
create_package "mpc"
create_package "attr"
create_package "acl"
create_package "libcap"
create_package "shadow"
create_package "gcc"
create_package "pkg-config"
create_package "ncurses"
create_package "sed"
create_package "psmisc"
create_package "gettext"
create_package "bison"
create_package "grep"
create_package "bash"
create_package "libtool"
create_package "gdbm"
create_package "gperf"
create_package "expat"
create_package "inetutils"
create_package "less"
create_package "perl"
create_package "XML-Parser"
create_package "intltool"
create_package "autoconf"
create_package "automake"
create_package "openssl"
create_package "libtasn1"
create_package "kmod"
create_package "libelf"
create_package "libffi"
create_package "p11-kit"
create_package "make-ca"
create_package "wget"
create_package "python"
create_package "ninja"
create_package "meson"
create_package "coreutils"
create_package "check"
create_package "diffutils"
create_package "gawk"
create_package "findutils"
create_package "groff"
create_package "grub"
create_package "gzip"
create_package "iproute2"
create_package "kbd"
create_package "libpipeline"
create_package "make"
create_package "patch"
create_package "tar"
create_package "texinfo"
create_package "vim"
create_package "markupsafe"
create_package "jinja2"
create_package "systemd"
create_package "dbus"
create_package "man-db"
create_package "procps-ng"
create_package "util-linux"
create_package "e2fsprogs"

do_chroot_build "finalize"

do_chroot_build "inst_base"

create_package "linux"

do_chroot_build "config_shell"

create_package "pam"
create_package "libcap-pam"
create_package "shadow-pam"
create_package "pcre"
create_package "libxml2"
create_package "docbook-xsl-nons"
create_package "unzip"
create_package "sgml-common"
create_package "docbook-xml"
create_package "libxslt"
create_package "glib"
create_package "gobject-introspection"
create_package "which"
create_package "autoconf2"
create_package "libuv"
create_package "curl"
create_package "libarchive"
create_package "nghttp2"
create_package "cmake"
create_package "llvm"
create_package "icu"
create_package "libssh2"
create_package "rustc"
create_package "mozjs"
create_package "polkit"
create_package "systemd-pam"
create_package "sudo"
create_package "xorg-build-env"
create_package "util-macros"
create_package "xorgproto"
create_package "libXau"
create_package "libXdmcp"
create_package "xcb-proto"
create_package "libxcb"
create_package "libpng"
create_package "freetype-nohb"
create_package "graphite2"
create_package "harfbuzz"
create_package "freetype"
create_package "fontconfig"
create_package "xorg-libs"
create_package "libgpg-error"
create_package "libgcrypt"
create_package "libassuan"
create_package "libksba"
create_package "npth"
create_package "nettle"
create_package "libunistring"
create_package "gnutls"
create_package "pinentry"
create_package "gnupg"
create_package "dbus-pam"
create_package "at-spi2-core"
create_package "atk"
create_package "at-spi2-atk"
create_package "nasm"
create_package "yasm"
create_package "libjpeg-turbo"
create_package "itstool"
create_package "xmlto"
create_package "shared-mime-info"
create_package "tiff"
create_package "gdk-pixbuf"
create_package "pixman"
create_package "cairo"
create_package "fribidi"
create_package "graphviz"
create_package "vala"
create_package "pango"
create_package "librsvg"
create_package "libdrm"
create_package "mako"
create_package "libva-nomesa"
create_package "libvdpau"
create_package "wayland"
create_package "wayland-protocols"
create_package "mesa"
create_package "libepoxy"
create_package "adwaita-icon-theme"
create_package "hicolor-icon-theme"
create_package "iso-codes"
create_package "xkeyboard-config"
create_package "libsass"
create_package "libxkbcommon"
create_package "sassc"
create_package "gtk+3"
create_package "libsecret"
create_package "accountsservice"
create_package "polkit-gnome"
create_package "gtk+2"
create_package "lxdm"




)

$CURDIR/uvmount.sh
