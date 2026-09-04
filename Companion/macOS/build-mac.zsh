#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SRC="${SCRIPT_DIR}/cpmac.swift"
BIN="${SCRIPT_DIR}/cpmac"

echo "🔨 正在编译 macOS 伴侣服务: ${SRC} -> ${BIN}"
swiftc -O "${SRC}" -o "${BIN}"
chmod +x "${BIN}"

echo "✅ 编译完成"
ls -lh "${BIN}"
