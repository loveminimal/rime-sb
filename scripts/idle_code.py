# 闲置的声笔飞单编码
# - https://github.com/loveminimal/rime-sb
# - Jack Liu <https://aituyaa.com>
# 
from datetime import datetime
from pathlib import Path
from is_chinese_char import is_chinese_char

def get_all_codes():
    all_codes = set()
    s = set('bpmfdtnlgkhjqxzcsrywv')
    b = set('aeuio')
    x = set('bpmfdtnlgkhjqxzcsrywvaeuio')
    f = set(";',./")
    t = set(";'")
    y = set("'")
    
    # s
    for i in s:
        all_codes.add(i)
        
    # s x|f
    for i in s:
        for j in x | f:
            all_codes.add(i + j)

    # s x|f b
    for i in s:
        for j in x | f:
            for k in b:
                all_codes.add(i + j + k)
    # ss'
    for i in s:
        for j in s:
            for k in y:
                all_codes.add(i + j + k)
    # sb ;|'
    for i in s:
        for j in b:
            for k in t:
                all_codes.add(i + j + k)

    # sxb b|y
    for i in s:
        for j in x:
            for k in b:
                for l in b|y:
                    all_codes.add(i + j + k + l)
        
    print(f'✅ ➭ 全部编码空间 {len(all_codes)} 个\n')
    # print(all_codes, len(all_codes))
    return all_codes


def get_used_codes(proj_dir):
    used_codes = set()
    lines_total = []
    lines_sbf = []

    # 读取飞码扩展词库中的词语
    sbf_path = proj_dir / 'sbf.dict.yaml'
    with open(sbf_path, 'r', encoding='utf-8') as s:
        print(f'☑️  已加载飞单缩减码数据 » {sbf_path}')   
        lines_total = s.readlines()
        lines_sbf = [l for l in lines_total if is_chinese_char(l[0])]

    sbfd_path = proj_dir / 'sbfd.dict.yaml'
    with open(sbfd_path, 'r', encoding='utf-8') as f:     
        print(f'☑️  已加载飞单单字编码数据 » {sbfd_path}\n')  
        lines_total.extend(f.readlines())
        for line in lines_total:
            line = line.strip()
            if not line or not is_chinese_char(line[0]):
                continue
            
            code = line.split('\t')[1]            
            used_codes.add(code)

    print(f'☑️  已使用编码 {len(used_codes)} 个')
    return (used_codes, lines_sbf)
    

def idle_code(proj_dir):
    # print(proj_dir)
    # 获取全部编码空间
    all_codes = get_all_codes()
    # 获全已用编码集合
    used_codes, lines_sbf = get_used_codes(proj_dir)
    # 计算闲置编码集合
    idle_codes = all_codes - used_codes
    print(f'☑️  未使用闲置编码 {len(idle_codes)} 个')
    
    for code in idle_codes:
        # lines_sbf.append(f'#\t{code}')
        lines_sbf.append(f'#\t{code}\t0\t## ')

    # print(len(lines_sbf))
    # 转换后的数据
    # out_path = proj_dir / 'out' / 'idle_codes.txt'
    # if not out_path.exists():
    #     out_path.parent.mkdir()
    # with open(out_path, 'w', encoding='utf-8') as o:   
    #     for i in sorted(idle_codes):     
    #         o.write(f'{i}\n')
    # print(f'\n✅ ➭ 已生成闲置编码条目 {out_path}')


    # is_start = False
    lines_sbf_sorted = []
    out_path = proj_dir / 'sbf.dict.yaml'
    with open(out_path, 'w', encoding='utf-8') as o:
        _lines_sbf = []
        for line in lines_sbf:
            line = line.strip()

            parts = line.split('\t')
            word, code, other = parts[0], parts[1], ''
            if len(parts) > 2:
                other = '\t'.join(parts[2:])
            _lines_sbf.append((word, code, other))
            
        lines_sbf_sorted = sorted(_lines_sbf, key=lambda x: (len(x[1]), x[1]))	# 先按编码才度，后按编码顺序
        
        o.write(f"""# Rime dict
# encoding: utf-8
#
# 飞码自定义
# 包含了声笔飞码、声笔飞单、声笔飞讯共用的数选字词、声声词、缩减码等
# 其中以 ## 结尾的行为
---
name: sbf
version: {datetime.now().date().strftime("%Y.%m")}
sort: by_weight
use_preset_vocabulary: false
columns:
  - text
  - code
  - weight
...
""")
        
        for l in lines_sbf_sorted:
            o.write(f"{'\t'.join(l)}\n")

    print(f'\n✅ ➭ 已更新飞单缩减码及补充条目 {out_path}')

if __name__ == '__main__':
    proj_dir = Path(__file__).resolve().parent.parent

    idle_code(proj_dir)