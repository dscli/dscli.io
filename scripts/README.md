# 博客文章管理脚本

## 简化后的脚本结构

```
scripts/
├── create_post_with_metadata.sh    # 创建文章
├── publish_post.sh                 # 发布文章（默认）
├── validate_metadata.sh            # 校验metadata
├── sync_posts_enhanced.py          # WordPress同步工具
├── analyze_metadata.py             # metadata分析工具（Python）
├── update_metadata_with_dscli.sh   # 智能metadata更新工具
└── README.md                       # 使用说明
```

## 核心工作流程（4步）

### 第1步：创建文章 🆕
```bash
./scripts/create_post_with_metadata.sh <slug> [选项]
```

**常用选项：**
```bash
# 基本创建
./scripts/create_post_with_metadata.sh my-article --title "文章标题"

# 完整参数创建
./scripts/create_post_with_metadata.sh go-tutorial \
  --title "Go语言入门教程" \
  --excerpt "从零开始学习Go语言编程" \
  --categories "技术,教程" \
  --tags "Go,编程,教程" \
  --tech-stack "Go,VS Code" \
  --difficulty "beginner"

# 交互式创建
./scripts/create_post_with_metadata.sh my-story --interactive
```

### 第2步：创作文章内容 ✍️
编辑 `content/posts/<slug>/index.md` 文件：
```markdown
---
title: "文章标题"
date: "2026-03-16 10:00:00"
author: "杰西卡尔"
excerpt: "文章摘要"
categories: ["技术", "教程"]
tags: ["Go", "编程"]
status: draft
published: false
---

# 文章标题

这里是文章正文内容...
### 第3步：使用dscli智能更新metadata 🤖

### 第3步：使用dscli智能更新metadata 🤖

**方法1：使用智能工具（推荐）**
```bash
# 分析文章并生成dscli提示
./scripts/update_metadata_with_dscli.sh <slug>

# 只显示分析结果
./scripts/update_metadata_with_dscli.sh <slug> --dry-run
```

**方法2：手动使用dscli**
dscli可以：
1. 读取metadata规范（参考 `docs/METADATA_SYSTEM.md`）
2. 分析文章内容
3. 智能建议metadata字段
4. 验证metadata完整性
4. 验证metadata完整性

### 第4步：发布文章 🚀
```bash
./scripts/publish_post.sh <slug> [--auto-commit]
```

**发布流程：**
1. ✅ **检查metadata完整性**（集成validate功能）
2. 🔄 **更新发布状态**：
   - `status: draft → publish`
   - `published: false → true`
   - `modified: 更新为当前时间`
3. 💾 **自动提交到Git**（如果使用`--auto-commit`）
4. 📤 **提示下一步操作**（包括push到远程）

**示例：**
```bash
# 发布并自动提交
./scripts/publish_post.sh my-article --auto-commit

# 发布但不自动提交
./scripts/publish_post.sh my-article
```

## 脚本详细说明

### 1. create_post_with_metadata.sh
**功能：** 创建新的博客文章，包含完整的metadata模板
**特点：**
- 自动生成目录结构
- 提供交互式参数输入
- 包含所有必需和推荐的metadata字段
- 支持技术栈、难度级别等高级字段

### 2. publish_post.sh
**功能：** 发布文章，包含metadata校验和自动提交
**特点：**
- 自动校验metadata完整性
- 更新文章状态为"已发布"
### 5. analyze_metadata.py
**功能：** Python实现的metadata分析工具
**特点：**
- 分析文章内容，提取技术关键词
- 评估难度级别和阅读时间
### 6. update_metadata_with_dscli.sh
**功能：** 智能metadata更新工具，支持自动调用dscli
**特点：**
- 先commit当前所有更改到Git
- 分析文章内容，基于metadata规范
- 生成给dscli的智能提示
- 支持自动调用dscli更新metadata
- 只能更新metadata部分，不修改文章内容
**使用模式：**
```bash
# 基本模式：生成dscli提示
./scripts/update_metadata_with_dscli.sh <slug>

# dry-run模式：只显示分析结果
./scripts/update_metadata_with_dscli.sh <slug> --dry-run

# 自动更新模式：自动调用dscli
./scripts/update_metadata_with_dscli.sh <slug> --auto-update
```
./scripts/update_metadata_with_dscli.sh content/posts/my-article/index.md --auto-update
```

**工作流程：**
1. ✅ 检查Git状态，commit当前更改
2. ✅ 分析文章内容和metadata规范
3. ✅ 生成智能更新建议
4. ✅ 提供dscli提示，只更新metadata
5. ✅ （可选）自动调用dscli更新

## GitHub Actions自动同步 ⚡

发布后，GitHub Actions会自动检测变更并同步到WordPress：
- **触发条件：** `push`到`main`分支的`content/posts/**`路径
- **同步脚本：** 使用内置的同步逻辑
- **幂等同步：** 基于文件哈希，避免重复同步
### Q: 如何批量更新文章？
A: 使用dscli的批量metadata管理功能，或使用智能工具分析多篇文章

### Q: 如何智能更新metadata？
## 版本历史

- **2026-03-16:** 添加智能metadata更新工具
- **2026-03-16:** 简化脚本结构，移除不必要的脚本
- **2026-03-15:** 创建增强版发布脚本
- **2026-03-14:** 创建metadata校验脚本
- **2026-03-13:** 创建文章创建脚本

### Q: 如何修复metadata错误？
A: 运行 `./scripts/validate_metadata.sh <文章文件>` 查看详细错误和建议

### Q: 如何撤销发布？
A: 编辑文章文件，将 `status: publish` 改回 `status: draft`，`published: true` 改回 `published: false`

### Q: 如何手动同步到WordPress？
A: 运行 `python3 scripts/sync_posts_enhanced.py`

### Q: 如何批量更新文章？
A: 使用dscli的批量metadata管理功能

## 版本历史

- **2026-03-16:** 简化脚本结构，移除不必要的脚本
- **2026-03-15:** 创建增强版发布脚本
- **2026-03-14:** 创建metadata校验脚本
- **2026-03-13:** 创建文章创建脚本

---

**注意：** 所有脚本都使用 `set -e` 确保错误时立即退出，请确保在执行前备份重要数据。