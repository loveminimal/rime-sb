# 转换生成用以临时调用的飞码补丁词库
# - https://github.com/loveminimal/rime-sb
# - Jack Liu <https://aituyaa.com>
# 
import json
from pathlib import Path
from is_chinese_char import is_chinese_char
# from code_table import code_table
# from meta_sb import meta_sb


def get_sb_code(word, meta_sb, ext='，。？'):
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
            code.append(f'{fc[0]}{fc[2][2:]}')
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


def get_meta_sb(proj_dir):
    # meta_path = proj_dir / 'scripts' / 'meta.yaml'
    meta_path = proj_dir / 'sbfd.dict.yaml'
    meta_dict = {}
    with open(meta_path, 'r', encoding='utf-8') as f:     
        print(f'☑️  已加载声笔源编码数据 » {meta_path}\n')   
        for line in f.readlines():
            line = line.strip()
            if not line or not is_chinese_char(line[0]):
                continue
            
            parts = line.split('\t')
            word, code, weight, stem = parts[0], parts[1], parts[2], parts[3]
            
            # 过滤非 8105 的字
            # if word not in code_table:
            #     continue
            
            if word not in meta_dict:
                meta_dict[word] = []
            meta_dict[word].append([code, weight, stem])

        # 对生僻的多音字做一些特殊处理
        meta_sb = {}
        for key, value in meta_dict.items():
            if len(value) == 1:
                meta_sb[key] = value
                continue
            
            filter_weight = 250
            _value = [v for v in value if int(v[1]) <= filter_weight]
            if len(_value) == len(value):
                # 多音字条目且权重都小于 filter_weight，仅收录第一个元素
                meta_sb[key] = [value[0]]
            else: 
                # 这里我们过滤掉多音字中权重小于等于 filter_weight 的音
                meta_sb[key] = [v for v in value if int(v[1]) > filter_weight]  

        # 是否更新编码元数据
        need_update_meta_sb = False
        # need_update_meta_sb = True
        if need_update_meta_sb:
            meta_sb_path = proj_dir / 'scripts' / 'meta_sb.py'
            with open(meta_sb_path, 'w', encoding='utf-8') as m:
                print(f'☑️  已更新声笔飞单元字典 » {meta_sb_path}\n')   
                m.write("meta_sb = ")
                json.dump(meta_dict, m, ensure_ascii=False, indent=4)
    return meta_sb
    

def get_patch_dict(proj_dir):
    lines_total = []
    patch_dict = {}

    # 读取飞码扩展词库中的词语
    sbfm_extended_path = proj_dir / 'sbfm.extended.dict.yaml'
    with open(sbfm_extended_path, 'r', encoding='utf-8') as s:
        print(f'☑️  已加载飞码扩展数据 » {sbfm_extended_path}')   
        lines_total = s.readlines()

    # 读取飞码补丁词库中的词语
    patch_path = proj_dir / 'patch.dict.yaml'
    with open(patch_path, 'r', encoding='utf-8') as p:     
        print(f'☑️  已加载既有PATCH数据 » {patch_path}\n')   
        lines_total.extend(p.readlines())
        for line in lines_total:
            line = line.strip()
            if not line or not is_chinese_char(line[0]):
                continue
            
            parts = line.split('\t')
            word, code, weight = parts[0], parts[1], parts[2]
            
            # 过滤非 8105 的字
            # if word not in code_table:
            #     continue
            
            if word not in patch_dict:
                patch_dict[word] = []
            patch_dict[word].append([code, weight])
    return patch_dict


def code_sb(proj_dir):
    # print(proj_dir)
    # 加载编码元数据
    meta_sb = get_meta_sb(proj_dir)

    # return
    # 待转换的源数据
    # src_dir = proj_dir / 'patches'
    src_dir = Path('C:\\Users\\jack\\Nutstore\\1\\我的坚果云\\patches')
    if not src_dir.exists():
        print(f'☑️  不存在转换数据目录 » {src_dir}')   
        print(f'❎ ➭ 结束转换')
        
        return
        
    words_total = []
    # 只处理常见的文本文件扩展名
    # valid_extensions = {'.txt', '.yaml', '.yml', '.dict', '.dict.yaml'}

    # 使用 glob模式匹配 src_dir目录下的所有文件，序号从1开始（默认为0）
    for i, file_path in enumerate(src_dir.rglob(f'*'), 1):
        # 跳过目录和其他非文件对象
        if not file_path.is_file():
            print(f'☑️  已加载第 {i} 个目录 » {file_path}')
            continue  
        
        # 检查文件扩展名，跳过不支持的文件类型
        # if file_path.suffix.lower() not in valid_extensions:
        #     continue
        
        words = []
        with open(file_path, 'r', encoding='utf-8') as c:
            print(f'☑️  已加载第 {i} 份码表 » {file_path}')
            for line in c.readlines():
                line = line.strip()
                
                if not line or not is_chinese_char(line[0]):
                    continue
                
                word = line.split('\t')[0].strip()
                if len(word) > 1:
                    words.append(word)
            words_total.extend(words)


    # 转换后的数据
    out_path = proj_dir / 'patch.dict.yaml'
    with open(out_path, 'a+', encoding='utf-8') as o:        
        # 读取第一行，判断是否已有表头
        o.seek(0)  # 将指针从末尾移动到文件开头
        first_line = o.readline().strip()
        if not first_line:
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
        # 读取原有 patch 数据
        patch_dict = get_patch_dict(proj_dir)
        
        print(f'☑️  已排序处理生成码表中 ……')
        for word in list(dict.fromkeys(words_total)):
        # for word in list(dict.fromkeys(sorted(words_total))):
            # 已经存在的不再重复编码
            if word in patch_dict:
                continue

            code_list = get_sb_code(word, meta_sb)
            # 忽略包含非法的编码词条 
            if not code_list:
                continue
            
            for code in code_list:
                o.write(f'{word}\t{code}\t1\n')
            # o.write(f'{word}\t{code_list[0]}\t1\n')

    print(f'\n✅ ➭ 已排序生成用户补丁词典 {out_path}')


if __name__ == '__main__':
    proj_dir = Path(__file__).resolve().parent.parent
    
    # print(len(meta_sb))

    code_sb(proj_dir)