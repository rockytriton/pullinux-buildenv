#!/bin/bash

set -e

source ~/.bashrc

echo "Building cross-tools in ${PLX:?}"

CURDIR="$(dirname "$0")"

. "$CURDIR/utils.sh"



chroot "$PLX" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login