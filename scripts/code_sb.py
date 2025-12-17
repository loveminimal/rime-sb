# 转换生成用以临时调用的飞码补丁词库
# - https://github.com/loveminimal/rime-sb
# - Jack Liu <https://aituyaa.com>
# 
import json
from pathlib import Path
from is_chinese_char import is_chinese_char
from meta_sb import meta_sb


def get_sb_code(word, ext='，。'):
    code = []
    # 此处追加一些可携带元素，如 '，。'
    for e in ext:
        meta_sb[e] = ''
    # 忽略包含非 meta_sb 中的词条
    if any(w not in meta_sb for w in word):
        return False
    
    if len(word) == 1:
        f = word[0]
        for fc in meta_sb[f]:
            code.append(f'{fc[0]}')
    elif len(word) == 2:
        f, s = word[0], word[1]
        for fc in meta_sb[f]:
            for sc in meta_sb[s]:
                code.append(f'{fc[2][:2]}{sc[2][:2]}{fc[2][2:]}')
    elif len(word) == 3:
        f, s, t = word[0], word[1], word[2]
        for fc in meta_sb[f]:
            for sc in meta_sb[s]:
                for tc in meta_sb[t]:
                    code.append(f'{fc[2][0]}{sc[2][0]}{tc[2][:2]}{fc[2][2:]}')
    elif len(word) >= 4:
        f, s, t, l = word[0], word[1], word[2], word[len(word) - 1]
        for fc in meta_sb[f]:
            for sc in meta_sb[s]:
                for tc in meta_sb[t]:
                    for lc in meta_sb[l]:
                        code.append(f'{fc[2][0]}{sc[2][0]}{tc[2][0]}{lc[2][0]}{fc[2][2:]}')       
    return code


def code_sb(proj_dir):
    # print(proj_dir)
    # ① 加载编码元数据
    meta_path = proj_dir / 'scripts' / 'meta.yaml'
    meta_dict = {}
    with open(meta_path, 'r', encoding='utf-8') as f:     
        print(f'☑️  已加载声笔源编码数据 » {meta_path}\n')   
        for line in f.readlines():
            line = line.strip()
            if not line or not is_chinese_char(line[0]):
                continue
            
            parts = line.split('\t')
            word, code, weight, stem = parts[0], parts[1], parts[2], parts[3]
            
            if word not in meta_dict:
                meta_dict[word] = []
            meta_dict[word].append([code, weight, stem])

    # 更新编码元数据
    need_update_meta_sb = False
    # need_update_meta_sb = True
    if need_update_meta_sb:
        meta_sb_path = proj_dir / 'scripts' / 'meta_sb.py'
        with open(meta_sb_path, 'w', encoding='utf-8') as m:
            print(f'☑️  已更新声笔飞单元字典 » {meta_sb_path}\n')   
            m.write("meta_sb = ")
            json.dump(meta_dict, m, ensure_ascii=False, indent=4)

    # return
    # ② 待转换的源数据
    # src_dir = proj_dir / 'patches'
    src_dir = Path('C:\\Users\\jack\\Nutstore\\1\\我的坚果云\\patches')
    words_total = []
    # 使用 glob模式匹配 src_dir目录下的所有文件，序号从1开始（默认为0）
    for i, file_path in enumerate(src_dir.glob(f'*'), 1):
        words = []
        with open(file_path, 'r', encoding='utf-8') as c:
            print(f'☑️  已加载第 {i} 份码表 » {file_path}')
            for line in c.readlines():
                line = line.strip()
                
                if not line or not is_chinese_char(line[0]):
                    continue
                
                word = line.split('\t')[0]
                if len(word) > 1:
                    words.append(word)
            words_total.extend(words)


    # ③ 转换后的数据
    out_path = proj_dir / 'patch.dict.yaml'
    with open(out_path, 'w', encoding='utf-8') as o:
        print(f'☑️  已排序处理生成码表中 ……')
        # 添加表头信息
        o.write(f'''# Rime dictionary - {out_path.name}
# encoding: utf-8
---
name: patch
version: 2025.12
sort: by_weight
use_preset_vocabulary: false
...
''')
        for word in list(dict.fromkeys(words_total)):
            code_list = get_sb_code(word)
            # 忽略包含非法的编码词条 
            if not code_list:
                continue
            
            for code in code_list:
                o.write(f'{word}\t{code}\t1\n')
            # o.write(f'{word}\t{code_list[0]}\t1\n')

    print(f'\n✅ » 已排序生成用户补丁词典 {out_path}')


if __name__ == '__main__':
    proj_dir = Path(__file__).resolve().parent.parent

    code_sb(proj_dir)