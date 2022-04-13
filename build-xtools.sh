#!/bin/bash

set -e

source ~/.bashrc

echo "Building cross-tools in ${PLX:?}"

CURDIR="$(dirname "$0")"

. "$CURDIR/utils.sh"

build_binutils_p1
build_gcc_p1
build_linux_headers
build_glibc_p1
build_libstdcpp_p1
build_cross_m4
build_cross_ncurses
build_cross_bash
build_cross_coreutils
build_cross_diff
build_cross_file
build_cross_find
build_cross_gawk
build_cross_grep
build_cross_gzip
build_cross_make
build_cross_patch
build_cross_sed
build_cross_tar
build_cross_xz
build_binutils_p2
build_gcc_p2

echo "Cross build complete"

