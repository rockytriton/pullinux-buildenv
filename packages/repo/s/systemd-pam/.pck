name: systemd-pam
version: 250
repo: core
source: https://github.com/systemd/systemd/archive/v250/systemd-250.tar.gz
deps: [
  'polkit',
  'pam',
]
mkdeps: []
extras: [
  'systemd-250-upstream_fixes-1.patch'
]
