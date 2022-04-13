set -e

echo "Unmounting Virtual in ${PLX:?}"

umount -l $PLX/dev/pts || echo "unmounted pts"
umount -f $PLX/dev/pts || echo "unmounted pts"
umount $PLX/{sys,proc,run,dev}
