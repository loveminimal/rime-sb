# 闲置的声笔象单编码「 实验性质 」
# - https://github.com/loveminimal/rime-sb
# - Jack Liu <https://aituyaa.com>
# 
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
        
    # s x
    for i in s:
        for j in x:
            all_codes.add(i + j)

    # s x x|t
    for i in s:
        for j in x:
            for k in x | t:
                all_codes.add(i + j + k)

    # s x s f
    for i in s:
        for j in x:
            for k in x:
                for l in b|y:
                    all_codes.add(i + j + k + l)
    # s x b b
    for i in s:
        for j in x:
            for k in x:
                for l in b|y:
                    all_codes.add(i + j + k + l)
        
    print(f'✅ ➭ 全部编码空间 {len(all_codes)} 个\n')
    # print(all_codes, len(all_codes))
    return all_codes


def get_used_codes(proj_dir):
    used_codes = set()
    lines_total = []
    lines_sbx = []

    # 读取象单扩展词库中的词语
    sbf_path = proj_dir / 'lua' / 'sbxlm' / 'xd_chars.txt'
    with open(sbf_path, 'r', encoding='utf-8') as s:
        print(f'☑️  已加载象单缩减码数据 » {sbf_path}')   
        lines_total = s.readlines()
        lines_sbx = [l for l in lines_total if is_chinese_char(l[0])]

    sbxd_path = proj_dir / 'sbxd.dict.yaml'
    with open(sbxd_path, 'r', encoding='utf-8') as f:     
        print(f'☑️  已加载象单单字编码数据 » {sbxd_path}\n')  
        lines_total.extend(f.readlines())
        for line in lines_total:
            line = line.strip()
            if not line or not is_chinese_char(line[0]):
                continue
            
            code = line.split('\t')[1]            
            used_codes.add(code)

    print(f'☑️  已使用编码 {len(used_codes)} 个')
    return (used_codes, lines_sbx)
    

def idle_code(proj_dir):
    # print(proj_dir)
    # 获取全部编码空间
    all_codes = get_all_codes()
    # 获全已用编码集合
    used_codes, lines_sbx = get_used_codes(proj_dir)
    # 计算闲置编码集合
    idle_codes = all_codes - used_codes
    print(f'☑️  未使用闲置编码 {len(idle_codes)} 个')

    for code in idle_codes:
        lines_sbx.append(f'#\t{code}')

    # 转换后的数据
    out_path = proj_dir / 'out' / 'idle_codes_xd.txt'
    if not out_path.exists():
        out_path.parent.mkdir()
    with open(out_path, 'w', encoding='utf-8') as o:   
        for i in sorted(idle_codes):     
            o.write(f'{i}\n')
    print(f'\n✅ ➭ 已生成闲置编码条目 {out_path}')

    # is_start = False
    lines_sbx_sorted = []
    out_path = proj_dir / 'sbx.dict.yaml'
    with open(out_path, 'w', encoding='utf-8') as o:
        _lines_sbx = []
        for line in lines_sbx:
            line = line.strip()

            parts = line.split('\t')
            word, code, other = parts[0], parts[1], ''
            if len(parts) > 2:
                other = '\t'.join(parts[2:])
            _lines_sbx.append((word, code, other))
            
        lines_sbx_sorted = sorted(_lines_sbx, key=lambda x: (len(x[1]), x[1]))	# 先按编码才度，后按编码顺序
        
        o.write(f"""# Rime dict
# encoding: utf-8
#
# 声笔象单

---
name: sbx
version: "11.0"
sort: by_weight
use_preset_vocabulary: false
columns:
  - text
  - code
  - weight
  - stem
encoder:
  rules:
    - length_equal: 2
      formula: "AaAbBaBbAcAd"
    - length_equal: 3
      formula: "AaBaCaCbAcAd"
    - length_in_range: [4, 12]
      formula: "AaBaCaZaAcAd"
...
""")
        
        for l in lines_sbx_sorted:
            o.write(f"{'\t'.join(l)}\n")

    print(f'\n✅ ➭ 已更新象单缩减码及补充条目 {out_path}')

if __name__ == '__main__':
    proj_dir = Path(__file__).resolve().parent.parent

    idle_code(proj_dir)