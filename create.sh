set -e

echo "Creating PLX in ${PLX:?}"

mkdir -pv $PLX/{etc,var,lib64} $PLX/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  if [ ! -s $PLX/$i ]; then
    ln -sv usr/$i $PLX/$i
  fi
done

mkdir -pv $PLX/tools
mkdir -pv $PLX/build/src
mkdir -pv $PLX/build/dl

chown -v plx $PLX/{usr{,/*},lib,var,etc,bin,sbin,tools,lib64}
chown -v plx $PLX/build/src
chown -v plx $PLX/build/dl
