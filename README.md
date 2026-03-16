# 极简博客发布系统

一个完全自动化的博客发布系统，本地操作极简，所有复杂逻辑都在GitHub Actions中处理。

## 🎯 设计理念

- **本地极简**：只需创建文件、编辑、提交
- **云端复杂**：所有同步逻辑都在GitHub Actions中
- **AI智能辅助**：dscli集成优化metadata管理
- **可靠同步**：基于文件哈希的幂等操作

## 🚀 快速开始（4步完成）

### 第1步：创建文章 🆕
```bash
./scripts/create_post_with_metadata.sh my-article --title "文章标题"
```

### 第2步：创作内容 ✍️
编辑 `content/posts/my-article/index.md`

### 第3步：智能更新metadata 🤖
```bash
./scripts/update_metadata_with_dscli.sh my-article --auto-update
```

### 第4步：发布文章 🚀
```bash
./scripts/publish_post.sh my-article --auto-commit
git push
```

**完成！** GitHub Actions会自动同步到WordPress。

## 📁 文件结构

```
.
├── content/posts/                    # 文章目录
│   └── {slug}/                      # 每篇文章一个目录
│       ├── index.md                 # 文章内容（完整metadata）
│       └── images/                  # 文章图片
├── scripts/                         # 核心脚本目录
│   ├── create_post_with_metadata.sh # 智能文章创建
│   ├── publish_post.sh              # 一键发布
│   ├── validate_metadata.sh         # metadata校验
│   ├── update_metadata_with_dscli.sh # dscli智能更新
│   ├── analyze_metadata.py          # metadata分析工具
│   ├── sync_posts_enhanced.py       # WordPress同步
│   └── README.md                    # 脚本使用说明
├── create_post.sh                   # 基础版创建工具（Shell）
├── .github/workflows/
│   └── sync-to-wordpress.yml        # GitHub Actions工作流
├── README.md                        # 本文档
└── docs/                            # 详细文档目录
    ├── ARCHITECTURE.md              # 架构设计文档
    ├── METADATA_SYSTEM.md           # metadata系统文档
    ├── USAGE.md                     # 完整使用指南
```

## 🔧 核心功能

### 🎯 智能metadata管理
- **AI辅助优化**：dscli集成分析文章内容
- **自动建议**：技术栈、难度级别、阅读时间
- **安全更新**：只更新metadata，不修改正文

### ⚡ 一键发布流程
- **自动校验**：metadata完整性检查
- **状态更新**：draft → publish，自动设置发布时间
- **自动提交**：可选自动提交到Git

### 🔄 可靠同步机制
- **幂等操作**：基于SHA256文件哈希
- **增量同步**：只同步变更的文件
- **错误隔离**：单篇文章失败不影响其他

### 🛡️ 完善错误处理
- **自动告警**：失败时创建GitHub Issue
- **详细日志**：完整的同步过程记录
- **防循环机制**：避免重复触发

## 📚 详细文档

### 1. [架构设计](docs/ARCHITECTURE.md)
完整的系统架构设计，包含：
- 设计理念和架构概览
- 核心组件详细说明
- 智能工作流程
- 安全设计和性能优化
- 系统监控和架构演进

### 2. [metadata系统](docs/METADATA_SYSTEM.md)
完整的metadata管理系统，包含：
- metadata字段规范和示例
- 必需字段和推荐字段
- 技术栈、难度级别等高级字段
- 智能更新和校验机制
- 常见问题和解决方案

### 3. [使用指南](docs/USAGE.md)
完整的使用指南，包含：
- 从创建到发布的完整示例
- 简化工作流程（4步完成）
- 高级用法和故障排除
- 监控状态和最佳实践
- 安全配置和测试方法

### 4. [脚本使用说明](scripts/README.md)
所有脚本的详细使用说明，包含：
- 核心工作流程（4步）
- 每个脚本的功能和选项
- 示例命令和输出
- 常见问题解答
- 版本历史

## ⚙️ 配置要求

### GitHub Secrets
需要在GitHub仓库中设置以下Secrets：

1. `WORDPRESS_URL` - WordPress站点URL（如：https://example.com）
2. `WORDPRESS_USERNAME` - WordPress用户名
3. `WORDPRESS_PASSWORD` - WordPress应用密码

### WordPress配置
1. 确保REST API已启用
2. 创建应用密码（用户设置 → 应用密码）
3. 确保有发布文章的权限

## 🛠️ 开发指南

### 扩展功能
1. **图片自动上传**：扩展sync_posts_enhanced.py支持图片上传
2. **多作者支持**：扩展metadata系统支持多作者
3. **内容日历**：可视化内容发布计划

### 测试
```bash
# 测试本地创建
./scripts/create_post_with_metadata.sh test-post --title "测试文章"

# 测试metadata校验
./scripts/validate_metadata.sh content/posts/test-post/index.md

# 测试发布流程
./scripts/publish_post.sh test-post
```

## 📞 支持

### 获取帮助
1. 查看详细文档（推荐先看[使用指南](docs/USAGE.md)）
2. 检查GitHub Actions日志
3. 创建GitHub Issue

### 报告问题
报告问题时请提供：
1. 问题描述
2. 复现步骤
3. 错误日志
4. 环境信息

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📅 更新日志

### v1.1.0 (2026-03-16)
- **AI智能辅助**：添加dscli智能metadata更新工具
- **简化工作流程**：优化为4步完成（创建→编辑→智能更新→发布）
- **增强发布脚本**：集成metadata校验和自动提交
- **完善文档**：更新架构文档和使用指南

### v1.0.0 (2026-03-15)
- **初始版本**：极简本地操作，复杂云端逻辑
- **自动同步**：基于GitHub Actions的WordPress同步
- **无状态设计**：不在Git中存储状态信息
- **可靠同步**：基于文件哈希的幂等操作

---

**现在开始使用** → 查看[使用指南](docs/USAGE.md)获取完整教程