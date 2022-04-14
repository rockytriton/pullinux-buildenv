name: mesa
version: 21.3.6
repo: core
source: https://mesa.freedesktop.org/archive/mesa-21.3.6.tar.xz
deps: [
  'xorg-libs',
  'libdrm',
  'mako',
  'libva-nomesa',
  'libvdpau',
  'wayland-protocols',
]
mkdeps: [
  'llvm'
]
extras: [
  'mesa-21.3.6-add_xdemos-1.patch'
]
