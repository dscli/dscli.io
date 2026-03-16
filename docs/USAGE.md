# 极简博客发布系统使用指南

## 📋 目录

1. [🚀 快速开始](#快速开始)
2. [📝 文章格式](#文章格式)
3. [🎯 完整示例：从创建到发布](#完整示例从创建到发布)
4. [🔄 简化工作流程](#简化工作流程)
5. [🔧 高级用法](#高级用法)
6. [🛠️ 故障排除](#故障排除)
7. [📊 监控和状态](#监控和状态)
8. [🔒 安全最佳实践](#安全最佳实践)
9. [🎯 最佳实践](#最佳实践)
10. [📞 支持](#支持)
11. [🚀 下一步](#下一步)

## 🚀 快速开始

### 1. 创建你的第一篇文章

```bash
# 创建一篇新文章（自动添加日期前缀）
./create_post.sh my-first-post

# 使用标题和模板
./create_post.sh python-tutorial --title "Python入门教程" --template tutorial

# 创建故事（不添加日期前缀）
./create_post.sh my-story --template story --no-date
```

### 2. 编辑文章

编辑文件：`content/posts/my-first-post/index.md`

### 3. 添加图片

将图片放入：`content/posts/my-first-post/images/`

### 4. 提交到GitHub

```bash
git add .
git commit -m "Add post: my-first-post"
git push
```

### 5. 自动同步

GitHub Actions会自动检测变更并同步到WordPress。

## 📝 文章格式

### Frontmatter示例

```yaml
---
title: "文章标题"
date: "2026-01-01 12:00:00"
status: draft  # draft, publish, private
categories: ["分类1", "分类2"]
tags: ["标签1", "标签2"]
---
```

### 支持的模板

1. **default** - 默认文章模板
2. **tutorial** - 教程模板（包含步骤和FAQ）
3. **story** - 故事模板（章节结构）

## 🎯 完整示例：从创建到发布

### 🎯 目标
创建一个关于"使用Go语言开发CLI工具"的教程文章，并发布到WordPress。

### 📋 步骤概览
1. 创建文章
2. 编辑内容
3. 发布文章
4. 提交和同步

### 🚀 详细步骤

#### 步骤1：创建文章

```bash
# 创建教程文章
./scripts/create_post_with_metadata.sh go-cli-tutorial \
  --title "使用Go语言开发CLI工具完整指南" \
  --excerpt "从零开始学习如何使用Go语言开发功能完整的命令行工具，包含项目结构、参数解析、子命令、配置文件等核心功能。" \
  --categories "技术,教程,Go语言" \
  --tags "Go,CLI,命令行工具,开发教程,编程" \
  --tech-stack "Go语言,Cobra,Viper" \
  --difficulty "intermediate" \
  --read-time 25 \
  --template tutorial
```

**输出：**
```
[INFO] 添加日期前缀: 2026-03-15-go-cli-tutorial
[INFO] 创建目录: content/posts/2026-03-15-go-cli-tutorial
[SUCCESS] 文章创建成功！

📄 文件位置: content/posts/2026-03-15-go-cli-tutorial/index.md
🖼️  图片目录: content/posts/2026-03-15-go-cli-tutorial/images/

📋 文章信息:
   标题: 使用Go语言开发CLI工具完整指南
   Slug: 2026-03-15-go-cli-tutorial
   日期: 2026-03-15 12:00:00
   状态: draft
   作者: 杰西卡尔
   分类: ["技术", "教程", "Go语言"]
   标签: ["Go", "CLI", "命令行工具", "开发教程", "编程"]
   技术栈: ["Go语言", "Cobra", "Viper"]
   难度: intermediate
   阅读时间: 25 分钟
```

#### 步骤2：编辑文章内容

```bash
# 编辑文章
vim content/posts/2026-03-15-go-cli-tutorial/index.md
```

**编辑后的内容示例：**
```markdown
---
title: "使用Go语言开发CLI工具完整指南"
date: "2026-03-15 12:00:00"
modified: ""
status: draft
published: false
author: "杰西卡尔"
author_bio: "全栈开发者，专注于开发工具和自动化"
excerpt: "从零开始学习如何使用Go语言开发功能完整的命令行工具，包含项目结构、参数解析、子命令、配置文件等核心功能。"
categories: ["技术", "教程", "Go语言"]
primary_category: "技术"
tags: ["Go", "CLI", "命令行工具", "开发教程", "编程"]
tech_stack: ["Go语言", "Cobra", "Viper"]
difficulty: "intermediate"
estimated_reading_minutes: 25
meta_title: "Go语言CLI开发教程：从零到一构建命令行工具"
meta_description: "完整的Go语言CLI开发指南，涵盖项目初始化、参数解析、子命令系统、配置文件管理等核心功能，适合有一定Go基础的开发者。"
og_image: "images/go-cli-cover.png"
og_description: "学习使用Go语言构建功能完整的命令行工具，提升开发效率。"
wordpress_post_format: "standard"
table_of_contents: true
license: "CC BY-NC-SA 4.0"
draft_reason: "等待代码示例验证"
target_publish_date: "2026-03-18"
---

# 使用Go语言开发CLI工具完整指南

## 🎯 学习目标

通过本教程，你将学会：
- 使用Cobra库创建CLI应用结构
- 实现参数解析和子命令系统
- 使用Viper管理配置文件
- 添加日志和错误处理
- 打包和分发CLI工具

## 📋 前置要求

在开始之前，请确保：
- 已安装Go 1.20+版本
- 了解Go语言基础语法
- 熟悉命令行基本操作

## 🚀 开始学习

### 步骤1: 项目初始化

```bash
# 创建项目目录
mkdir my-cli && cd my-cli
go mod init github.com/yourname/my-cli

# 安装Cobra
go get -u github.com/spf13/cobra@latest
```

### 步骤2: 创建主命令

```go
// cmd/root.go
package cmd

import (
    "fmt"
    "os"
    "github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
    Use:   "mycli",
    Short: "My CLI工具",
    Long:  `一个功能完整的命令行工具示例`,
    Run: func(cmd *cobra.Command, args []string) {
        fmt.Println("欢迎使用My CLI工具")
    },
}

func Execute() {
    if err := rootCmd.Execute(); err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
}
```

### 步骤3: 添加子命令

```go
// cmd/version.go
package cmd

import (
    "fmt"
    "github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
    Use:   "version",
    Short: "显示版本信息",
    Run: func(cmd *cobra.Command, args []string) {
        fmt.Println("My CLI v1.0.0")
    },
}

func init() {
    rootCmd.AddCommand(versionCmd)
}
```

### 步骤4: 配置管理

```go
// config/config.go
package config

import (
    "github.com/spf13/viper"
    "log"
)

func InitConfig() {
    viper.SetConfigName("config")
    viper.SetConfigType("yaml")
    viper.AddConfigPath(".")
    
    if err := viper.ReadInConfig(); err != nil {
        log.Printf("配置文件未找到，使用默认配置")
    }
}
```

## 🔧 常见问题 (FAQ)

### Q1: 如何添加命令行参数？
**A:** 使用Cobra的Flags功能：
```go
var name string
rootCmd.PersistentFlags().StringVar(&name, "name", "", "用户名")
```

### Q2: 如何打包为可执行文件？
**A:** 使用Go的build命令：
```bash
go build -o mycli main.go
```

### Q3: 如何添加配置文件支持？
**A:** 使用Viper库，支持多种格式（YAML、JSON、TOML等）。

## 📚 进阶学习

如果你已经掌握了基础，可以继续学习：
- 添加插件系统
- 实现自动补全
- 集成API调用
- 添加测试覆盖率

## 🎉 总结

通过本教程，你学会了：
- 使用Cobra创建CLI应用结构
- 实现参数解析和子命令
- 管理配置文件
- 打包和分发工具

## 📖 扩展阅读

- [Cobra官方文档](https://github.com/spf13/cobra)
- [Viper配置管理](https://github.com/spf13/viper)
- [Go语言官方文档](https://golang.org/doc/)
```

#### 步骤3：添加图片

```bash
# 添加封面图片（如果有）
cp ~/Downloads/go-cli-cover.png content/posts/2026-03-15-go-cli-tutorial/images/
```

#### 步骤4：发布文章

```bash
# 发布文章（推荐使用增强版）
./scripts/publish_post_enhanced.sh 2026-03-15-go-cli-tutorial --auto-commit
```

**输出：**
```
[INFO] 开始发布文章: 2026-03-15-go-cli-tutorial
[INFO] 文章文件: content/posts/2026-03-15-go-cli-tutorial/index.md
[INFO] 步骤1: 校验metadata...
[SUCCESS] metadata校验通过
[INFO] 步骤2: 创建备份...
[INFO] 已创建备份: content/posts/2026-03-15-go-cli-tutorial/index.md.backup.20260315120000
[INFO] 步骤3: 更新Frontmatter...
[INFO] 步骤4: 写入新文件...
[SUCCESS] 文章发布成功！

✅ 已更新:
   - 状态: draft → publish
   - 发布状态: false → true
   - 修改时间: 2026-03-15 12:00:00
   - 草稿字段: 已移除

[INFO] 步骤5: 自动提交到Git...
[SUCCESS] 已提交到Git: 发布文章: 2026-03-15-go-cli-tutorial
```

#### 步骤5：推送到GitHub

```bash
# 推送到GitHub
git push
```

#### 步骤6：自动同步到WordPress

GitHub Actions会自动检测变更并同步到WordPress。你可以在以下位置查看同步状态：

1. **GitHub Actions页面**: `https://github.com/你的用户名/你的仓库/actions`
2. **WordPress后台**: 查看文章是否已创建/更新
3. **同步日志**: 查看详细的同步过程

## 📊 验证结果

### 1. 检查本地文件
```bash
# 查看metadata
head -30 content/posts/2026-03-15-go-cli-tutorial/index.md

# 检查状态
grep -E "^(status|published|modified):" content/posts/2026-03-15-go-cli-tutorial/index.md
```

**预期输出：**
```
status: publish
published: true
modified: "2026-03-15 12:00:00"
```

### 2. 检查Git状态
```bash
git status
git log --oneline -5
```

### 3. 检查WordPress同步
1. 登录WordPress后台
2. 进入"文章"页面
3. 查找标题为"使用Go语言开发CLI工具完整指南"的文章
4. 检查自定义字段是否包含完整的metadata

## 🎯 成功指标

✅ **文章创建成功** - 包含完整的metadata  
✅ **内容编辑完成** - 包含详细的教程内容  
✅ **文章已发布** - 状态更新为publish  
✅ **已提交到Git** - 代码已推送到GitHub  
✅ **已同步到WordPress** - 文章已同步到WordPress

**恭喜！你的文章现在已经可以在WordPress上访问了！** 🚀
## 🔄 简化工作流程

### 场景：创建一篇关于"Go语言并发编程"的文章

#### 第1步：创建文章 🆕

```bash
# 使用完整参数创建
./scripts/create_post_with_metadata.sh go-concurrency-tutorial \
  --title "Go语言并发编程指南" \
  --excerpt "深入理解Go语言的并发模型：Goroutine和Channel" \
  --categories "技术,编程,教程" \
  --tags "Go,并发,编程,教程" \
  --tech-stack "Go,Goroutine,Channel" \
  --difficulty "intermediate" \
  --read-time 15

# 或者使用交互式模式
./scripts/create_post_with_metadata.sh go-concurrency-tutorial --interactive
```

**创建结果：**
- 目录：`content/posts/go-concurrency-tutorial/`
- 文件：`index.md`（包含基础metadata）
- 图片目录：`images/`

#### 第2步：创作文章内容 ✍️

编辑 `content/posts/go-concurrency-tutorial/index.md`：

```markdown
---
title: "Go语言并发编程指南"
date: "2026-03-16 10:00:00"
modified: "2026-03-16 10:00:00"
status: draft
published: false
author: "杰西卡尔"
author_bio: "全栈开发者，专注于开发工具和自动化"
excerpt: "深入理解Go语言的并发模型：Goroutine和Channel"
categories: ["技术", "编程", "教程"]
primary_category: "技术"
tags: ["Go", "并发", "编程", "教程"]
tech_stack: ["Go", "Goroutine", "Channel"]
difficulty: "intermediate"
estimated_reading_minutes: 15
meta_title: "Go语言并发编程指南"
meta_description: "深入理解Go语言的并发模型：Goroutine和Channel"
og_image: "images/default.png"
og_description: "深入理解Go语言的并发模型：Goroutine和Channel"
wordpress_post_format: "standard"
table_of_contents: true
license: "CC BY-NC-SA 4.0"
draft_reason: "等待审核"
target_publish_date: "2026-03-23"
---

# Go语言并发编程指南

Go语言以其简洁而强大的并发模型而闻名。本文将深入探讨Go的并发编程...

## Goroutine：轻量级线程

Goroutine是Go语言并发编程的核心...

## Channel：通信共享内存

Channel是Goroutine之间通信的主要方式...

## 实战示例

让我们通过一个实际的例子来理解...

## 总结

Go语言的并发模型简洁而强大...
```

#### 第3步：使用dscli更新metadata 🤖

**dscli可以执行以下操作：**

1. **分析文章内容**：
   - 检测到文章讨论Goroutine和Channel
   - 建议添加相关技术栈标签
   - 分析文章长度，建议阅读时间

2. **检查metadata完整性**：
   - 确认所有必需字段都存在
   - 建议添加缺失的推荐字段
   - 验证字段格式是否正确

3. **智能建议**：
   - 建议添加`primary_category: "技术"`
   - 建议添加`wordpress_post_format: "standard"`
   - 建议添加`table_of_contents: true`

#### 第4步：发布文章 🚀

```bash
# 发布并自动提交到Git
./scripts/publish_post.sh go-concurrency-tutorial --auto-commit
```

**发布过程输出：**
```
[INFO] 开始发布文章: go-concurrency-tutorial
[INFO] 文章文件: content/posts/go-concurrency-tutorial/index.md
[INFO] 步骤1: 校验metadata...
[SUCCESS] metadata校验通过
[INFO] 步骤2: 创建备份...
[INFO] 已创建备份: content/posts/go-concurrency-tutorial/index.md.backup.20260316100000
[INFO] 步骤3: 更新发布状态...
[SUCCESS] 已更新发布状态
[INFO] 步骤4: 自动提交到Git...
[SUCCESS] 已提交到Git: 发布文章: Go语言并发编程指南
[SUCCESS] 文章发布成功！
```

**发布后的metadata变化：**
```yaml
status: publish           # draft → publish
published: true           # false → true
modified: "2026-03-16 11:30:00"  # 更新为当前时间
# 移除草稿相关字段
# draft_reason: "等待审核" (已移除)
# target_publish_date: "2026-03-23" (已移除)
```

#### 第5步：GitHub Actions自动同步 ⚡

发布并推送到远程仓库后：
1. GitHub Actions检测到`content/posts/go-concurrency-tutorial/`的变更
2. 自动运行同步脚本
3. 将文章同步到WordPress
4. 在GitHub Actions日志中显示同步结果

### 完整工作流程总结

| 步骤 | 工具 | 说明 |
|------|------|------|
| 1. 创建 | `create_post_with_metadata.sh` | 创建文章结构和基础metadata |
| 2. 创作 | 文本编辑器 | 编写文章内容 |
| 3. 优化 | dscli | 智能辅助完善metadata |
| 4. 发布 | `publish_post.sh` | 校验metadata并发布文章 |
| 5. 同步 | GitHub Actions | 自动同步到WordPress |

### 优势对比

**简化前：**
- 多个脚本需要管理
- 手动metadata更新繁琐
- 发布流程复杂
- 容易遗漏必需字段

**简化后：**
- 4个核心脚本，职责清晰
- dscli智能辅助metadata管理
- 一键发布，自动校验
- GitHub Actions自动同步

### 故障排除

**问题1：metadata校验失败**
```bash
# 查看详细错误
./scripts/validate_metadata.sh content/posts/go-concurrency-tutorial/index.md

# 根据建议修复metadata
# 然后重新发布
./scripts/publish_post.sh go-concurrency-tutorial
```

**问题2：同步失败**
1. 检查GitHub Actions日志
2. 确认WordPress API配置正确
3. 手动运行同步脚本：
   ```bash
   python3 scripts/sync_posts_enhanced.py
   ```

**问题3：需要撤销发布**
1. 编辑文章文件，将状态改回草稿：
   ```yaml
   status: draft
   published: false
   ```
2. 重新提交更改

### 扩展功能

如果需要更高级的功能，可以：

1. **批量操作**：使用dscli的批量metadata管理
2. **自定义模板**：创建自己的文章模板
3. **高级同步**：使用`sync_posts_enhanced.py`的手动同步选项
4. **统计分析**：添加文章访问统计功能

这个简化的工作流程既保持了易用性，又确保了文章质量，是博客文章管理的理想方案。

## 🔧 高级用法

### 批量创建文章

```bash
# 创建多篇文章
./create_post.sh article-1 --title "文章1"
./create_post.sh article-2 --title "文章2"
./create_post.sh article-3 --title "文章3"
```

### 手动触发同步

1. 访问GitHub仓库的Actions页面
2. 选择"Sync to WordPress"工作流
3. 点击"Run workflow"
4. 可以选择指定文章slug或同步所有文章

### 本地测试同步

```bash
# 设置环境变量
export WORDPRESS_URL="https://your-site.com"
export WORDPRESS_USERNAME="your-username"
export WORDPRESS_PASSWORD="your-app-password"

# 测试同步
python scripts/sync_posts.py --slugs "my-first-post"
```

## 🛠️ 故障排除

### 常见问题

#### 1. 创建文章失败

**症状**：`./create_post.sh` 命令失败

**解决**：
```bash
# 检查脚本权限
chmod +x create_post.sh

# 检查目录是否存在
ls -la content/posts/

# 检查slug是否已存在
./create_post.sh existing-slug  # 会提示目录已存在
```

#### 2. 同步失败

**症状**：GitHub Actions运行失败

**解决**：
1. 检查GitHub Actions日志
2. 验证WordPress API配置
3. 检查网络连接

#### 3. 文章重复创建

**症状**：WordPress中出现重复文章

**解决**：
1. 检查git_slug是否唯一
2. 清理WordPress中的重复文章
3. 确保每篇文章有唯一的slug

### 调试方法

#### 查看详细日志

```bash
# 设置详细日志
export PYTHONPATH=.
python -c "import scripts.sync_posts; scripts.sync_posts.main()" --slugs "test-post"
```

#### 检查文件哈希

```bash
# 计算文件哈希
python -c "
import hashlib
with open('content/posts/my-post/index.md', 'rb') as f:
    print(hashlib.sha256(f.read()).hexdigest())
"
```

## 🔄 工作流程

### 正常流程

```
用户操作 → GitHub → WordPress
    ↓         ↓         ↓
创建文章 → 提交代码 → 自动同步
    ↓         ↓         ↓
编辑内容 → 触发工作流 → 更新文章
    ↓         ↓         ↓
添加图片 → 检测变更 → 存储状态
```

### 错误处理流程

```
同步失败 → 创建Issue → 人工处理
    ↓         ↓         ↓
记录日志 → 发送通知 → 修复问题
    ↓         ↓         ↓
重试机制 → 状态更新 → 重新同步
```

## 📊 监控和状态

### 监控指标

1. **同步成功率**：成功同步的文章比例
2. **同步耗时**：从提交到完成的时间
3. **失败率**：同步失败的文章比例
4. **文章数量**：已同步的文章总数

### 状态检查

```bash
# 检查同步状态
curl -s "https://your-wordpress.com/wp-json/wp/v2/posts?per_page=1" | jq '.[0].meta'

# 检查GitHub Actions状态
curl -s "https://api.github.com/repos/your-username/your-repo/actions/runs" | jq '.workflow_runs[0].status'
```

## 🔒 安全最佳实践

### 1. 凭证管理

- 定期轮换WordPress应用密码（建议每90天）
- 使用最小权限原则
- 不要在代码中硬编码凭证

### 2. 访问控制

- 限制WordPress API访问频率
- 使用HTTPS连接
- 监控API调用日志

### 3. 数据备份

- 定期备份WordPress文章
- 备份Git仓库
- 备份同步状态

## 🎯 最佳实践

### 写作最佳实践

1. **使用有意义的slug**：`python-tutorial` 而不是 `post1`
2. **添加完整Frontmatter**：包含标题、日期、分类、标签
3. **使用模板**：根据内容类型选择合适的模板
4. **添加图片**：将图片放在images目录中
5. **定期提交**：完成一个章节就提交一次

### 技术最佳实践

1. **小批量提交**：一次提交不要包含太多文章
2. **测试同步**：在正式发布前测试同步
3. **监控日志**：定期检查同步日志
4. **更新文档**：保持文档与系统同步

## 📞 支持

### 获取帮助

1. **查看文档**：
   - `README.md` - 主文档
   - `docs/ARCHITECTURE.md` - 架构设计文档
   - `docs/USAGE.md` - 本使用指南
   - `docs/METADATA_SYSTEM.md` - metadata系统文档

2. **检查日志**：
   - GitHub Actions运行日志
   - WordPress API访问日志
   - 同步脚本输出日志

3. **寻求帮助**：
   - 创建GitHub Issue
   - 查看常见问题
   - 联系维护者

### 报告问题

报告问题时请提供：
1. 问题描述
2. 复现步骤
3. 错误日志
4. 环境信息
5. 期望结果

## 🚀 下一步

### 学习资源

1. **Markdown语法**：https://www.markdownguide.org/
2. **WordPress REST API**：https://developer.wordpress.org/rest-api/
3. **GitHub Actions**：https://docs.github.com/en/actions

### 进阶功能

1. **图片自动上传**：扩展同步脚本支持图片上传
2. **多平台发布**：支持发布到多个平台
3. **团队协作**：添加多作者支持
4. **内容日历**：集成内容日历视图

---

**现在你已经掌握了极简博客发布系统的使用方法！** 🎉

开始创作吧，让自动化系统处理繁琐的发布工作！
