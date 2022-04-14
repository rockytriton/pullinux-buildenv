name: mozjs
version: 78.15.0
repo: core
source: https://archive.mozilla.org/pub/firefox/releases/78.15.0esr/source/firefox-78.15.0esr.source.tar.xz
deps: [
]
mkdeps: [
  'autoconf2',
  'icu',
  'rustc',
  'which'
]
extras: [
  'js-78.15.0-python_3_10-1.patch'
]
