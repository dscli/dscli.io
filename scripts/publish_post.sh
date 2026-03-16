#!/bin/bash

# 默认发布文章脚本
# 包含metadata校验和自动提交功能

set -e
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

# 检查参数
if [ $# -eq 0 ]; then
    log_error "请提供文章slug"
    echo "用法: $0 <文章slug> [--auto-commit] [--no-validate]"
    echo "示例: $0 2026-03-04-春天-一个dscli复活 --auto-commit"
    echo ""
    echo "选项:"
    echo "  --auto-commit   自动提交到Git"
    echo "  --no-validate   跳过metadata校验"
    exit 1
fi

SLUG="$1"
POST_DIR="content/posts/$SLUG"
POST_FILE="$POST_DIR/index.md"

# 解析选项
AUTO_COMMIT=false
SKIP_VALIDATE=false

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-commit)
            AUTO_COMMIT=true
            shift
            ;;
        --no-validate)
            SKIP_VALIDATE=true
            shift
            ;;
        *)
            log_warning "未知选项: $1"
            shift
            ;;
    esac
done

# 检查文件是否存在
if [ ! -f "$POST_FILE" ]; then
    log_error "文章文件不存在: $POST_FILE"
    exit 1
fi

log_info "开始发布文章: $SLUG"
log_info "文章文件: $POST_FILE"

# 步骤1: 校验metadata（除非跳过）
if [ "$SKIP_VALIDATE" = false ]; then
    log_info "步骤1: 校验metadata..."
    if ! ./scripts/validate_metadata.sh "$POST_FILE"; then
        log_error "metadata校验失败，请修复后再发布"
        echo ""
        echo "修复建议:"
        echo "1. 运行 ./scripts/validate_metadata.sh \"$POST_FILE\" 查看详细错误"
        echo "2. 编辑文章文件: vim \"$POST_FILE\""
        echo "3. 添加缺失的必需字段"
        exit 1
    fi
    log_success "metadata校验通过"
else
    log_warning "跳过metadata校验"
fi

# 步骤2: 备份原文件
log_info "步骤2: 创建备份..."
BACKUP_FILE="$POST_FILE.backup.$(date +%Y%m%d%H%M%S)"
cp "$POST_FILE" "$BACKUP_FILE"
log_info "已创建备份: $BACKUP_FILE"

# 步骤3: 读取整个文件
CONTENT=$(cat "$POST_FILE")

# 检查是否已经有Frontmatter
if [[ "$CONTENT" != "---"* ]]; then
    log_error "文章没有Frontmatter格式"
    exit 1
fi

# 提取Frontmatter部分和正文
FRONTMATTER_END=$(echo "$CONTENT" | grep -n "^---$" | head -2 | tail -1 | cut -d: -f1)
FRONTMATTER=$(echo "$CONTENT" | head -n $((FRONTMATTER_END)))
BODY=$(echo "$CONTENT" | tail -n +$((FRONTMATTER_END + 1)))

# 步骤4: 更新Frontmatter
log_info "步骤3: 更新Frontmatter..."
CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
UPDATED_FRONTMATTER=$(echo "$FRONTMATTER" | sed "
    # 更新状态
    s/^status:.*$/status: publish/
    s/^published:.*$/published: true/
    
    # 更新修改时间（处理带引号和不带引号的情况）
    s/^modified:.*$/modified: \"$CURRENT_TIME\"/
    
    # 移除草稿相关字段
    /^draft_reason:/d
    /^target_publish_date:/d
")

# 步骤5: 写入新文件
log_info "步骤4: 写入新文件..."
echo -e "$UPDATED_FRONTMATTER\n$BODY" > "$POST_FILE.new"

# 验证新文件
if [[ $(head -1 "$POST_FILE.new") != "---" ]]; then
    log_error "生成的文件格式错误"
    mv "$BACKUP_FILE" "$POST_FILE"
    exit 1
fi

# 替换原文件
mv "$POST_FILE.new" "$POST_FILE"

# 步骤6: 显示更新结果
log_success "文章发布成功！"
echo ""
echo "✅ 已更新:"
echo "   - 状态: draft → publish"
echo "   - 发布状态: false → true"
echo "   - 修改时间: $CURRENT_TIME"
echo "   - 草稿字段: 已移除"
echo ""

# 步骤7: 自动提交（如果启用）
if [ "$AUTO_COMMIT" = true ]; then
    log_info "步骤5: 自动提交到Git..."
    
    # 检查Git状态
    if ! git status &> /dev/null; then
        log_error "当前目录不是Git仓库"
        exit 1
    fi
    
    # 添加文件
    git add "$POST_FILE"
    
    # 提交
    COMMIT_MSG="发布文章: $SLUG"
    if git commit -m "$COMMIT_MSG"; then
        log_success "已提交到Git: $COMMIT_MSG"
        
        # 显示Git状态
        echo ""
        log_info "Git状态:"
        git log --oneline -3
    else
        log_warning "Git提交失败，可能是没有更改或已提交"
    fi
else
    log_info "步骤5: 手动提交到Git"
    echo "运行以下命令提交:"
    echo "  git add \"$POST_FILE\""
    echo "  git commit -m \"发布文章: $SLUG\""
    echo "  git push"
fi

# 步骤8: 清理和下一步建议
echo ""
log_info "下一步操作:"
if [ "$AUTO_COMMIT" = false ]; then
    echo "1. 检查文章内容: cat \"$POST_FILE\" | head -40"
    echo "2. 提交到Git: git add \"$POST_FILE\" && git commit -m '发布文章: $SLUG'"
    echo "3. 推送到GitHub: git push"
else
    echo "1. 推送到GitHub: git push"
fi
echo "4. GitHub Actions会自动同步到WordPress"
echo ""

# 清理备份文件
if [ "$AUTO_COMMIT" = true ]; then
    # 自动提交模式下自动删除备份文件
    rm "$BACKUP_FILE"
    log_info "备份文件已自动删除"
else
    # 手动模式下询问用户
    read -p "是否删除备份文件？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$BACKUP_FILE"
        log_info "备份文件已删除"
    else
        log_info "备份文件保留在: $BACKUP_FILE"
    fi
fi
log_success "🎉 发布流程完成！"