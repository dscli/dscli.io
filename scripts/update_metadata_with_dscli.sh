#!/bin/bash

# ============================================================================
# update_metadata_with_dscli.sh
# 
# 智能metadata更新工具 - 简化版
# 功能：
# 1. 检查metadata规范文件是否存在
# 2. 检查dscli命令是否可用
# 3. 分析文章内容，基于docs/METADATA_SYSTEM.md规范
# 4. 生成给dscli的智能提示
# 5. 可选：自动调用dscli更新metadata
# ============================================================================

set -e  # 遇到错误立即退出

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

# 检查metadata规范文件
check_metadata_spec() {
    log_info "检查metadata规范文件..."
    
    if [ ! -f "docs/METADATA_SYSTEM.md" ]; then
        log_error "metadata规范文件不存在: docs/METADATA_SYSTEM.md"
        log_info "请确保项目包含完整的metadata系统文档"
        exit 1
    fi
    
    log_success "metadata规范文件存在"
}

# 检查dscli命令
check_dscli() {
    log_info "检查dscli命令..."
    
    if ! command -v dscli &> /dev/null; then
        log_error "dscli命令未找到"
        log_info "请确保dscli已正确安装并配置"
        log_info "安装方法: https://github.com/supertime/dscli"
        exit 1
    fi
    
    log_success "dscli命令可用"
}

# 检查文章文件
check_article_file() {
    local article_path="$1"
    
    log_info "检查文章文件: $article_path"
    
    if [ ! -f "$article_path" ]; then
        log_error "文章文件不存在: $article_path"
        exit 1
    fi
    
    # 检查文件是否包含frontmatter
    if [ "$(head -1 "$article_path")" != "---" ]; then
        log_error "文章文件缺少frontmatter（第一行不是'---'）"
        exit 1
    fi
    
    log_success "文章文件检查通过"
}

# 生成dscli提示
generate_dscli_prompt() {
    local article_path="$1"
    local article_content
    
    # 读取文章内容
    article_content=$(cat "$article_path")
    
    # 提取frontmatter部分
    local frontmatter=""
    local in_frontmatter=false
    local frontmatter_end=false
    
    while IFS= read -r line; do
        if [ "$line" = "---" ]; then
            if [ "$in_frontmatter" = false ]; then
                in_frontmatter=true
            else
                frontmatter_end=true
                break
            fi
        elif [ "$in_frontmatter" = true ] && [ "$frontmatter_end" = false ]; then
            frontmatter="$frontmatter$line\n"
        fi
    done <<< "$article_content"
    
    # 获取文章正文（用于分析）
    local body_content=""
    local after_frontmatter=false
    
    while IFS= read -r line; do
        if [ "$line" = "---" ]; then
            if [ "$after_frontmatter" = false ]; then
                after_frontmatter=true
            fi
        elif [ "$after_frontmatter" = true ]; then
            body_content="$body_content$line\n"
        fi
    done <<< "$article_content"
    
    # 统计字数
    local word_count=$(echo "$body_content" | wc -w)
    local reading_minutes=$(( (word_count + 199) / 200 ))  # 每分钟200字
    if [ $reading_minutes -lt 5 ]; then
        reading_minutes=5
    elif [ $reading_minutes -gt 60 ]; then
        reading_minutes=60
    fi
    
    # 分析技术栈（简单关键词匹配）
    local tech_stack=""
    if echo "$body_content" | grep -qi "\bgo\b\|golang\|goroutine\|channel"; then
        tech_stack="Go"
    elif echo "$body_content" | grep -qi "\bpython\b\|django\|flask"; then
        tech_stack="Python"
    elif echo "$body_content" | grep -qi "\bjavascript\b\|node\|react\|vue"; then
        tech_stack="JavaScript"
    elif echo "$body_content" | grep -qi "\bdocker\b\|container\|image"; then
        tech_stack="Docker"
    elif echo "$body_content" | grep -qi "\bkubernetes\b\|k8s\|pod"; then
        tech_stack="Kubernetes"
    fi
    
    # 分析难度级别
    local difficulty="beginner"
    if echo "$body_content" | grep -qi "\badvanced\b\|expert\|complex\|optimization"; then
        difficulty="advanced"
    elif echo "$body_content" | grep -qi "\bintermediate\b\|tutorial\|guide\|step-by-step"; then
        difficulty="intermediate"
    fi
    
    # 生成当前时间戳
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 构建dscli提示
    cat << EOF
我需要你帮我更新文章的metadata。以下是详细信息：

## 任务说明
根据docs/METADATA_SYSTEM.md提供的metadata规范，对文章文件进行分析，并生成更新的metadata。

## 文章信息
- 文件路径: $article_path
- 文章字数: $word_count
- 分析时间: $current_time

## 当前metadata
\`\`\`yaml
$frontmatter
\`\`\`

## 内容分析结果
基于文章内容分析，建议以下metadata更新：

1. **技术栈 (tech_stack)**: $tech_stack
2. **难度级别 (difficulty)**: $difficulty
3. **预计阅读时间 (estimated_reading_minutes)**: ${reading_minutes}分钟
4. **修改时间 (modified)**: 更新为当前时间: $current_time

## 规范要求
请参考docs/METADATA_SYSTEM.md中的metadata规范：
1. **必需字段**: title, date, modified, status, published
2. **推荐字段**: author, author_bio, excerpt, categories, tags, tech_stack, difficulty, estimated_reading_minutes
3. **其他字段**: 根据规范添加缺失的推荐字段

## 操作要求
1. **只能更新metadata部分**（frontmatter），不要修改文章正文内容
2. **保持YAML格式正确**，确保缩进和引号使用正确
3. **不要删除现有字段**，除非它们不符合规范
4. **添加缺失的推荐字段**，使用合理的默认值
5. **更新modified字段**为当前时间: $current_time

## 具体建议
请检查并更新以下字段：

1. **tech_stack**: 如果当前为空或需要更新，请设置为: $tech_stack
2. **difficulty**: 更新为: $difficulty
3. **estimated_reading_minutes**: 更新为: ${reading_minutes}分钟
4. **modified**: 更新为当前时间戳: $current_time
5. **检查必需字段**: 确保所有必需字段都存在且有效
6. **添加推荐字段**: 如果缺失，添加合理的默认值

## 重要提示
你可以使用文件操作工具来修改文件。请直接修改 $article_path 文件，只更新metadata部分（frontmatter）。
EOF
}

# 显示帮助信息
show_help() {
    cat << EOF
智能metadata更新工具 - 简化版

用法: $0 <slug> [选项]

参数:
  <slug>          文章slug（例如: my-article）

选项:
  --auto-update   自动调用dscli更新metadata
  --help, -h      显示此帮助信息

功能:
  1. ✅ 检查metadata规范文件是否存在
  2. ✅ 检查dscli命令是否可用
  3. ✅ 分析文章内容，基于docs/METADATA_SYSTEM.md规范
  4. ✅ 生成给dscli的智能提示
  5. ✅ （可选）自动调用dscli更新metadata

工作流程:
  1. 检查依赖和文件
  2. 分析文章内容
  3. 生成dscli提示
  4. （可选）自动调用dscli更新

注意:
  - 需要docs/METADATA_SYSTEM.md规范文件
  - 需要dscli已正确安装配置
  - 只能更新metadata，不修改文章正文
  - 默认模式：显示差异，不进行直接更新
  - 使用--auto-update才会实际更新文件

示例:
  $0 my-article                    # 显示分析结果和dscli提示
  $0 my-article --auto-update     # 自动调用dscli更新metadata
EOF
}

# 主函数
main() {
    # 参数解析
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    # 检查是否请求帮助
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_help
        exit 0
    fi
    
    # 解析参数
    SLUG=""
    AUTO_UPDATE="false"
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --auto-update)
                AUTO_UPDATE="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                if [ -z "$SLUG" ]; then
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
    
    # 检查必需参数
    if [ -z "$SLUG" ]; then
        log_error "请提供文章slug"
        show_help
        exit 1
    fi
    
    # 构建文章文件路径
    ARTICLE_PATH="content/posts/$SLUG/index.md"
    
    echo ""
    echo "=" * 80
    echo "🚀 智能metadata更新工具 - 简化版"
    echo "=" * 80
    echo ""
    echo "📝 文章slug: $SLUG"
    echo "📄 文章文件: $ARTICLE_PATH"
    echo ""
    
    # 步骤1: 检查依赖
    check_metadata_spec
    check_dscli
    check_article_file "$ARTICLE_PATH"
    
    # 步骤2: 生成dscli提示
    log_info "生成dscli提示..."
    echo ""
    echo "=" * 80
    echo "📊 METADATA智能分析报告"
    echo "=" * 80
    echo ""
    
    local dscli_prompt
    dscli_prompt=$(generate_dscli_prompt "$ARTICLE_PATH")
    
    # 显示分析结果
    echo "$dscli_prompt"
    echo ""
    
    # 步骤3: 根据选项处理
    if [ "$AUTO_UPDATE" = "true" ]; then
        log_info "自动调用dscli更新metadata..."
        echo ""
        echo "=" * 80
        echo "🤖 正在调用dscli更新metadata..."
        echo "=" * 80
        echo ""
        
        # 创建临时文件保存提示
        local temp_prompt_file=$(mktemp)
        echo "$dscli_prompt" > "$temp_prompt_file"
        
        # 调用dscli，使用chat子命令
        log_info "使用dscli chat命令更新metadata..."
        log_warning "注意：dscli chat命令可能会进入交互模式"
        log_info "如果脚本卡住，请按 Ctrl+C 中断，然后手动执行以下命令："
        echo ""
        echo "    dscli chat --mode markdown < \"$temp_prompt_file\""
        echo ""
        log_info "或者复制上面的分析报告手动操作"
        echo ""
        # 尝试调用dscli，设置超时
        local timeout_seconds=30
        log_info "设置超时时间: ${timeout_seconds}秒"
        
        # 检查是否有timeout命令
        if command -v timeout &> /dev/null; then
            # 使用timeout命令
            if timeout $timeout_seconds dscli chat --mode markdown < "$temp_prompt_file"; then
                log_success "dscli更新完成"
                echo ""
                echo "✅ 请检查metadata更新结果"
            else
                local exit_code=$?
                echo ""
                if [ $exit_code -eq 124 ]; then
                    log_error "dscli命令超时（${timeout_seconds}秒）"
                    echo "❌ dscli可能进入了交互模式，需要手动处理"
                else
                    log_error "dscli更新失败，退出码: $exit_code"
                fi
            fi
        else
            # 没有timeout命令，直接调用并提示用户
            log_warning "系统没有timeout命令，直接调用dscli（无超时控制）"
            log_info "如果脚本卡住，请按 Ctrl+C 中断"
            echo ""
            
            if dscli chat --mode markdown < "$temp_prompt_file"; then
                log_success "dscli更新完成"
                echo ""
                echo "✅ 请检查metadata更新结果"
            else
                local exit_code=$?
                echo ""
                log_error "dscli更新失败，退出码: $exit_code"
            fi
        fi
        
        # 如果失败，显示手动操作步骤
        if [ $? -ne 0 ]; then
            echo ""
            echo "📋 手动操作步骤："
            echo "1. 复制上面的分析报告"
            echo "2. 启动dscli: dscli chat --mode markdown"
            echo "3. 粘贴分析报告内容"
            echo "4. 按照提示完成metadata更新"
            echo ""
            echo "💡 提示文件保存在: $temp_prompt_file"
        fi
        # 清理临时文件
        rm -f "$temp_prompt_file"
    else
        log_success "分析完成"
        echo ""
        echo "📝 下一步：使用dscli根据上面的提示更新metadata"
        echo "💡 提示：复制上面的分析报告和dscli提示内容"
        echo "💡 或者使用: $0 $SLUG --auto-update 自动更新"
    fi
    
    echo ""
}

# 运行主函数
main "$@"