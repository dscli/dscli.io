#!/bin/bash

# metadata校验脚本
# 检查文章是否包含必需的metadata字段

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 必需字段定义
REQUIRED_FIELDS=(
    "title"
    "date"
    "author"
    "excerpt"
    "categories"
    "tags"
)

# 推荐字段（非必需，但建议包含）
RECOMMENDED_FIELDS=(
    "status"
    "published"
    "modified"
    "meta_title"
    "meta_description"
    "og_image"
    "og_description"
    "primary_category"
    "tech_stack"
    "difficulty"
    "estimated_reading_minutes"
    "license"
)

# 检查参数
if [ $# -eq 0 ]; then
    log_error "请提供文章文件路径"
    echo "用法: $0 <文章文件路径>"
    echo "示例: $0 content/posts/2026-03-04-春天-一个dscli复活/index.md"
    exit 1
fi

POST_FILE="$1"

# 检查文件是否存在
if [ ! -f "$POST_FILE" ]; then
    log_error "文章文件不存在: $POST_FILE"
    exit 1
fi

log_info "开始校验metadata: $POST_FILE"

# 读取文件内容
CONTENT=$(cat "$POST_FILE")

# 检查是否包含Frontmatter
if [[ "$CONTENT" != "---"* ]]; then
    log_error "文章没有Frontmatter格式"
    exit 1
fi

# 提取Frontmatter部分
FRONTMATTER_END=$(echo "$CONTENT" | grep -n "^---$" | head -2 | tail -1 | cut -d: -f1)
FRONTMATTER=$(echo "$CONTENT" | head -n $((FRONTMATTER_END)))

# 检查必需字段
MISSING_REQUIRED=()
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$FRONTMATTER" | grep -q "^${field}:"; then
        MISSING_REQUIRED+=("$field")
    fi
done

# 检查推荐字段
MISSING_RECOMMENDED=()
for field in "${RECOMMENDED_FIELDS[@]}"; do
    if ! echo "$FRONTMATTER" | grep -q "^${field}:"; then
        MISSING_RECOMMENDED+=("$field")
    fi
done

# 输出结果
echo ""
echo "📋 Metadata校验结果"
echo "=================="

if [ ${#MISSING_REQUIRED[@]} -eq 0 ]; then
    log_success "✅ 所有必需字段都已包含"
else
    log_error "❌ 缺少必需字段:"
    for field in "${MISSING_REQUIRED[@]}"; do
        echo "   - $field"
    done
    echo ""
    echo "建议添加以下字段到Frontmatter:"
    for field in "${MISSING_REQUIRED[@]}"; do
        case $field in
            "title")
                echo "  title: \"文章标题\""
                ;;
            "date")
                echo "  date: \"$(date +"%Y-%m-%d %H:%M:%S")\""
                ;;
            "author")
                echo "  author: \"你的名字\""
                ;;
            "excerpt")
                echo "  excerpt: \"文章摘要，用于SEO和列表展示\""
                ;;
            "categories")
                echo "  categories: [\"默认分类\"]"
                ;;
            "tags")
                echo "  tags: [\"默认标签\"]"
                ;;
        esac
    done
fi

if [ ${#MISSING_RECOMMENDED[@]} -eq 0 ]; then
    log_success "✅ 所有推荐字段都已包含"
else
    log_warning "⚠️  缺少推荐字段:"
    for field in "${MISSING_RECOMMENDED[@]}"; do
        echo "   - $field"
    done
    echo ""
    echo "建议添加以下字段以增强SEO和用户体验:"
    for field in "${MISSING_RECOMMENDED[@]}"; do
        case $field in
            "meta_title")
                echo "  meta_title: \"SEO标题（通常与title相同）\""
                ;;
            "meta_description")
                echo "  meta_description: \"SEO描述（通常与excerpt相同）\""
                ;;
            "og_image")
                echo "  og_image: \"images/cover.png\""
                ;;
            "og_description")
                echo "  og_description: \"社交媒体分享描述\""
                ;;
            "primary_category")
                echo "  primary_category: \"主要分类\""
                ;;
            "tech_stack")
                echo "  tech_stack: [\"技术栈1\", \"技术栈2\"]"
                ;;
            "difficulty")
                echo "  difficulty: \"beginner|intermediate|advanced\""
                ;;
            "estimated_reading_minutes")
                echo "  estimated_reading_minutes: 10"
                ;;
            "license")
                echo "  license: \"CC BY-NC-SA 4.0\""
                ;;
        esac
    done
fi

echo ""
echo "📊 统计信息:"
echo "  - 必需字段: ${#REQUIRED_FIELDS[@]}个"
echo "  - 推荐字段: ${#RECOMMENDED_FIELDS[@]}个"
echo "  - 缺少必需字段: ${#MISSING_REQUIRED[@]}个"
echo "  - 缺少推荐字段: ${#MISSING_RECOMMENDED[@]}个"

# 返回状态码
if [ ${#MISSING_REQUIRED[@]} -gt 0 ]; then
    exit 1
else
    exit 0
fi