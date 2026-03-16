#!/bin/bash

# 增强版文章创建脚本
# 支持完整的metadata模板系统
# 用法: ./scripts/create_post_with_metadata.sh <slug> [选项]

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

# 显示帮助
show_help() {
    cat << EOF
增强版文章创建脚本

用法: $0 <slug> [选项]

选项:
  -t, --title <标题>         设置文章标题
  -e, --excerpt <摘要>       设置文章摘要
  -c, --categories <分类>    设置分类，多个用逗号分隔
  -g, --tags <标签>          设置标签，多个用逗号分隔
  -d, --date <日期>          设置发布日期 (格式: YYYY-MM-DD)
  -a, --author <作者>        设置作者 (默认: 杰西卡尔)
  -s, --status <状态>        设置文章状态 (默认: draft)
  --tech-stack <技术栈>      设置技术栈，多个用逗号分隔
  --difficulty <难度>        设置难度级别 (beginner/intermediate/advanced)
  --read-time <分钟>         设置预计阅读时间
  --no-date-prefix           不添加日期前缀
  --interactive              交互式模式
  --template <模板>          使用指定模板 (default/tutorial/story)
  -h, --help                 显示此帮助信息

示例:
  $0 my-article --title "我的文章" --categories "技术,教程" --tags "Go,AI"
  $0 my-article --interactive
  $0 my-article --no-date-prefix --title "我的故事" --template story

模板说明:
  default   默认文章模板
  tutorial  教程模板 (包含步骤和FAQ)
  story     故事模板 (章节结构)
EOF
}

# 默认值
SLUG=""
TITLE=""
EXCERPT=""
CATEGORIES="[\"未分类\"]"
TAGS="[\"文章\"]"
DATE=$(date +"%Y-%m-%d %H:%M:%S")
AUTHOR="杰西卡尔"
STATUS="draft"
TECH_STACK="[]"
DIFFICULTY="beginner"
READING_MINUTES="10"
ADD_DATE_PREFIX=true
INTERACTIVE=false
TEMPLATE="default"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--title)
            TITLE="$2"
            shift 2
            ;;
        -e|--excerpt)
            EXCERPT="$2"
            shift 2
            ;;
        -c|--categories)
            CATEGORIES="[\"$(echo "$2" | sed 's/,/\", \"/g')\"]"
            shift 2
            ;;
        -g|--tags)
            TAGS="[\"$(echo "$2" | sed 's/,/\", \"/g')\"]"
            shift 2
            ;;
        -d|--date)
            DATE="$2 12:00:00"
            shift 2
            ;;
        -a|--author)
            AUTHOR="$2"
            shift 2
            ;;
        -s|--status)
            STATUS="$2"
            shift 2
            ;;
        --tech-stack)
            TECH_STACK="[\"$(echo "$2" | sed 's/,/\", \"/g')\"]"
            shift 2
            ;;
        --difficulty)
            DIFFICULTY="$2"
            shift 2
            ;;
        --read-time)
            READING_MINUTES="$2"
            shift 2
            ;;
        --no-date-prefix)
            ADD_DATE_PREFIX=false
            shift
            ;;
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        *)
            if [[ -z "$SLUG" ]]; then
                SLUG="$1"
            else
                log_error "未知参数: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# 检查必要参数
if [[ -z "$SLUG" ]]; then
    log_error "必须提供文章slug"
    show_help
    exit 1
fi

# 交互式模式
if [[ "$INTERACTIVE" == true ]]; then
    echo ""
    echo "📝 创建新文章 - 交互式模式"
    echo "="*40
    
    # 标题
    if [[ -z "$TITLE" ]]; then
        read -p "文章标题: " TITLE
        if [[ -z "$TITLE" ]]; then
            TITLE=$(echo "$SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
            log_warning "使用slug作为标题: $TITLE"
        fi
    fi
    
    # 摘要
    if [[ -z "$EXCERPT" ]]; then
        read -p "文章摘要 (留空自动生成): " EXCERPT
    fi
    
    # 分类
    if [[ "$CATEGORIES" == '["未分类"]' ]]; then
        read -p "分类 (多个用逗号分隔，如: 技术,教程): " CATEGORIES_INPUT
        if [[ -n "$CATEGORIES_INPUT" ]]; then
            CATEGORIES="[\"$(echo "$CATEGORIES_INPUT" | sed 's/,/\", \"/g')\"]"
        fi
    fi
    
    # 标签
    if [[ "$TAGS" == '["文章"]' ]]; then
        read -p "标签 (多个用逗号分隔，如: Go,AI,教程): " TAGS_INPUT
        if [[ -n "$TAGS_INPUT" ]]; then
            TAGS="[\"$(echo "$TAGS_INPUT" | sed 's/,/\", \"/g')\"]"
        fi
    fi
    
    # 技术栈
    read -p "技术栈 (多个用逗号分隔，留空跳过): " TECH_STACK_INPUT
    if [[ -n "$TECH_STACK_INPUT" ]]; then
        TECH_STACK="[\"$(echo "$TECH_STACK_INPUT" | sed 's/,/\", \"/g')\"]"
    fi
    
    # 难度级别
    read -p "难度级别 (beginner/intermediate/advanced，默认: beginner): " DIFFICULTY_INPUT
    if [[ -n "$DIFFICULTY_INPUT" ]]; then
        DIFFICULTY="$DIFFICULTY_INPUT"
    fi
    
    # 阅读时间
    read -p "预计阅读时间 (分钟，默认: 10): " READING_MINUTES_INPUT
    if [[ -n "$READING_MINUTES_INPUT" ]]; then
        READING_MINUTES="$READING_MINUTES_INPUT"
    fi
    
    echo ""
fi

# 自动生成缺失的信息
if [[ -z "$TITLE" ]]; then
    TITLE=$(echo "$SLUG" | sed 's/[0-9]*-//g' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
fi

if [[ -z "$EXCERPT" ]]; then
    EXCERPT="这是关于 $TITLE 的文章，将分享相关的内容和经验。"
fi

# 添加日期前缀
if [[ "$ADD_DATE_PREFIX" == true ]] && [[ ! "$SLUG" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}- ]]; then
    DATE_PREFIX=$(date +"%Y-%m-%d")
    SLUG="$DATE_PREFIX-$SLUG"
    log_info "添加日期前缀: $SLUG"
fi

# 检查目录是否已存在
POST_DIR="content/posts/$SLUG"
if [[ -d "$POST_DIR" ]]; then
    log_error "文章目录已存在: $POST_DIR"
    exit 1
fi

# 创建目录
mkdir -p "$POST_DIR/images"
log_info "创建目录: $POST_DIR"

# 选择模板
TEMPLATE_FILE=""
case "$TEMPLATE" in
    tutorial)
        TEMPLATE_FILE="templates/tutorial.md"
        ;;
    story)
        TEMPLATE_FILE="templates/story.md"
        ;;
    *)
        TEMPLATE_FILE="templates/post.md"
        ;;
esac

# 检查模板文件是否存在
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    log_warning "模板文件不存在: $TEMPLATE_FILE，使用默认模板"
    TEMPLATE_CONTENT=$(cat << 'EOF'
---
title: "{{title}}"
date: "{{date}}"
status: draft
categories: {{categories}}
tags: {{tags}}
---

# {{title}}

开始你的写作...
EOF
)
else
    TEMPLATE_CONTENT=$(cat "$TEMPLATE_FILE")
fi

# 替换模板变量
CONTENT="$TEMPLATE_CONTENT"
CONTENT="${CONTENT//\{\{title\}\}/$TITLE}"
CONTENT="${CONTENT//\{\{date\}\}/$DATE}"
CONTENT="${CONTENT//\{\{excerpt\}\}/$EXCERPT}"
CONTENT="${CONTENT//\{\{categories\}\}/$CATEGORIES}"
CONTENT="${CONTENT//\{\{tags\}\}/$TAGS}"

# 添加额外的metadata
# 提取Frontmatter和正文
FRONTMATTER=$(echo "$CONTENT" | awk '/^---$/{i++}i==1')
BODY=$(echo "$CONTENT" | awk '/^---$/{i++}i==2')

# 构建完整的metadata
FULL_FRONTMATTER=$(cat << EOF
---
title: "$TITLE"
date: "$DATE"
modified: ""
status: $STATUS
published: false
author: "$AUTHOR"
author_bio: "全栈开发者，专注于开发工具和自动化"
excerpt: "$EXCERPT"
categories: $CATEGORIES
primary_category: ""
tags: $TAGS
tech_stack: $TECH_STACK
difficulty: "$DIFFICULTY"
estimated_reading_minutes: $READING_MINUTES
meta_title: "$TITLE"
meta_description: "$EXCERPT"
og_image: ""
og_description: ""
wordpress_post_format: "standard"
table_of_contents: true
license: "CC BY-NC-SA 4.0"
draft_reason: "新文章，待完善"
target_publish_date: ""
---
EOF
)

# 写入文件
echo -e "$FULL_FRONTMATTER\n$BODY" > "$POST_DIR/index.md"

log_success "文章创建成功！"
echo ""
echo "📄 文件位置: $POST_DIR/index.md"
echo "🖼️  图片目录: $POST_DIR/images/"
echo ""

# 显示创建的metadata
echo "📋 文章信息:"
echo "   标题: $TITLE"
echo "   Slug: $SLUG"
echo "   日期: $DATE"
echo "   状态: $STATUS"
echo "   作者: $AUTHOR"
echo "   分类: $CATEGORIES"
echo "   标签: $TAGS"
echo "   技术栈: $TECH_STACK"
echo "   难度: $DIFFICULTY"
echo "   阅读时间: $READING_MINUTES 分钟"
echo ""

# 下一步操作提示
log_info "下一步操作:"
echo "1. 编辑文章: vim $POST_DIR/index.md"
echo "2. 添加图片: 放到 $POST_DIR/images/ 目录"
echo "3. 提交到Git: git add $POST_DIR && git commit -m '添加文章: $SLUG'"
echo "4. 推送到GitHub: git push"
echo "5. 自动同步到WordPress"

# 打开编辑器（可选）
read -p "是否现在编辑文章？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ${EDITOR:-vim} "$POST_DIR/index.md"
fi