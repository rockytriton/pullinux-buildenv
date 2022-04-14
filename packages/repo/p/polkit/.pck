name: polkit
version: 0.120
repo: core
source: https://www.freedesktop.org/software/polkit/releases/polkit-0.120.tar.gz
deps: [
  'glib',
  'mozjs',
  'gobject-introspection',
  'libxslt',
  'pam',
]
mkdeps: []
extras: [
  'polkit-0.120-security_fix-1.patch'
]
