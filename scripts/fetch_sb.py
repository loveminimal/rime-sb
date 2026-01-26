#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 克隆声笔输入法源码仓库改动

import os
import sys
import shutil
import fnmatch
from pathlib import Path

def is_blacklisted(item, item_name, blacklist_patterns):
    """
    检查文件/目录是否在黑名单中
    """
    for pattern in blacklist_patterns:
        # 使用 fnmatch 进行 glob 模式匹配
        if fnmatch.fnmatch(item_name, pattern) or fnmatch.fnmatch(item, pattern):
            return True
    return False

def copy_with_blacklist(src, dst, source_dir, blacklist_patterns):
    """
    复制函数，支持黑名单过滤
    """
    # 创建目标目录
    os.makedirs(dst, exist_ok=True)

    # 遍历源目录中的所有项目
    try:
        items = os.listdir(src)
    except PermissionError:
        print(f"警告: 无法访问目录 {src}，权限不足")
        return
    except FileNotFoundError:
        print(f"警告: 目录 {src} 不存在")
        return

    for item_name in items:
        item_path = os.path.join(src, item_name)
        relative_path = os.path.relpath(item_path, source_dir)
        dst_path = os.path.join(dst, item_name)

        # 检查是否在黑名单中
        if is_blacklisted(relative_path, item_name, blacklist_patterns):
            print(f"[跳过] {relative_path}")
            continue

        try:
            if os.path.isdir(item_path):
                # 如果是目录，递归复制
                print(f"[目录] {relative_path}")
                copy_with_blacklist(item_path, dst_path, source_dir, blacklist_patterns)
            elif os.path.isfile(item_path):
                # 如果是文件，直接复制
                print(f"[文件] {relative_path}")
                try:
                    # 尝试保留文件属性复制
                    shutil.copy2(item_path, dst_path)
                except PermissionError:
                    print(f"警告: 无法复制 {item_path}，尝试不带权限信息")
                    shutil.copy(item_path, dst_path)
            else:
                # 其他类型（如符号链接）
                print(f"[其他] {relative_path}")
                try:
                    # 尝试复制符号链接等特殊文件
                    shutil.copy2(item_path, dst_path)
                except PermissionError:
                    shutil.copy(item_path, dst_path)
        except Exception as e:
            print(f"警告: 复制 {relative_path} 时出错: {e}")

def read_custom_blacklist(custom_blacklist_file, blacklist_patterns):
    """
    读取自定义黑名单文件（如果存在）
    """
    if os.path.exists(custom_blacklist_file):
        print(f"发现自定义黑名单文件: {custom_blacklist_file}")
        try:
            with open(custom_blacklist_file, 'r', encoding='utf-8') as f:
                for line in f:
                    # 移除注释和首尾空格
                    line = line.split('#')[0].strip()
                    if line:  # 跳过空行
                        blacklist_patterns.append(line)
        except Exception as e:
            print(f"读取自定义黑名单文件时出错: {e}")
    return blacklist_patterns

def main():
    # 设置源目录和目标目录
    SOURCE_DIR = Path("D:/sourcecode/sc_rime/sbsrf/sbxlm")
    DIST_DIR = Path("C:/Users/jack/AppData/Roaming/Rime")

    # 定义黑名单模式数组（支持 glob 模式）
    BLACKLIST_PATTERNS = [
        ".git",
        "build",
        "sync",
        "*.userdb",
        "user.yaml",
        "installation.yaml",
        "default.*",
        "sbf.dict.yaml",
        "sbfd.dict.yaml",
        "sbfy.*",
        "sbfm.extended.*",
        "sbfx*.*",
        "sbfj*.*",
        "sbmm*.*",
        # "*xm*.*",
        "sbmd.*",
        "sbyp.*",
        "sbjp.*",
        "sbjm.*",
        "sbjm*.*",
        "sbpy*.*",
        "sbxh*.*",
        "sbhz.*",
        "sbzr*.*",
        "sbzz.*",
    ]

    # 验证参数
    if len(sys.argv) != 3 and len(sys.argv) != 1:
        print("用法: python copy_with_blacklist.py [<源目录> <目标目录>]")
        print("示例: python copy_with_blacklist.py /path/to/source /path/to/dist")
        sys.exit(1)

    # 如果提供了命令行参数，则使用参数中的目录
    if len(sys.argv) == 3:
        SOURCE_DIR = sys.argv[1]
        DIST_DIR = sys.argv[2]

    # 验证源目录是否存在
    if not os.path.isdir(SOURCE_DIR):
        print(f"错误: 源目录 '{SOURCE_DIR}' 不存在或不是目录")
        sys.exit(1)

    # 读取自定义黑名单文件（如果存在）
    CUSTOM_BLACKLIST = os.path.join(SOURCE_DIR, ".copy-blacklist")
    BLACKLIST_PATTERNS = read_custom_blacklist(CUSTOM_BLACKLIST, BLACKLIST_PATTERNS)

    print("========================================")
    print(f"源目录: {SOURCE_DIR}")
    print(f"目标目录: {DIST_DIR}")
    print(f"黑名单模式: {' '.join(BLACKLIST_PATTERNS)}")
    print("========================================")
    print("开始复制...")

    # 执行复制
    copy_with_blacklist(SOURCE_DIR, DIST_DIR, SOURCE_DIR, BLACKLIST_PATTERNS)

    print("========================================")
    print("复制完成!")
    print(f"目标目录: {DIST_DIR}")

if __name__ == "__main__":
    main()
