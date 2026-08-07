#!/bin/bash
set -e

# 获取项目根目录（scripts 目录的上级目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# 蒲公英 API Key，可通过环境变量 PGYER_API_KEY 传入或直接在此填入
PGYER_API_KEY="${PGYER_API_KEY:-"d0b9d95dace3adac931a5f3a6ff1bcbf"}"

echo "=========================================="
echo "      测试版本：清理 -> 打包 -> 上传蒲公英 "
echo "=========================================="

# 1. 打包前删除 build/app-outs 文件夹
OUTPUT_DIR="$PROJECT_ROOT/build/app-outs"
echo "--> 1/3: 清理旧打包目录 ($OUTPUT_DIR)..."
rm -rf "$OUTPUT_DIR"

# 2. 调用测试打包脚本
echo "--> 2/3: 执行测试打包脚本 (build_test.sh)..."
"$SCRIPT_DIR/build_test.sh"

# 3. 提取最近 100 次提交记录并上传蒲公英
echo "--> 3/3: 提取最近 100 次提交记录并上传蒲公英..."

# 检查 PGYER_API_KEY 是否设置
if [ -z "$PGYER_API_KEY" ]; then
    echo "--------------------------------------------------------"
    echo "[警告] 未检测到 PGYER_API_KEY！"
    echo "请在环境变量中设置 export PGYER_API_KEY='你的蒲公英APIKey'"
    echo "或直接在脚本中修改 PGYER_API_KEY 变量。"
    echo "--------------------------------------------------------"
    exit 1
fi

# 获取当前分支最近 100 次 Git 提交记录
CHANGELOG=$(git log -n 100 --pretty=format:"%h %s (%an, %cd)" --date=short)

# 上传 build/app-outs 下所有的 apk 与 ipa
FILES_FOUND=0
for file in "$OUTPUT_DIR"/*.apk "$OUTPUT_DIR"/*.ipa; do
    if [ -f "$file" ]; then
        FILES_FOUND=$((FILES_FOUND + 1))
        filename=$(basename "$file")
        echo "正在上传 $filename 到蒲公英..."

        RESPONSE=$(curl -s -F "file=@$file" \
             -F "_api_key=$PGYER_API_KEY" \
             -F "buildUpdateDescription=$CHANGELOG" \
             https://www.pgyer.com/apiv2/app/upload)

        echo "上传响应: $RESPONSE"
    fi
done

if [ "$FILES_FOUND" -eq 0 ]; then
    echo "[错误] 产物目录 $OUTPUT_DIR 未找到可上传的 .apk 或 .ipa 文件！"
    exit 1
fi

echo "=========================================="
echo "      测试版本打包并上传蒲公英成功！      "
echo "=========================================="
