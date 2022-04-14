name: shared-mime-info
version: 2.1
repo: core
source: https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/2.1/shared-mime-info-2.1.tar.gz
deps: [
  'glib',
  'itstool',
  'libxml2',
  'xmlto',
]
mkdeps: []
extras: [
  'shared-mime-info-2.1-meson_0.60_fix-1.patch'
]
