name: polkit-gnome
version: 0.105
repo: core
source: https://download.gnome.org/sources/polkit-gnome/0.105/polkit-gnome-0.105.tar.xz
deps: [
  'accountsservice',
  'gtk+3',
  'polkit',
]
mkdeps: []
extras: [
  'polkit-gnome-0.105-consolidated_fixes-1.patch'
]
