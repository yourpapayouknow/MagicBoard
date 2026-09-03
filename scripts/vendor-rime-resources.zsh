#!/bin/zsh
# 固定并下载 MagicBoard 离线中文输入资源
set -euo pipefail

project_root=${0:A:h:h}
output_dir="$project_root/Keyboard/RimeResources"
staging_dir=$(mktemp -d)
prelude_commit=082425e
luna_commit=56b934b
double_commit=01a1328
essay_commit=e9b1a37
stroke_commit=1e8fff9b9494ddec23b0cbc526bcfd8171a6fd48
librimekit_commit=efcb049af1cd854b16e5d248afbcac71ace02cc3
opencc_commit=26753884f1984add422f3b0249ccee8613deaff6
opencc_url=https://github.com/rime/librime/releases/download/1.16.1/rime-deps-de4700e-macOS-universal.tar.bz2

mkdir -p "$output_dir/opencc" "$output_dir/Licenses" "$staging_dir/opencc"

# 下载固定提交中的单个资源
fetch() {
    local repository=$1
    local commit=$2
    local file=$3
    local destination=$4
    curl -fsSL "https://raw.githubusercontent.com/$repository/$commit/$file" -o "$destination"
}

for file in key_bindings.yaml punctuation.yaml symbols.yaml; do
    fetch rime/rime-prelude "$prelude_commit" "$file" "$output_dir/$file"
done

for file in luna_pinyin.dict.yaml luna_pinyin.schema.yaml luna_pinyin_simp.schema.yaml pinyin.yaml; do
    fetch rime/rime-luna-pinyin "$luna_commit" "$file" "$output_dir/$file"
done

for file in double_pinyin.schema.yaml double_pinyin_abc.schema.yaml double_pinyin_flypy.schema.yaml double_pinyin_mspy.schema.yaml double_pinyin_pyjj.schema.yaml double_pinyin_st.schema.yaml; do
    fetch rime/rime-double-pinyin "$double_commit" "$file" "$output_dir/$file"
done

fetch rime/rime-essay "$essay_commit" essay.txt "$output_dir/essay.txt"
fetch rime/rime-stroke "$stroke_commit" stroke.dict.yaml "$output_dir/stroke.dict.yaml"
fetch rime/rime-stroke "$stroke_commit" stroke.schema.yaml "$output_dir/stroke.schema.yaml"

fetch rime/rime-prelude "$prelude_commit" LICENSE "$output_dir/Licenses/rime-prelude-GPL-3.0.txt"
fetch rime/rime-luna-pinyin "$luna_commit" LICENSE "$output_dir/Licenses/rime-luna-pinyin-GPL-3.0.txt"
fetch rime/rime-double-pinyin "$double_commit" LICENSE "$output_dir/Licenses/rime-double-pinyin-GPL-3.0.txt"
fetch rime/rime-essay "$essay_commit" LICENSE "$output_dir/Licenses/rime-essay-GPL-3.0.txt"
fetch rime/rime-stroke "$stroke_commit" LICENSE "$output_dir/Licenses/rime-stroke-GPL-3.0.txt"
fetch zhanggenlove/LibrimeKit "$librimekit_commit" LICENSE "$output_dir/Licenses/LibrimeKit-BSD-3-Clause.txt"
fetch zhanggenlove/LibrimeKit "$librimekit_commit" THIRD_PARTY_LICENSES.md "$output_dir/Licenses/LibrimeKit-third-party.md"
fetch BYVoid/OpenCC "$opencc_commit" LICENSE "$output_dir/Licenses/OpenCC-Apache-2.0.txt"

# 提取与 librime 1.16.1 匹配的简体转换资源
curl -fsSL "$opencc_url" -o "$staging_dir/opencc.tar.bz2"
tar -xjf "$staging_dir/opencc.tar.bz2" -C "$staging_dir/opencc" \
    share/opencc/t2s.json \
    share/opencc/TSCharacters.ocd2 \
    share/opencc/TSPhrases.ocd2
cp "$staging_dir/opencc/share/opencc/t2s.json" "$output_dir/opencc/"
cp "$staging_dir/opencc/share/opencc/TSCharacters.ocd2" "$output_dir/opencc/"
cp "$staging_dir/opencc/share/opencc/TSPhrases.ocd2" "$output_dir/opencc/"
