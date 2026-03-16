#!/usr/bin/env python3
"""
文章metadata分析工具
分析文章内容并智能建议metadata更新
"""

import os
import re
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional

# ============================================================================
# 配置和常量
# ============================================================================

# 尝试导入yaml，但不是必需的
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

# ============================================================================
# 工具函数
# ============================================================================

def parse_frontmatter_simple(frontmatter_text: str) -> Dict:
    """简单的frontmatter解析器（当PyYAML不可用时使用）"""
    frontmatter = {}
    lines = frontmatter_text.split('\n')
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        
        # 匹配 key: value 格式
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()
            
            # 处理引号
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                value = value[1:-1]
            
            # 处理列表 [item1, item2]
            if value.startswith('[') and value.endswith(']'):
                items = value[1:-1].split(',')
                value = [item.strip().strip('"\'') for item in items if item.strip()]
            
            frontmatter[key] = value
    
    return frontmatter

def extract_frontmatter(content: str) -> tuple[Optional[Dict], str, str]:
    """从文章内容中提取frontmatter和正文"""
    lines = content.split('\n')
    
    if not lines or lines[0] != '---':
        return None, "", content
    
    frontmatter_lines = []
    body_lines = []
    in_frontmatter = False
    frontmatter_end = False
    
    for i, line in enumerate(lines):
        if i == 0 and line == '---':
            in_frontmatter = True
            continue
        elif in_frontmatter and line == '---':
            in_frontmatter = False
            frontmatter_end = True
            continue
        
        if in_frontmatter:
            frontmatter_lines.append(line)
        elif frontmatter_end:
            body_lines.append(line)
    
    frontmatter_text = '\n'.join(frontmatter_lines)
    body_text = '\n'.join(body_lines)
    
    try:
        if HAS_YAML:
            frontmatter = yaml.safe_load(frontmatter_text)
        else:
            frontmatter = parse_frontmatter_simple(frontmatter_text)
        return frontmatter, frontmatter_text, body_text
    except Exception as e:
        print(f"❌ 解析frontmatter失败: {e}")
        return None, frontmatter_text, body_text

def read_metadata_spec() -> Dict:
    """读取metadata规范文档"""
    spec_path = Path("docs/METADATA_SYSTEM.md")
    if not spec_path.exists():
        print(f"⚠️  警告: metadata规范文件不存在: {spec_path}")
        return {}
    
    spec_text = spec_path.read_text(encoding='utf-8')
    
    # 提取必需字段
    required_fields = []
    optional_fields = []
    
    # 解析规范文档
    lines = spec_text.split('\n')
    in_required_section = False
    in_optional_section = False
    
    for i, line in enumerate(lines):
        line = line.strip()
        
        # 检查是否进入必需字段部分
        if "基础信息（必需）" in line:
            in_required_section = True
            in_optional_section = False
            continue
        # 检查是否进入可选字段部分（作者信息之后的所有字段）
        elif "作者信息" in line or "内容摘要" in line or "分类系统" in line or "标签系统" in line or "技术信息" in line or "SEO优化" in line or "社交分享" in line or "平台特定" in line or "许可信息" in line or "草稿管理" in line:
            in_required_section = False
            in_optional_section = True
            continue
        # 检查是否离开字段部分
        elif line.startswith("## ") and not any(keyword in line for keyword in ["字段", "信息", "系统", "优化", "分享", "特定", "许可", "管理"]):
            in_required_section = False
            in_optional_section = False
        
        # 提取字段名
        if line.startswith("- `") and "` -" in line:
            # 匹配格式: - `title` - 文章标题
            field_match = re.search(r'`([a-zA-Z_]+)`', line)
            if field_match:
                field_name = field_match.group(1)
                if in_required_section:
                    required_fields.append(field_name)
                elif in_optional_section:
                    optional_fields.append(field_name)
    
    # 手动添加一些已知的必需字段（从文档中）
    if not required_fields:
        required_fields = ["title", "date", "modified", "status", "published"]
    
    if not optional_fields:
        optional_fields = [
            "author", "author_bio", "excerpt", "categories", "primary_category",
            "tags", "tech_stack", "difficulty", "estimated_reading_minutes",
            "meta_title", "meta_description", "og_image", "og_description",
            "wordpress_post_format", "table_of_contents", "license",
            "draft_reason", "target_publish_date"
        ]
    
    return {
        "required_fields": required_fields,
        "optional_fields": optional_fields
    }

def analyze_content(body_text: str) -> Dict[str, Any]:
    """分析文章内容，提取关键词和建议"""
    suggestions = {
        "tech_stack": [],
        "difficulty": "beginner",
        "estimated_reading_minutes": 10,
        "missing_fields": [],
        "recommended_fields": []
    }
    
    # 分析技术栈关键词
    tech_keywords = {
        "Go": ["go", "golang", "goroutine", "channel", "interface", "struct", "package"],
        "Python": ["python", "django", "flask", "numpy", "pandas", "tensorflow"],
        "JavaScript": ["javascript", "node", "react", "vue", "angular", "typescript"],
        "Docker": ["docker", "container", "image", "dockerfile"],
        "Kubernetes": ["kubernetes", "k8s", "pod", "deployment", "service"],
        "AWS": ["aws", "s3", "ec2", "lambda", "cloudformation"],
        "Azure": ["azure", "blob", "function", "cosmos"],
        "GCP": ["gcp", "google cloud", "bigquery", "cloud run"],
        "Database": ["mysql", "postgresql", "mongodb", "redis", "sqlite"],
        "DevOps": ["ci/cd", "jenkins", "gitlab", "github actions", "terraform"]
    }
    
    body_lower = body_text.lower()
    detected_tech = []
    
    for tech, keywords in tech_keywords.items():
        for keyword in keywords:
            if keyword in body_lower:
                detected_tech.append(tech)
                break
    
    if detected_tech:
        suggestions["tech_stack"] = detected_tech
    
    # 分析难度级别
    difficulty_keywords = {
        "advanced": ["advanced", "expert", "complex", "optimization", "performance", "scalability"],
        "intermediate": ["intermediate", "tutorial", "guide", "step-by-step", "example"],
        "beginner": ["beginner", "introduction", "basics", "getting started", "hello world"]
    }
    
    for difficulty, keywords in difficulty_keywords.items():
        for keyword in keywords:
            if keyword in body_lower:
                suggestions["difficulty"] = difficulty
                break
    
    # 估算阅读时间（每分钟约200-250字）
    word_count = len(body_text.split())
    estimated_minutes = max(5, word_count // 200)  # 最少5分钟
    suggestions["estimated_reading_minutes"] = estimated_minutes
    
    return suggestions

def generate_dscli_prompt(article_path: str, current_metadata: Dict, 
                         suggestions: Dict, spec_info: Dict) -> str:
    """生成给dscli的提示内容"""
    
    # 格式化当前metadata
    metadata_str = "\n".join([f"  {k}: {v}" for k, v in current_metadata.items()])
    
    prompt = f"""请帮我更新文章的metadata。以下是详细信息：

## 文章信息
- 文件路径: {article_path}
- 当前状态: {current_metadata.get('status', 'unknown')}

## 当前metadata
```yaml
{metadata_str}
```

## 分析建议
基于文章内容分析，建议更新以下metadata：

1. **技术栈 (tech_stack)**: {suggestions['tech_stack'] or '无建议'}
2. **难度级别 (difficulty)**: {suggestions['difficulty']}
3. **预计阅读时间 (estimated_reading_minutes)**: {suggestions['estimated_reading_minutes']} 分钟

## 规范要求
根据 docs/METADATA_SYSTEM.md 规范：

### 必需字段
{spec_info.get('required_fields', [])}

### 推荐字段
{spec_info.get('optional_fields', [])}

## 操作要求
1. **只能更新metadata部分**（frontmatter），不要修改文章正文内容
2. **保持YAML格式正确**，确保缩进和引号使用正确
3. **不要删除现有字段**，除非它们不符合规范
4. **添加缺失的推荐字段**，使用合理的默认值
5. **更新modified字段**为当前时间

## 具体建议
请检查并更新以下字段：

1. **tech_stack**: 如果当前为空或需要更新，请设置为: {suggestions['tech_stack']}
2. **difficulty**: 更新为: {suggestions['difficulty']}
3. **estimated_reading_minutes**: 更新为: {suggestions['estimated_reading_minutes']}
4. **modified**: 更新为当前时间戳
5. **检查必需字段**: 确保所有必需字段都存在且有效
6. **添加推荐字段**: 如果缺失，添加合理的默认值

请直接修改文件，只更新metadata部分。"""
    
    return prompt

# ============================================================================
# 主函数
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="分析文章内容并生成metadata更新建议")
    parser.add_argument("article_path", help="文章文件路径")
    parser.add_argument("--dry-run", action="store_true", help="只显示建议，不生成提示")
    
    args = parser.parse_args()
    
    article_path = Path(args.article_path)
    if not article_path.exists():
        print(f"❌ 错误: 文章文件不存在: {article_path}")
        sys.exit(1)
    
    # 读取文章内容
    content = article_path.read_text(encoding='utf-8')
    
    # 提取frontmatter和正文
    frontmatter, frontmatter_text, body_text = extract_frontmatter(content)
    if frontmatter is None:
        print(f"❌ 错误: 无法解析文章的frontmatter")
        sys.exit(1)
    
    # 读取metadata规范
    spec_info = read_metadata_spec()
    
    # 分析文章内容
    suggestions = analyze_content(body_text)
    
    # 检查缺失字段
    missing_required = []
    for field in spec_info.get("required_fields", []):
        if field not in frontmatter or not frontmatter[field]:
            missing_required.append(field)
    
    suggestions["missing_fields"] = missing_required
    
    # 生成dscli提示
    prompt = generate_dscli_prompt(str(article_path), frontmatter, suggestions, spec_info)
    
    if args.dry_run:
        print("=" * 80)
        print("📋 METADATA分析报告")
        print("=" * 80)
        print(f"📄 文章: {article_path}")
        print(f"📊 字数: {len(body_text.split())}")
        print()
        
        print("🔍 内容分析结果:")
        print(f"  技术栈建议: {suggestions['tech_stack']}")
        print(f"  难度级别: {suggestions['difficulty']}")
        print(f"  预计阅读时间: {suggestions['estimated_reading_minutes']}分钟")
        
        if missing_required:
            print(f"⚠️  缺失必需字段: {missing_required}")
        else:
            print("✅ 所有必需字段都存在")
        
        print()
        print("📝 生成的dscli提示:")
        print("-" * 40)
        print(prompt)
    else:
        # 输出给dscli的提示
        print(prompt)

if __name__ == "__main__":
    if not HAS_YAML:
        print("⚠️  警告: PyYAML库未安装，使用简单解析器")
    main()