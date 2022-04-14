name: llvm
version: 13.0.1
repo: core
source: https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/llvm-13.0.1.src.tar.xz
deps: [
  'cmake'
]
mkdeps: []
extras: [
  'https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/clang-13.0.1.src.tar.xz',
  'https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/compiler-rt-13.0.1.src.tar.xz'
]
