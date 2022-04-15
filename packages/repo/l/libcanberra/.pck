name: libcanberra
version: 0.30
repo: core
source: http://0pointer.de/lennart/projects/libcanberra/libcanberra-0.30.tar.xz
deps: [
  'libvorbis',
  'alsa-lib',
  'gstreamer',
  'gtk+3',
]
mkdeps: []
extras: [
  'libcanberra-0.30-wayland-1.patch'
]
