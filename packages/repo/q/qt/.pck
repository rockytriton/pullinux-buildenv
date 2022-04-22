name: qt
version: 5.15.2
repo: core
source: https://download.qt.io/archive/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz
deps: [
  'xorg-libs',
  'alsa-lib',
  'glib',
  'gst-plugins-base',
  'icu',
  'jasper',
  'libmng',
  'libpng',
  'tiff',
  'libwebp',
  'libxkbcommon',
  'mesa',
  'mtdev',
  'pcre2',
  'sqlite',
  'wayland',
  'xcb-util-image',
  'xcb-util-keysyms',
  'xcb-util-renderutil',
  'xcb-util-wm',
]
mkdeps: []
extras: [
  'qt-everywhere-src-5.15.2-kf5.15-2.patch'
]
