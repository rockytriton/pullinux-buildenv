
export DL_PATH=${PLX:?}/build/dl
export SRC_PATH=${PLX:?}/build/src
export STAT_PATH=${PLX:?}/build/src/status

download_file() {
    URL=$1
    FN=$(basename $URL)

    echo "Downloading ${URL:?} in $DL_PATH"

    if [ ! -f "$DL_PATH/$FN" ]; then
        if wget --directory-prefix="$DL_PATH" "$URL" ; then
            return 0
        else
            return -1
        fi
    fi

    echo "Using previously downloaded file: $DL_PATH/$FN"
    return 0;
}

prepare_build() {
    URL=$1
    DIR=$2

    FN=$(basename $URL)

    if [ "$DIR" == "" ]; then
        DIR="${FN%.t*}"
    fi

    if [ -d "$SRC_PATH/$DIR" ]; then
        echo "Cleaning up old directory"
        rm -rf $SRC_PATH/$DIR
    fi

    if ! download_file "$URL" ; then
        echo "Download Failure"
        return -1;
    fi

    tar -xf $DL_PATH/$FN -C $SRC_PATH

    if ! cd $SRC_PATH/$DIR ; then
        return -1
    fi

    return 0
}

rm_cur() {
    CD=$(pwd)
    cd ..
    rm -rf $CD
}

is_installed() {
    if [ "$(grep -Fx $1 $STAT_PATH)" == "$1" ]; then
        return 0
    else
        return 1
    fi
}

set_installed() {
    echo $1 >> $STAT_PATH
}

build_binutils_p1() {( set -e
    touch $STAT_PATH

    if is_installed "build_binutils_p1" ; then
        echo "build_binutils_p1 already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz"

    mkdir -v build
    cd       build

    ../configure --prefix=$PLX/tools \
             --with-sysroot=$PLX \
             --target=$PLX_TGT   \
             --disable-nls       \
             --disable-werror

    make && make install
    cd ..
    rm_cur

    set_installed "build_binutils_p1"
)}

build_gcc_p1() {( set -e

    if is_installed "build_gcc_p1" ; then
        echo "build_gcc_p1 already installed"
        return 0
    fi

    download_file "https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz"
    download_file "https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz"
    download_file "https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz"
    prepare_build "https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz"

    echo "Extracting..."
    pwd
    echo "TGT: $PLX_TGT"
    sleep 5

    tar -xf $DL_PATH/mpfr-4.1.0.tar.xz
    mv -v mpfr-4.1.0 mpfr
    tar -xf $DL_PATH/gmp-6.2.1.tar.xz
    mv -v gmp-6.2.1 gmp
    tar -xf $DL_PATH/mpc-1.2.1.tar.gz
    mv -v mpc-1.2.1 mpc

    sed -e '/lp64=/s/lib64/lib/' -i.orig gcc/config/aarch64/t-aarch64-linux

    mkdir -v build
    cd       build

    ../configure                  \
        --target=$PLX_TGT         \
        --prefix=$PLX/tools       \
        --with-glibc-version=2.35 \
        --with-sysroot=$PLX       \
        --with-newlib             \
        --without-headers         \
        --enable-initfini-array   \
        --disable-nls             \
        --disable-shared          \
        --disable-multilib        \
        --disable-decimal-float   \
        --disable-threads         \
        --disable-libatomic       \
        --disable-libgomp         \
        --disable-libquadmath     \
        --disable-libssp          \
        --disable-libvtv          \
        --disable-libstdcxx       \
        --enable-languages=c,c++
    make
    make install

    cd ..
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    `dirname $($PLX_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h

    rm_cur

    set_installed "build_gcc_p1"
)}

build_linux_headers() {( set -e

    if is_installed "build_linux_headers" ; then
        echo "build_linux_headers already installed"
        return 0
    fi

    prepare_build "https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.16.9.tar.xz"

    make mrproper

    make headers
    find usr/include -name '.*' -delete
    rm usr/include/Makefile
    cp -rv usr/include $PLX/usr

    rm_cur

    set_installed "build_linux_headers"
)}

build_glibc_p1() {( set -e 

    if is_installed "build_glibc_p1" ; then
        echo "build_glibc_p1 already installed"
        return 0
    fi

    download_file "https://www.linuxfromscratch.org/patches/lfs/11.1/glibc-2.35-fhs-1.patch"
    prepare_build "https://ftp.gnu.org/gnu/glibc/glibc-2.35.tar.xz"

    ln -sfv ../lib/ld-linux-aarch64.so.1 $PLX/lib64
    ln -sfv ../lib/ld-linux-aarch64.so.1 $PLX/lib64/ld-lsb-aarch64.so.1

    patch -Np1 -i $DL_PATH/glibc-2.35-fhs-1.patch

    mkdir -v build
    cd       build

    ../configure                             \
      --prefix=/usr                      \
      --host=$PLX_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=$PLX/usr/include    \
      libc_cv_slibdir=/usr/lib

    make
    make DESTDIR=$PLX install

    sed '/RTLDLIST=/s@/usr@@g' -i $PLX/usr/bin/ldd

    $PLX/tools/libexec/gcc/$PLX_TGT/11.2.0/install-tools/mkheaders

    cd ..
    
    rm_cur

    set_installed "build_glibc_p1"
)}

build_libstdcpp_p1() {( set -e

    if is_installed "build_libstdcpp_p1" ; then
        echo "build_libstdcpp_p1 already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz"

    mkdir -v build
    cd       build

    ../libstdc++-v3/configure           \
        --host=$PLX_TGT                 \
        --build=$(../config.guess)      \
        --prefix=/usr                   \
        --disable-multilib              \
        --disable-nls                   \
        --disable-libstdcxx-pch         \
        --with-gxx-include-dir=/tools/$PLX_TGT/include/c++/11.2.0

    make
    make DESTDIR=$PLX install

    cd ..
    rm_cur

    set_installed "build_libstdcpp_p1"
)}

build_cross_m4() {( set -e 

    if is_installed "build_cross_m4" ; then
        echo "build_cross_m4 already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz"

    ./configure --prefix=/usr   \
                --host=$PLX_TGT \
                --build=$(build-aux/config.guess)

    make

    make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_m4"
)}

build_cross_ncurses() {( set -e 

    if is_installed "build_cross_ncurses" ; then
        echo "build_cross_ncurses already installed"
        return 0
    fi

    prepare_build "https://invisible-mirror.net/archives/ncurses/ncurses-6.3.tar.gz"

    sed -i s/mawk// configure

    mkdir build
    pushd build
    ../configure
    make -C include
    make -C progs tic
    popd

    ./configure --prefix=/usr                \
                --host=$PLX_TGT              \
                --build=$(./config.guess)    \
                --mandir=/usr/share/man      \
                --with-manpage-format=normal \
                --with-shared                \
                --without-debug              \
                --without-ada                \
                --without-normal             \
                --disable-stripping          \
                --enable-widec
    make
    make DESTDIR=$PLX TIC_PATH=$(pwd)/build/progs/tic install
    echo "INPUT(-lncursesw)" > $PLX/usr/lib/libncurses.so

    rm_cur

    set_installed "build_cross_ncurses"
)}

build_cross_bash() {( set -e 

    if is_installed "build_cross_bash" ; then
        echo "build_cross_bash already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/bash/bash-5.1.16.tar.gz"

    ./configure --prefix=/usr                   \
            --build=$(support/config.guess) \
            --host=$PLX_TGT                 \
            --without-bash-malloc
    make
    make DESTDIR=$PLX install
    ln -sv bash $PLX/bin/sh

    rm_cur

    set_installed "build_cross_bash"
)}

build_cross_coreutils() {( set -e 

    if is_installed "build_cross_coreutils" ; then
        echo "build_cross_coreutils already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/coreutils/coreutils-9.0.tar.xz"

    ./configure --prefix=/usr                     \
            --host=$PLX_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

    make && make DESTDIR=$PLX install

    mv -v $PLX/usr/bin/chroot              $PLX/usr/sbin
    mkdir -pv $PLX/usr/share/man/man8
    mv -v $PLX/usr/share/man/man1/chroot.1 $PLX/usr/share/man/man8/chroot.8
    sed -i 's/"1"/"8"/'                    $PLX/usr/share/man/man8/chroot.8

    rm_cur

    set_installed "build_cross_coreutils"
)}

build_cross_diff() {( set -e 

    if is_installed "build_cross_diff" ; then
        echo "build_cross_diff already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/diffutils/diffutils-3.8.tar.xz"

    ./configure --prefix=/usr --host=$PLX_TGT
    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_diff"
)}

build_cross_file() {( set -e 

    if is_installed "build_cross_file" ; then
        echo "build_cross_file already installed"
        return 0
    fi

    prepare_build "https://astron.com/pub/file/file-5.41.tar.gz"

    mkdir build
    pushd build
    ../configure --disable-bzlib      \
                --disable-libseccomp \
                --disable-xzlib      \
                --disable-zlib
    make
    popd

    ./configure --prefix=/usr --host=$PLX_TGT --build=$(./config.guess)

    make FILE_COMPILE=$(pwd)/build/src/file

    make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_file"
)}

build_cross_find() {( set -e 

    if is_installed "build_cross_find" ; then
        echo "build_cross_find already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/findutils/findutils-4.9.0.tar.xz"

    ./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$PLX_TGT                 \
            --build=$(build-aux/config.guess)

    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_find"
)}

build_cross_gawk() {( set -e 

    if is_installed "build_cross_gawk" ; then
        echo "build_cross_gawk already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/gawk/gawk-5.1.1.tar.xz"

    sed -i 's/extras//' Makefile.in

    ./configure --prefix=/usr   \
                --host=$PLX_TGT \
                --build=$(build-aux/config.guess)

    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_gawk"
)}

build_cross_grep() {( set -e 

    if is_installed "build_cross_grep" ; then
        echo "build_cross_grep already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/grep/grep-3.7.tar.xz"

    ./configure --prefix=/usr   \
                --host=$PLX_TGT

    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_grep"
)}

build_cross_gzip() {( set -e 

    if is_installed "build_cross_gzip" ; then
        echo "build_cross_gzip already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/gzip/gzip-1.11.tar.xz"

    ./configure --prefix=/usr   \
                --host=$PLX_TGT

    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_gzip"
)}

build_cross_make() {( set -e 

    if is_installed "build_cross_make" ; then
        echo "build_cross_make already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/make/make-4.3.tar.gz"

    ./configure --prefix=/usr   \
            --without-guile \
            --host=$PLX_TGT \
            --build=$(build-aux/config.guess)

    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_make"
)}

build_cross_patch() {( set -e 

    if is_installed "build_cross_patch" ; then
        echo "build_cross_patch already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz"

    ./configure --prefix=/usr   \
            --host=$PLX_TGT \
            --build=$(build-aux/config.guess)

    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_patch"
)}

build_cross_sed() {( set -e 

    if is_installed "build_cross_sed" ; then
        echo "build_cross_sed already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/sed/sed-4.8.tar.xz"

    ./configure --prefix=/usr   \
                --host=$PLX_TGT

    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_sed"
)}

build_cross_tar() {( set -e 

    if is_installed "build_cross_tar" ; then
        echo "build_cross_tar already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/tar/tar-1.34.tar.xz"

    ./configure --prefix=/usr   \
            --host=$PLX_TGT \
            --build=$(build-aux/config.guess)

    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_tar"
)}

build_cross_xz() {( set -e 

    if is_installed "build_cross_xz" ; then
        echo "build_cross_xz already installed"
        return 0
    fi

    prepare_build "https://tukaani.org/xz/xz-5.2.5.tar.xz"

    ./configure --prefix=/usr                     \
            --host=$PLX_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.2.5

    make && make DESTDIR=$PLX install

    rm_cur

    set_installed "build_cross_xz"
)}

build_binutils_p2() {( set -e 

    if is_installed "build_binutils_p2" ; then
        echo "build_binutils_p2 already installed"
        return 0
    fi

    prepare_build "https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.xz"

    sed '6009s/$add_dir//' -i ltmain.sh

    mkdir -v build
    cd       build

    ../configure                   \
        --prefix=/usr              \
        --build=$(../config.guess) \
        --host=$PLX_TGT            \
        --disable-nls              \
        --enable-shared            \
        --disable-werror           \
        --enable-64-bit-bfd
        
    make && make DESTDIR=$PLX install

    cd ..

    rm_cur

    set_installed "build_binutils_p2"
)}

build_gcc_p2() {( set -e

    if is_installed "build_gcc_p2" ; then
        echo "build_gcc_p2 already installed"
        return 0
    fi

    download_file "https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz"
    download_file "https://ftp.gnu.org/gnu/mpc/mpc-1.2.1.tar.gz"
    download_file "https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz"
    prepare_build "https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz"

    echo "Extracting..."
    pwd
    echo "TGT: $PLX_TGT"
    sleep 5

    tar -xf $DL_PATH/mpfr-4.1.0.tar.xz
    mv -v mpfr-4.1.0 mpfr
    tar -xf $DL_PATH/gmp-6.2.1.tar.xz
    mv -v gmp-6.2.1 gmp
    tar -xf $DL_PATH/mpc-1.2.1.tar.gz
    mv -v mpc-1.2.1 mpc

    sed -e '/lp64=/s/lib64/lib/' -i.orig gcc/config/aarch64/t-aarch64-linux

    mkdir -v build
    cd       build
    
    mkdir -pv $PLX_TGT/libgcc
    ln -s ../../../libgcc/gthr-posix.h $PLX_TGT/libgcc/gthr-default.h


    ../configure                                       \
        --build=$(../config.guess)                     \
        --host=$PLX_TGT                                \
        --prefix=/usr                                  \
        CC_FOR_TARGET=$PLX_TGT-gcc                     \
        --with-build-sysroot=$PLX                      \
        --enable-initfini-array                        \
        --disable-nls                                  \
        --disable-multilib                             \
        --disable-decimal-float                        \
        --disable-libatomic                            \
        --disable-libgomp                              \
        --disable-libquadmath                          \
        --disable-libssp                               \
        --disable-libvtv                               \
        --disable-libstdcxx                            \
        --enable-languages=c,c++
        
    make
    make DESTDIR=$PLX install

    ln -sv gcc $PLX/usr/bin/cc

    cd ..

    rm_cur

    set_installed "build_gcc_p2"
)}

build_template() {( set -e 

    if is_installed "build_template" ; then
        echo "build_template already installed"
        return 0
    fi

    prepare_build ""

    rm_cur

    set_installed "build_template"
)}

