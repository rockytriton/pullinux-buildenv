name: avahi
version: 0.8
repo: core
source: https://github.com/lathiat/avahi/releases/download/v0.8/avahi-0.8.tar.gz
deps: [
  'glib',
  'gtk+2',
  'gtk+3',
  'libdaemon',
  'libglade',
]
mkdeps: []
extras: [
  'avahi-0.8-ipv6_race_condition_fix-1.patch'
]
