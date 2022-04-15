name: nss
version: 3.75
repo: core
source: https://archive.mozilla.org/pub/security/nss/releases/NSS_3_75_RTM/src/nss-3.75.tar.gz
deps: [
  'nspr',
  'sqlite',
]
mkdeps: []
extras: [
  'nss-3.75-standalone-1.patch'
]
