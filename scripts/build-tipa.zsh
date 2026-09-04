#!/bin/zsh

# 构建并预签 TrollStore 安装包
set -euo pipefail

readonly script_dir="${0:A:h}"
readonly project_dir="${script_dir:h}"
readonly build_dir="${project_dir}/build"
readonly derived_dir="${build_dir}/DerivedData"
readonly stage_dir="${build_dir}/stage"
readonly payload_dir="${stage_dir}/Payload"
readonly artifact="${build_dir}/MagicBoard.tipa"
readonly host_entitlements="${project_dir}/App/MagicBoard.entitlements"
readonly keyboard_entitlements="${project_dir}/Keyboard/MagicBoardKeyboard.entitlements"

# 报告构建错误
fail() {
  print -u2 -r -- "MagicBoard: $1"
  exit 1
}

# 检查外部命令
needcmd() {
  command -v "$1" >/dev/null 2>&1 || fail "缺少命令：$1"
}

# 检查签名权限
chksign() {
  local binary_path="$1"
  local dump_path="$2"
  ldid -e "$binary_path" > "$dump_path"
  plutil -lint "$dump_path" >/dev/null
  local group_id
  group_id=$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.application-groups:0' "$dump_path")
  [[ "$group_id" == "group.com.iwmei.magicboard" ]] || fail "App Group 签名不匹配：$binary_path"
}

# 检查 HID 派发权限
chkhid() {
  local host_dump="$1"
  local keyboard_dump="$2"
  if /usr/libexec/PlistBuddy -c 'Print :com.apple.private.hid.client.event-dispatch' "$host_dump" >/dev/null 2>&1; then
    fail "主 App 不应携带 HID 派发权限"
  fi
  local hid_dispatch
  hid_dispatch=$(/usr/libexec/PlistBuddy -c 'Print :com.apple.private.hid.client.event-dispatch' "$keyboard_dump")
  [[ "$hid_dispatch" == "true" ]] || fail "键盘 HID 派发权限缺失"
}

needcmd xcodegen
needcmd xcodebuild
needcmd ldid
needcmd plutil
needcmd zip
needcmd unzip
needcmd rg
[[ -x /usr/libexec/PlistBuddy ]] || fail "缺少命令：/usr/libexec/PlistBuddy"

xcodegen generate --spec "${project_dir}/project.yml" --project "${project_dir}"

rm -rf "$derived_dir" "$stage_dir"
rm -f "$artifact"
mkdir -p "$build_dir" "$payload_dir"

xcodebuild \
  -project "${project_dir}/MagicBoard.xcodeproj" \
  -scheme MagicBoard \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_dir" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  ONLY_ACTIVE_ARCH=NO \
  build

readonly product_app="${derived_dir}/Build/Products/Release-iphoneos/MagicBoard.app"
readonly staged_app="${payload_dir}/MagicBoard.app"
[[ -d "$product_app" ]] || fail "未找到构建产物：$product_app"

ditto "$product_app" "$staged_app"
for staged_item in "$staged_app" "$staged_app"/**/*(D); do
  xattr -c "$staged_item"
done
rm -rf "$staged_app/_CodeSignature" "$staged_app/PlugIns/MagicBoardKeyboard.appex/_CodeSignature"
rm -f "$staged_app/embedded.mobileprovision" "$staged_app/PlugIns/MagicBoardKeyboard.appex/embedded.mobileprovision"

readonly host_binary="${staged_app}/MagicBoard"
readonly keyboard_binary="${staged_app}/PlugIns/MagicBoardKeyboard.appex/MagicBoardKeyboard"
[[ -f "$host_binary" ]] || fail "未找到主 App 可执行文件"
[[ -f "$keyboard_binary" ]] || fail "未找到 Keyboard Extension 可执行文件"

ldid -S"$keyboard_entitlements" "$keyboard_binary"
ldid -S"$host_entitlements" "$host_binary"

chksign "$host_binary" "${build_dir}/host-entitlements.plist"
chksign "$keyboard_binary" "${build_dir}/keyboard-entitlements.plist"
chkhid "${build_dir}/host-entitlements.plist" "${build_dir}/keyboard-entitlements.plist"

readonly host_id=$(plutil -extract CFBundleIdentifier raw "$staged_app/Info.plist")
readonly keyboard_id=$(plutil -extract CFBundleIdentifier raw "$staged_app/PlugIns/MagicBoardKeyboard.appex/Info.plist")
readonly host_version=$(plutil -extract CFBundleShortVersionString raw "$staged_app/Info.plist")
readonly keyboard_version=$(plutil -extract CFBundleShortVersionString raw "$staged_app/PlugIns/MagicBoardKeyboard.appex/Info.plist")
readonly host_build=$(plutil -extract CFBundleVersion raw "$staged_app/Info.plist")
readonly keyboard_build=$(plutil -extract CFBundleVersion raw "$staged_app/PlugIns/MagicBoardKeyboard.appex/Info.plist")
readonly open_access=$(plutil -extract NSExtension.NSExtensionAttributes.RequestsOpenAccess raw "$staged_app/PlugIns/MagicBoardKeyboard.appex/Info.plist")
[[ "$host_id" == "com.iwmei.magicboard" ]] || fail "主 App Bundle ID 不匹配"
[[ "$keyboard_id" == "com.iwmei.magicboard.keyboard" ]] || fail "键盘 Bundle ID 不匹配"
[[ "$host_version" == "$keyboard_version" ]] || fail "主 App 与键盘版本不匹配"
[[ "$host_build" == "$keyboard_build" ]] || fail "主 App 与键盘构建号不匹配"
[[ "$open_access" == "true" ]] || fail "RequestsOpenAccess 未启用"

(
  cd "$stage_dir"
  COPYFILE_DISABLE=1 /usr/bin/zip -qry "$artifact" Payload
)

unzip -tq "$artifact" >/dev/null
unzip -Z1 "$artifact" | rg -q '^Payload/MagicBoard[.]app/Info[.]plist$' || fail "tipa 缺少主 App Info.plist"
unzip -Z1 "$artifact" | rg -q '^Payload/MagicBoard[.]app/PlugIns/MagicBoardKeyboard[.]appex/Info[.]plist$' || fail "tipa 缺少键盘 Info.plist"
unzip -Z1 "$artifact" | rg -q '^Payload/MagicBoard[.]app/PlugIns/MagicBoardKeyboard[.]appex/RimeResources/build/luna_pinyin[.]table[.]bin$' || fail "tipa 缺少 Rime 预编译二进制词典"

print -r -- "生成完成：$artifact（${host_version} (${host_build})）"
