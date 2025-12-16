import json
from pathlib import Path
from is_chinese_char import is_chinese_char
from meta_sb import meta_sb


def get_sb_code(word, ext=''):
    ext = ext or f'\t1'
    code = ''
    
    # 此处追加一些可携带元素
    meta_sb['，'] = ''
    # 忽略包含非 meta_sb 中的词条
    if any(w not in meta_sb for w in word):
        # return f'xxxxxx{ext}\n'
        return False
    
    if len(word) == 1:
        f = word[0]
        for fc in meta_sb[f]:
            code += f'{word}\t{fc[0]}{ext}\n'
    elif len(word) == 2:
        f, s = word[0], word[1]
        for fc in meta_sb[f]:
            for sc in meta_sb[s]:
                code += f'{word}\t{fc[2][:2]}{sc[2][:2]}{fc[2][2:]}{ext}\n'
    elif len(word) == 3:
        f, s, t = word[0], word[1], word[2]
        for fc in meta_sb[f]:
            for sc in meta_sb[s]:
                for tc in meta_sb[t]:
                    code += f'{word}\t{fc[2][0]}{sc[2][0]}{tc[2][:2]}{fc[2][2:]}{ext}\n'
    elif len(word) >= 4:
        f, s, t, l = word[0], word[1], word[2], word[len(word) - 1]
        for fc in meta_sb[f]:
            for sc in meta_sb[s]:
                for tc in meta_sb[t]:
                    for lc in meta_sb[l]:
                        code += f'{word}\t{fc[2][0]}{sc[2][0]}{tc[2][0]}{lc[2][0]}{fc[2][2:]}{ext}\n'         
    return code


def code_sb(proj_dir):
    print(proj_dir)
    
    meta_path = proj_dir / 'scripts' / 'meta.yaml'
    meta_dict = {}
    lines_total = []
    with open(meta_path, 'r', encoding='utf-8') as f:
        lines_total = f.readlines()
        
    for line in lines_total:
        line = line.strip()
        if not line or not is_chinese_char(line[0]):
            continue
        
        parts = line.split('\t')
        word, code, weight, stem = parts[0], parts[1], parts[2], parts[3]
        
        if word not in meta_dict:
            meta_dict[word] = []
        meta_dict[word].append([code, weight, stem])


    chengyu_path = proj_dir / 'scripts' / 'chengyu.txt'
    # chengyu_path = proj_dir / 'scripts' / 'pinyin.dict.yaml'
    lines_total1 = []
    with open(chengyu_path, 'r', encoding='utf-8') as c:
        for line in c.readlines():
            line = line.strip()
            
            if not line or not is_chinese_char(line[0]):
                continue

            lines_total1.append(line)
            

    out_path = proj_dir / 'scripts' / 'out.txt'
    with open(out_path, 'w', encoding='utf-8') as o:
        for line in lines_total1:
            parts = line.split('\t')
            word = parts[0]

            # 忽略包含非法的编码词条 
            if not get_sb_code(word):
                continue
            
            o.write(f'{get_sb_code(word)}')

    
    return
    meta_sb_path = proj_dir / 'scripts' / 'meta_sb.py'
    with open(meta_sb_path, 'w', encoding='utf-8') as m:
        m.write("meta_sb = ")
        json.dump(meta_dict, m, ensure_ascii=False, indent=4)

if __name__ == '__main__':
    proj_dir = Path(__file__).resolve().parent.parent

    code_sb(proj_dir)