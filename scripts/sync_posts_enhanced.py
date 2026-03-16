#!/usr/bin/env python3
"""
WordPress文章同步脚本 - 增强版
支持完整的metadata字段同步
"""

import os
import sys
import hashlib
import json
import logging
import time
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

import markdown
import requests
from requests.auth import HTTPBasicAuth

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _wrap_block(tag: str, html: str) -> str:
    """将单个HTML元素包装为Gutenberg区块注释格式。"""
    if tag.startswith('h') and len(tag) == 2:
        level = tag[1]
        return (
            f'<!-- wp:heading {{"level":{level}}} -->\n'
            f'{html}\n'
            f'<!-- /wp:heading -->'
        )

    if tag == 'pre':
        code_html = re.sub(
            r'<pre><code(.*?)>(.*?)</code></pre>',
            r'<pre class="wp-block-code"><code\1>\2</code></pre>',
            html,
            flags=re.DOTALL
        )
        return f'<!-- wp:code -->\n{code_html}\n<!-- /wp:code -->'

    if tag == 'ol':
        return (
            f'<!-- wp:list {{"ordered":true}} -->\n'
            f'{html}\n'
            f'<!-- /wp:list -->'
        )

    if tag == 'table':
        return (
            f'<!-- wp:table -->\n'
            f'<figure class="wp-block-table">{html}</figure>\n'
            f'<!-- /wp:table -->'
        )

    simple_map = {
        'p': 'paragraph',
        'blockquote': 'quote',
        'ul': 'list',
    }
    block_name = simple_map.get(tag, 'html')
    return f'<!-- wp:{block_name} -->\n{html}\n<!-- /wp:{block_name} -->'


def html_to_gutenberg_blocks(html: str) -> str:
    """将Markdown生成的HTML转换为WordPress Gutenberg区块格式。

    解析顶层HTML元素，为每个元素添加对应的
    ``<!-- wp:block_type -->`` 注释标记。
    """
    BLOCK_TAGS = (
        'h[1-6]|p|blockquote|ul|ol|pre|table|div|figure'
    )
    SELF_CLOSING = re.compile(r'<hr\s*/?>\s*')

    result = []
    pos = 0
    html = html.strip()

    while pos < len(html):
        # 跳过元素之间的空白字符
        ws = re.match(r'\s+', html[pos:])
        if ws:
            pos += ws.end()
            if pos >= len(html):
                break

        # 自闭合标签 <hr>
        hr = SELF_CLOSING.match(html[pos:])
        if hr:
            result.append(
                '<!-- wp:separator -->\n'
                '<hr class="wp-block-separator '
                'has-alpha-channel-opacity"/>\n'
                '<!-- /wp:separator -->'
            )
            pos += hr.end()
            continue

        # 匹配开始标签
        tag_m = re.match(rf'<({BLOCK_TAGS})\b', html[pos:])
        if tag_m:
            tag = tag_m.group(1)
            # 深度追踪匹配闭合标签
            depth = 0
            close_pat = re.compile(rf'</?{re.escape(tag)}\b[^>]*>')
            element_end = len(html)
            for m in close_pat.finditer(html, pos):
                if m.group().startswith(f'<{tag}'):
                    depth += 1
                else:
                    depth -= 1
                    if depth == 0:
                        element_end = m.end()
                        break

            element_html = html[pos:element_end]
            result.append(_wrap_block(tag, element_html))
            pos = element_end
            continue

        # 未知内容 — 查找下一个已知标签或取剩余内容
        nxt = re.search(
            rf'<(?:{BLOCK_TAGS}|hr)\b', html[pos + 1:]
        )
        end = (pos + 1 + nxt.start()) if nxt else len(html)
        chunk = html[pos:end].strip()
        if chunk:
            result.append(
                f'<!-- wp:html -->\n{chunk}\n<!-- /wp:html -->'
            )
        pos = end

    return '\n\n'.join(result)

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class WordPressSyncError(Exception):
    """WordPress同步错误"""


class WordPressAPIError(WordPressSyncError):
    """WordPress API错误"""


class PostFileError(WordPressSyncError):
    """文章文件错误"""


class WordPressClient:
    """WordPress REST API客户端"""

    def __init__(self, base_url: str, username: str, password: str,
                 max_retries: int = 3):
        self.base_url = base_url.rstrip('/')
        self.auth = HTTPBasicAuth(username, password)
        self.session = requests.Session()
        self.session.auth = self.auth
        self.max_retries = max_retries

    def _make_request(self, method: str, endpoint: str,
                      **kwargs) -> Optional[dict]:
        """发送HTTP请求，支持重试"""
        url = f"{self.base_url}/wp-json/wp/v2/{endpoint}"

        for attempt in range(1, self.max_retries + 1):
            try:
                response = self.session.request(method, url, **kwargs)
                response.raise_for_status()
                return response.json()
            except requests.exceptions.RequestException as e:
                error_msg = f"HTTP请求失败: {e}"

                if hasattr(e, 'response') and e.response is not None:
                    status_code = e.response.status_code
                    content_type = e.response.headers.get(
                        'content-type', ''
                    )

                    if 'application/json' in content_type:
                        try:
                            error_data = e.response.json()
                            error_msg = (
                                f"HTTP请求失败: {status_code} - "
                                f"{error_data.get('message', 'Unknown')}"
                            )
                        except Exception:
                            error_msg = f"HTTP请求失败: {status_code}"
                    else:
                        error_msg = f"HTTP请求失败: {status_code}"

                if attempt < self.max_retries:
                    wait = 2 ** attempt
                    logger.warning(
                        f"{error_msg} (重试 {attempt}/{self.max_retries}，"
                        f"等待 {wait}s)"
                    )
                    time.sleep(wait)
                else:
                    logger.error(error_msg)
                    raise WordPressAPIError(error_msg)

        return None

    def get_posts(self, per_page: int = 100) -> List[dict]:
        """获取所有文章"""
        posts = []
        page = 1

        while True:
            try:
                response = self._make_request('GET', 'posts', params={
                    'per_page': per_page,
                    'page': page,
                    'context': 'edit'
                })

                if not response:
                    break

                posts.extend(response)

                if len(response) < per_page:
                    break

                page += 1
                time.sleep(0.1)

            except Exception as e:
                logger.error(f"获取文章失败: {e}")
                break

        return posts

    def get_post_by_slug(self, slug: str) -> Optional[dict]:
        """根据slug获取文章"""
        try:
            posts = self._make_request('GET', 'posts', params={
                'slug': slug,
                'context': 'edit'
            })

            if posts and len(posts) > 0:
                return posts[0]
            return None

        except Exception as e:
            logger.error(f"获取文章失败 {slug}: {e}")
            return None

    def create_post(self, title: str, content: str, slug: str,
                    meta: dict,
                    status: str = 'draft') -> Optional[int]:
        """创建新文章"""
        try:
            post_data = {
                'title': title,
                'content': content,
                'slug': slug,
                'status': status,
                'meta': meta
            }

            response = self._make_request('POST', 'posts', json=post_data)
            return response.get('id')

        except Exception as e:
            logger.error(f"创建文章失败 {slug}: {e}")
            return None

    def update_post(self, post_id: int, title: str, content: str,
                    meta: dict,
                    status: str = None) -> bool:
        """更新现有文章"""
        try:
            update_data = {
                'title': title,
                'content': content,
                'meta': meta
            }
            if status:
                update_data['status'] = status

            self._make_request('POST', f'posts/{post_id}', json=update_data)
            return True

        except Exception as e:
            logger.error(f"更新文章失败 {post_id}: {e}")
            return False


class PostFile:
    """文章文件处理器"""

    def __init__(self, file_path: Path):
        self.file_path = file_path
        self.slug = file_path.parent.name
        self.content = self._read_content()
        self.file_hash = self._calculate_hash()

    def _read_content(self) -> str:
        try:
            return self.file_path.read_text(encoding='utf-8')
        except Exception:
            return self.file_path.read_text(encoding='gbk')

    def _calculate_hash(self) -> str:
        """计算文件内容的哈希值，确保一致性"""
        try:
            content_bytes = self.content.encode('utf-8')
            return hashlib.sha256(content_bytes).hexdigest()
        except Exception as e:
            logger.warning(f"UTF-8编码失败，尝试其他编码: {e}")
            try:
                content_bytes = self.content.encode('gbk')
                return hashlib.sha256(content_bytes).hexdigest()
            except Exception as e2:
                logger.error(f"所有编码尝试失败，使用文件原始字节: {e2}")
                raw_bytes = self.file_path.read_bytes()
                return hashlib.sha256(raw_bytes).hexdigest()

    def extract_frontmatter(self) -> dict:
        lines = self.content.split('\n')
        frontmatter = {}

        if lines and lines[0].strip() == '---':
            i = 1
            while i < len(lines) and lines[i].strip() != '---':
                line = lines[i]
                if ': ' in line:
                    key, value = line.split(': ', 1)
                    frontmatter[key.strip()] = value.strip()
                i += 1

        return frontmatter

    def get_body_content(self) -> str:
        """返回去除frontmatter后的文章内容。"""
        lines = self.content.split('\n')
        if lines and lines[0].strip() == '---':
            i = 1
            while i < len(lines) and lines[i].strip() != '---':
                i += 1
            if i < len(lines):
                return '\n'.join(lines[i + 1:]).strip()
        return self.content

    def get_title(self) -> str:
        frontmatter = self.extract_frontmatter()
        if 'title' in frontmatter:
            title = frontmatter['title'].strip('"\'')
            return title

        lines = self.content.split('\n')
        for line in lines:
            if line.startswith('# '):
                return line[2:].strip()

        return self.slug.replace('-', ' ').title()


class EnhancedPostFile(PostFile):
    """增强版文章文件处理器，支持完整metadata"""

    WORDPRESS_META_MAPPING = {
        'git_author': 'author',
        'git_author_bio': 'author_bio',
        'git_excerpt': 'excerpt',
        'git_primary_category': 'primary_category',
        'git_tech_stack': 'tech_stack',
        'git_difficulty': 'difficulty',
        'git_reading_minutes': 'estimated_reading_minutes',
        'git_meta_title': 'meta_title',
        'git_meta_description': 'meta_description',
        'git_og_image': 'og_image',
        'git_og_description': 'og_description',
        'git_post_format': 'wordpress_post_format',
        'git_table_of_contents': 'table_of_contents',
        'git_license': 'license',
        'git_draft_reason': 'draft_reason',
        'git_target_publish_date': 'target_publish_date',
        'git_published': 'published',
        'git_modified': 'modified',
    }

    def extract_enhanced_frontmatter(self) -> dict:
        """提取增强的Frontmatter信息"""
        frontmatter = self.extract_frontmatter()

        if 'title' not in frontmatter:
            frontmatter['title'] = self.get_title()
        if 'date' not in frontmatter:
            frontmatter['date'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        if 'status' not in frontmatter:
            frontmatter['status'] = 'draft'
        if 'author' not in frontmatter:
            frontmatter['author'] = '杰西卡尔'
        if 'categories' not in frontmatter:
            frontmatter['categories'] = '["未分类"]'
        if 'tags' not in frontmatter:
            frontmatter['tags'] = '["文章"]'

        return frontmatter

    def get_wordpress_meta(self) -> dict:
        """获取WordPress格式的meta数据"""
        frontmatter = self.extract_enhanced_frontmatter()
        meta = {
            'git_slug': self.slug,
            'git_file_hash': self.file_hash,
            'git_synced_at': datetime.now().isoformat(),
            'git_source': 'github'
        }

        for wp_field, md_field in self.WORDPRESS_META_MAPPING.items():
            if md_field in frontmatter:
                meta[wp_field] = frontmatter[md_field]

        if 'categories' in frontmatter:
            meta['git_categories'] = frontmatter['categories']
        if 'tags' in frontmatter:
            meta['git_tags'] = frontmatter['tags']
        if 'status' in frontmatter:
            meta['git_status'] = frontmatter['status']

        return meta

    def get_wordpress_status(self) -> str:
        """获取WordPress文章状态"""
        frontmatter = self.extract_enhanced_frontmatter()
        status = frontmatter.get('status', 'draft')

        status_map = {
            'publish': 'publish',
            'published': 'publish',
            'draft': 'draft',
            'private': 'private',
            'pending': 'pending'
        }

        return status_map.get(status.lower(), 'draft')


class EnhancedSyncManager:
    """增强版同步管理器"""

    def __init__(self, wp_client: WordPressClient, posts_root: Path,
                 hashes_file: Optional[Path] = None,
                 dry_run: bool = False):
        self.wp_client = wp_client
        self.posts_root = posts_root
        self.hashes_file = hashes_file
        self.dry_run = dry_run
        self.hashes = self._load_hashes()
        self.sync_times: Dict[str, float] = {}
        self.results = {
            'success': [],
            'skipped': [],
            'failed': []
        }

    def _load_hashes(self) -> dict:
        """从 JSON 文件加载已存储的哈希值。"""
        if self.hashes_file and self.hashes_file.exists():
            try:
                data = json.loads(
                    self.hashes_file.read_text(encoding='utf-8')
                )
                logger.info(f"已加载 {len(data)} 条哈希记录")
                return data
            except (json.JSONDecodeError, OSError) as e:
                logger.warning(f"加载哈希文件失败，将全量同步: {e}")
                return {}
        logger.info("无哈希缓存，将全量同步")
        return {}

    def _save_hashes(self):
        """将当前哈希值保存到 JSON 文件。"""
        if self.hashes_file:
            self.hashes_file.write_text(
                json.dumps(self.hashes, indent=2, ensure_ascii=False),
                encoding='utf-8'
            )
            logger.info(f"已保存 {len(self.hashes)} 条哈希记录")

    def _get_last_sync_time(self, slug: str) -> Optional[float]:
        """获取文章的最后同步时间"""
        return self.sync_times.get(slug)

    def _update_sync_time(self, slug: str, sync_time: float):
        """更新文章的最后同步时间"""
        self.sync_times[slug] = sync_time

    def get_wp_posts_by_slug(self) -> Dict[str, dict]:
        """获取WordPress中所有文章，按slug索引"""
        logger.info("获取WordPress中的文章...")
        posts = self.wp_client.get_posts()

        wp_posts = {}
        for post in posts:
            slug = post.get('slug')
            if slug:
                wp_posts[slug] = post

        logger.info(f"找到 {len(wp_posts)} 篇文章")
        return wp_posts

    def find_post_files(self,
                        specific_slugs: List[str] = None) -> List[Path]:
        """查找文章文件"""
        post_files = []

        for post_dir in self.posts_root.iterdir():
            if not post_dir.is_dir():
                continue

            slug = post_dir.name
            if specific_slugs and slug not in specific_slugs:
                continue

            md_file = post_dir / 'index.md'
            if md_file.exists():
                post_files.append(md_file)

        return post_files

    def sync_post(self, post_file: EnhancedPostFile,
                  wp_posts: Dict[str, dict]) -> bool:
        """同步单篇文章"""
        slug = post_file.slug

        try:
            title = post_file.get_title()
            body_md = post_file.get_body_content()
            file_hash = post_file.file_hash
            meta = post_file.get_wordpress_meta()
            wp_status = post_file.get_wordpress_status()

            # 将Markdown转换为HTML，再转换为Gutenberg区块格式
            body_html = markdown.markdown(
                body_md,
                extensions=[
                    'fenced_code',
                    'tables',
                    'toc',
                    'nl2br',
                ]
            )
            body_blocks = html_to_gutenberg_blocks(body_html)

            # 验证哈希值格式
            if not file_hash or len(file_hash) != 64:
                logger.error(f"无效的哈希值: {slug} -> {file_hash}")
                self.results['failed'].append(
                    (slug, f"无效的哈希值: {file_hash}")
                )
                return False

            # 基于本地哈希文件的变更检测
            stored_hash = self.hashes.get(slug)
            if stored_hash == file_hash:
                logger.info(f"文章未变化（哈希匹配），跳过: {slug}")
                self.results['skipped'].append(slug)
                return True

            # 防止短时间内重复同步
            current_time = time.time()
            last_sync = self._get_last_sync_time(slug)
            if last_sync and (current_time - last_sync) < 60:
                logger.warning(f"文章在60秒内重复同步，跳过: {slug}")
                self.results['skipped'].append(slug)
                return True

            if self.dry_run:
                action = "更新" if slug in wp_posts else "创建"
                logger.info(f"[DRY-RUN] 将{action}文章: {slug}")
                self.results['success'].append((slug, 0, f'dry-{action}'))
                return True

            # 判断创建还是更新
            if slug in wp_posts:
                wp_post = wp_posts[slug]
                logger.info(f"更新文章: {slug} (status={wp_status})")
                success = self.wp_client.update_post(
                    wp_post['id'], title, body_blocks, meta,
                    status=wp_status
                )

                if success:
                    self.hashes[slug] = file_hash
                    self._update_sync_time(slug, current_time)
                    self.results['success'].append(
                        (slug, wp_post['id'], 'updated')
                    )
                    return True
                raise WordPressAPIError("更新文章失败")

            # 创建新文章
            logger.info(f"创建新文章: {slug} (status={wp_status})")
            post_id = self.wp_client.create_post(
                title, body_blocks, slug, meta,
                status=wp_status
            )

            if post_id:
                self.hashes[slug] = file_hash
                self._update_sync_time(slug, current_time)
                self.results['success'].append(
                    (slug, post_id, 'created')
                )
                return True
            raise WordPressAPIError("创建文章失败")

        except Exception as e:
            logger.error(f"同步文章失败 {slug}: {e}")
            self.results['failed'].append((slug, f"同步失败: {e}"))
            return False

    def sync_all(self, specific_slugs: List[str] = None) -> bool:
        """同步所有文章"""
        wp_posts = self.get_wp_posts_by_slug()
        post_files = self.find_post_files(specific_slugs)

        if not post_files:
            logger.info("没有找到需要同步的文章")
            return True

        total = len(post_files)
        logger.info(f"开始同步 {total} 篇文章")

        for i, file_path in enumerate(post_files, 1):
            logger.info(f"处理文章 [{i}/{total}]: {file_path.parent.name}")

            try:
                post_file = EnhancedPostFile(file_path)
                self.sync_post(post_file, wp_posts)
            except Exception as e:
                logger.error(
                    f"处理文章失败 {file_path.parent.name}: {e}"
                )
                self.results['failed'].append(
                    (file_path.parent.name, f"处理失败: {e}")
                )

            if i < total:
                time.sleep(0.5)

        self._save_hashes()
        self._print_results()

        return len(self.results['failed']) == 0

    def _print_results(self):
        """输出同步结果"""
        logger.info("\n" + "=" * 50)
        logger.info("增强版同步结果汇总")
        logger.info("=" * 50)

        logger.info(f"✅ 成功: {len(self.results['success'])}")
        for slug, post_id, action in self.results['success']:
            logger.info(f"  - {slug}: {action} -> ID: {post_id}")

        logger.info(f"⏭️  跳过: {len(self.results['skipped'])}")
        for slug in self.results['skipped']:
            logger.info(f"  - {slug}: 未变化")

        logger.info(f"❌ 失败: {len(self.results['failed'])}")
        for slug, reason in self.results['failed']:
            logger.error(f"  - {slug}: {reason}")

        logger.info("=" * 50)


def main():
    """主函数"""
    import argparse

    parser = argparse.ArgumentParser(description="增强版同步文章到WordPress")
    parser.add_argument(
        '--slugs',
        help="指定要同步的文章slug，多个用逗号分隔"
    )
    parser.add_argument(
        '--posts-root', default='content/posts',
        help="文章根目录，默认: content/posts"
    )
    parser.add_argument(
        '--hashes-file', default='.sync-hashes.json',
        help="哈希状态文件路径，默认: .sync-hashes.json"
    )
    parser.add_argument(
        '--dry-run', action='store_true',
        help="只显示将要执行的操作，不实际同步"
    )
    parser.add_argument(
        '--max-retries', type=int, default=3,
        help="API请求最大重试次数"
    )

    args = parser.parse_args()

    # 从环境变量获取配置
    wp_url = os.getenv('WORDPRESS_URL')
    wp_username = os.getenv('WORDPRESS_USERNAME')
    wp_password = os.getenv('WORDPRESS_PASSWORD')

    if not all([wp_url, wp_username, wp_password]):
        logger.error(
            "缺少环境变量: WORDPRESS_URL, WORDPRESS_USERNAME, "
            "WORDPRESS_PASSWORD"
        )
        sys.exit(1)

    # 验证URL格式
    if not wp_url.startswith(('http://', 'https://')):
        logger.error(f"无效的URL格式: {wp_url}")
        sys.exit(1)

    # 安全地记录配置信息
    logger.info(f"WordPress URL: {wp_url}")
    logger.info(f"WordPress Username: {wp_username}")
    logger.info("WordPress Password: [已隐藏]")

    if args.dry_run:
        logger.warning("⚠️  DRY-RUN模式：只显示操作，不实际同步")

    # 初始化客户端
    wp_client = WordPressClient(
        wp_url, wp_username, wp_password,
        max_retries=args.max_retries
    )

    # 解析指定的slug
    specific_slugs = None
    if args.slugs:
        specific_slugs = [s.strip() for s in args.slugs.split(',')]
        logger.info(f"指定同步的文章: {specific_slugs}")

    # 初始化同步管理器
    posts_root = Path(args.posts_root)
    if not posts_root.exists():
        logger.error(f"文章根目录不存在: {posts_root}")
        sys.exit(1)

    hashes_file = Path(args.hashes_file)
    sync_manager = EnhancedSyncManager(
        wp_client, posts_root, hashes_file,
        dry_run=args.dry_run
    )

    # 执行同步
    success = sync_manager.sync_all(specific_slugs)

    if not success:
        logger.error("同步过程中有失败的文章")
        sys.exit(1)

    logger.info("✅ 所有文章同步完成")


if __name__ == '__main__':
    main()