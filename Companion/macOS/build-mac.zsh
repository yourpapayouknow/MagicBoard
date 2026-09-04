#!/bin/zsh
set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="${0:A:h}"
SRC="${SCRIPT_DIR}/magicboard-companion-mac.swift"
BIN="${SCRIPT_DIR}/magicboard-companion-mac"

echo "🔨 正在编译 macOS 原生伴侣服务: ${SRC} -> ${BIN}"
swiftc -O "${SRC}" -o "${BIN}"
chmod +x "${BIN}"

echo "✅ 编译完成！"
ls -lh "${BIN}"
