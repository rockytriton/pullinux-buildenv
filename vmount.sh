#set -e

echo "Mounting Virtual in ${PLX:?}"

mount -v --bind /dev $PLX/dev 
mount -v --bind /dev/pts $PLX/dev/pts
mount -vt proc proc $PLX/proc
mount -vt sysfs sysfs $PLX/sys
mount -vt tmpfs tmpfs $PLX/run

if [ -h $PLX/dev/shm ]; then
  mkdir -pv $PLX/$(readlink $PLX/dev/shm)
fi
