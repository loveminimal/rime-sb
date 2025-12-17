# 基于官方自动同步的用户词典合并排序生成用户词典
# - https://github.com/loveminimal/rime-jk
# - Jack Liu <https://aituyaa.com>
# 
import hashlib
import re
from pathlib import Path
from collections import defaultdict
import sys
from timer import timer
from progress import progress
from is_chinese_char import is_chinese_char
from datetime import datetime

def get_md5(text: str) -> str:
    """计算字符串的 MD5 哈希值"""
    md5 = hashlib.md5()  # 创建 MD5 对象
    md5.update(text.encode('utf-8'))  # 传入字节数据（必须 encode）
    return md5.hexdigest()  # 返回 32 位 16 进制字符串

# --- 用户词典同步表头 ---
# 
def get_header_sync(file_name):
    header = f'''
# Rime dictionary - {file_name}
# encoding: utf-8
#
# 声笔飞码动态词库
# 本文件中的内容用于自动码长调整，请不要改动！
# ——————
# 这里我们重置为供飞单使用的 3+ 词条库
# 
# 运行脚本：
# - https://github.com/loveminimal/rime-sb/blob/master/scripts/sync_user_dict.py
# - py scripts/sync_user_dict.py
# 
---
name: {'.'.join(file_name.split('.')[:-2])}
version: {datetime.now().date().strftime("%Y.%m")}
sort: by_weight
import_tables:
  - patch
use_preset_vocabulary: false
...
'''
    return header.strip() + '\n'

@timer
def convert(src_dir, out_dir, src_file, out_file):
    """
    将用户同步的词典文件合并、排序并生成适用于 Rime 输入法的用户词典文件。

    :param src_dir: 源文件目录
    :param out_dir: 输出文件目录
    """
    # 遍历源文件夹文件，处理
    res_dict = defaultdict(set)  # 使用 defaultdict 提高效率
    lines_total = []

    src_file_path = src_dir / src_file

    # 判断当前同步字典为 userdb（自动同步）还是 tabledb（自造词）
    is_userdb = 'userdb' in src_file

    if not src_file_path.exists():
        print(f'🪧  未发现 {src_file_path}')
        return

    if is_userdb:
        print('☑️  已加载用户词库文件 » %s' % src_file_path)
    else:
        print('☑️  已加载自造词库文件 » %s' % src_file_path)

    with open(src_file_path, 'r', encoding='utf-8') as f:
        lines_total = f.readlines()

    with open(out_dir / f'{out_file + '.temp'}', 'w', encoding='utf-8') as o:
        res = ''
        # 以下几行为原始同步词典格式 - userdb
        # 如 jk_wubi.userdb.txt
        # ---------------------------------------------------
        # yywg 	方便	c=3 d=0.187308 t=1959
        # yywr 	文件	c=1 d=0.826959 t=1959
        # encabb 	萍聊了	c=0 d=0.0201897 t=1959
        # encabbk 	萍聊了吗	c=0 d=0.0202909 t=1959
        # encabbn 	萍聊了	c=0 d=0.0201897 t=1959
        # ---------------------------------------------------
        # 以下几行为自造词同步词典格式 - tabledb
        # 如 jk_flyyx.txt
        # 自造词	zzci	9
        # 安报	encanbc	1
        # 报安	encbcan	1
        # ---------------------------------------------------
        for line in lines_total:
            word = ''
            code = ''
            weight = ''
            if not line[0] in '# ':  # 忽略注释和特殊行
                line_list = re.split(r'\t+', line.strip())
                
                if is_userdb:
                    code = line_list[0].strip()
                    word = line_list[1]
                    weight = line_list[2].split(' ')[0].split('=')[1]
                else:
                    if '' not in line:
                        continue
                    word = line_list[0]
                    code = line_list[1].strip()
                    weight = line_list[2]


                # 删除 ¹权重为负数的字词（废词）²或单字 ³或声笔中编码小于 6 的标点字词
                if int(weight) <= 0 or len(word) < 2 or len(code) < 6:
                    continue

                # 处理特殊编码
                if '' in code:
                    code = code.split('')[1]

                # 此外不再过滤非 8105 字词（源码表已做过滤 & 加载超范字词）
                # 仅处理已合成词典中 不存在 或 已存在但编码不同的字词
                if word not in res_dict or code not in res_dict[word]:
                    res += f'{word}\t{code}\t{weight}\n'
                    res_dict[word].add(code)

        if len(res.strip()) > 0:
            progress('正在转换')
            print('\n✅  » 已生成用户词库临时文件 %s' % (out_dir / f'{out_file + '.temp'}'))
            o.write(res)

@timer
def combine(out_dir, out_file):
    print(f'\n🔜  === 开始增量合并「 声笔 」用户词库文件 ===')
    res_dict = {}
    res_dict_weight = defaultdict(set)
    lines_total = []

    # 加载所有词典文件
    for file_path in out_dir.iterdir():
        # if file_path.is_file() and file_path.name.startswith(f'{out_file.split('.')[0] + '.'}'):
        if file_path.is_file() and file_path.name.startswith(out_file):
            print('☑️  已加载用户词库文件 » %s' % file_path)
            with open(file_path, 'r', encoding='utf-8') as f:
                lines_total.extend(f.readlines())

    # 去重并处理词条
    for line in set(lines_total):
        if is_chinese_char(line[0]):
            word, code, weight = line.strip().split('\t')

            # 增加用户词语的权重，放大亿点点 100,000,000
            if is_keep_user_dict_first :
                weight = int(weight)  * 100000000 if not weight.endswith('00000000') else int(weight)
            else:
                weight = int(weight) if not weight.endswith('00000000') else int(weight[:-8])

            if (word + get_md5(code)) not in res_dict or weight > max(res_dict_weight[word]):
                res_dict[word + get_md5(code)] = f'{code}\t{weight}'
                res_dict_weight[word].add(weight)
    # print(res_dict)
    # 多级分组排序（词长→编码长度→编码→汉字）
    with open(out_dir / out_file, 'w', encoding='utf-8') as o:
        o.write(get_header_sync(out_file))
        
        # 第一级：按词长分组
        word_len_dict = defaultdict(list)
        for word, value in res_dict.items():
            word_len_dict[len(word) - 32].append((word, value))

        # 处理每组词长
        for word_len in sorted(word_len_dict.keys()):
            # 第二级：按编码长度分组
            code_len_dict = defaultdict(list)
            for word, value in word_len_dict[word_len]:
                code = value.split('\t')[0]
                code_len_dict[len(code)].append((word, code, value))

            # 按编码长度处理
            for code_len in sorted(code_len_dict.keys()):
                # 关键修改：当编码相同时，按汉字unicode排序
                group = sorted(code_len_dict[code_len], 
                             key=lambda x: (x[1], x[0]))  # 先按编码排序，再按汉字排序
                for word, _, value in group:
                    o.write(f'{word[:-32]}\t{value}\n')
            print(f'☑️  已合并处理生成 {word_len} 字词语')
        print('✅  » 已合并生成用户词典 %s' % (out_dir / out_file))


if __name__ == '__main__':
    current_dir = Path.cwd()
    
    # --- 是否让用户词库排在最前 ---
    # 权重放大亿点点
    is_keep_user_dict_first = True

    src_dir = Path('C:\\Users\\jack\\Nutstore\\1\\我的坚果云\\RimeSync\\sb-rime')
    out_dir = Path('C:\\Users\\jack\\AppData\\Roaming\\Rime')


    src_file = 'sbfm.userdb.txt'
    out_file = 'sbfm.extended.dict.yaml'

    # 如果存在输出文件，先删除
    current_out_file_temp = out_dir / f'{out_file + '.temp'}'
    if current_out_file_temp.exists():
        current_out_file_temp.unlink()
        
    print(f'🔜  === 开始同步转换「 声笔 」用户词库文件 ===')

    convert(src_dir, out_dir, src_file, out_file)
    # 合并至用户文件
    combine(out_dir, out_file)
    # 清理掉临时文件 *.temp
    if current_out_file_temp.exists():
        current_out_file_temp.unlink()