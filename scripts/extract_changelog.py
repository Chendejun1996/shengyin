#!/usr/bin/env python3
"""从 CHANGELOG.md 提取指定版本的更新内容"""
import sys, re

if len(sys.argv) < 2:
    print("用法: extract_changelog.py <版本号>")
    sys.exit(1)

tag = sys.argv[1]
try:
    with open('CHANGELOG.md', 'r') as f:
        content = f.read()
except FileNotFoundError:
    print("")
    sys.exit(0)

# 匹配 ## vX.Y.Z (日期) 到下一个 ## 或文件末尾
pattern = r'## ' + re.escape(tag) + r'\s*\(.*?\)\n(.*?)(?=\n## |\Z)'
match = re.search(pattern, content, re.DOTALL)

if match:
    body = match.group(1).strip()
    print(body)
else:
    print("")
