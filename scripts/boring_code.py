# 统计那些令人讨厌的声笔象码编码「 实验性质 」
# - https://github.com/loveminimal/rime-sb
# - Jack Liu <https://aituyaa.com>
# 
from datetime import datetime
from pathlib import Path
import re
from is_chinese_char import is_chinese_char

def get_all_codes():
    all_codes = set()
    s = set('bpmfdtnlgkhjqxzcsrywv')
    b = set('aeuio')
    x = set('bpmfdtnlgkhjqxzcsrywvaeuio')
    f = set(";',./")
    t = set(";'")
    
    # 单字简码 21 + 21*26 + 21*26*5 + 21*26*2 = 4389
    # s
    for i in s:
        all_codes.add(i)
        
    # s x
    for i in s:
        for j in x:
            all_codes.add(i + j)

    # s b b|t
    for i in s:
        for j in b:
            for k in b | t:
                all_codes.add(i + j + k)
    # s s b|t
    for i in s:
        for j in s:
            for k in b | t:
                all_codes.add(i + j + k)

    # 单字全码 21*26*21*5 + 21*26*5*5 = 70980
    # s x s f
    for i in s:
        for j in x:
            for k in s:
                for l in f:
                    all_codes.add(i + j + k + l)
    # s x b b
    for i in s:
        for j in x:
            for k in b:
                for l in b:
                    all_codes.add(i + j + k + l)
        
    print(f'✅ ➭ 全部编码空间 {len(all_codes)} 个\n')
    # print(all_codes, len(all_codes))
    return all_codes


def get_used_codes(proj_dir):
    used_codes = set()
    lines_total = []
    lines_sbx = []

    # 读取象码扩展词库中的词语
    sbx_path = proj_dir / 'sbx.dict.yaml'
    if not sbx_path.exists():
        sbx_path.touch()
    with open(sbx_path, 'r', encoding='utf-8') as s:
        print(f'☑️  已加载象码缩减码数据 » {sbx_path}')   
        lines_total = s.readlines()
        lines_sbx = [l for l in lines_total if is_chinese_char(l[0])]

    sbxd_path = proj_dir / 'sbxm.dict.yaml'
    with open(sbxd_path, 'r', encoding='utf-8') as f:     
        print(f'☑️  已加载象码单字编码数据 » {sbxd_path}\n')  
        lines_total.extend(f.readlines())
        for line in lines_total:
            line = line.strip()
            if not line or not is_chinese_char(line[0]):
                continue
            
            code = line.split('\t')[1]            
            used_codes.add(code)

    print(f'☑️  已使用编码 {len(used_codes)} 个')
    # lines_sbx = [l for l in lines_total if is_chinese_char(l[0])]
    return (used_codes, lines_sbx)
    

def boring_code(proj_dir):
    # print(proj_dir)
    # 获取全部编码空间
    # all_codes = get_all_codes()
    # 获全已用编码集合
    used_codes, lines_sbx = get_used_codes(proj_dir)
    # 计算闲置编码集合
    # idle_codes = all_codes - used_codes
    # print(f'☑️  未使用闲置编码 {len(idle_codes)} 个')

    # for code in idle_codes:
    #     # lines_sbx.append(f'#\t{code}\t0\t{code[:2]}\t# ')
    #     lines_sbx.append(f'#\t{code}\t')
    
    # 令人讨厌的编码正则规则数组 - 基于键盘手感和连击难度
    # boring_code_re = [
    #     # 1. 同手指连续击键（垂直方向难连击）
    #     r'^([qaz])\1',        # 左手小指垂直连击
    #     r'^([wsx])\1',        # 左手中指垂直连击
    #     r'^([edc])\1',        # 左手食指垂直连击
    #     r'^([rfv])\1',        # 左手食指垂直连击
    #     r'^([tgb])\1',        # 左手食指垂直连击
    #     r'^([yhn])\1',        # 右手食指垂直连击
    #     r'^([ujm])\1',        # 右手食指垂直连击
    #     r'^([ik,])\1',        # 右手中指垂直连击
    #     r'^([ol.])\1',        # 右手无名指垂直连击
    #     r'^([p;/])\1',        # 右手小指垂直连击
        
    #     # 2. 远距离跨排连击（手指需要大幅度移动）
    #     r'^[qaz][p;/]',       # 最左到最右
    #     r'^[p;/][qaz]',       # 最右到最左
    #     r'^[qaz][ol.]',       # 左下到右上
    #     r'^[p;/][wsx]',       # 右上到左下
        
    #     # 3. 同手小指连续击键（小指力量弱，容易疲劳）
    #     r'^[qazp;/]{2,}',     # 左右小指连续击键
    #     r'[qazp;/][qazp;/]',  # 任意小指键连续
        
    #     # 4. 底部排连续击键（手腕需要上下移动）
    #     r'^[zxc,./]{3,}',     # 底部排连续3个以上
    #     r'[zxc,./][zxc,./]',  # 底部排连续击键
        
    #     # 5. 数字排连续击键（需要手部上移）
    #     r'^[1234567890]{2,}', # 数字排连续击键
        
    #     # 6. 对角线难连击序列
    #     r'^[qpl;]',           # 左上到右下的对角线
    #     r'^[aq;.]',           # 左下到右上的对角线
    #     r'^[pza]',            # 右上到左下的对角线
    #     r'^[;aq]',            # 右下到左上的对角线
        
    #     # 7. 需要手掌旋转的连击
    #     r'^[qwert][yuiop]',   # 左手区到右手区快速切换
    #     r'^[yuiop][qwert]',   # 右手区到左手区快速切换
    #     r'^[asdfg][hjkl]',    # 左手中部到右手中部
    #     r'^[hjkl][asdfg]',    # 右手中部到左手中部
        
    #     # 8. 同排但距离远的连击
    #     r'^[qp]',             # 顶部排最左最右
    #     r'^[az]',             # 中部排最左最右  
    #     r'^[;.]',             # 底部排最左最右
        
    #     # 9. 小指+无名指连续（力量差异大）
    #     r'^[qaz][wsxol.]',    # 小指后接无名指
    #     r'^[p;/][ol.ik,]',    # 右手小指后接无名指
        
    #     # 10. 需要伸展手指的连击
    #     r'^[qaz][edcik,]',    # 小指伸展到中指
    #     r'^[p;/][rfvol.]',    # 小指伸展到食指/无名指
        
    #     # 11. 手腕需要扭动的序列
    #     r'^[qwert][zxcvb]',   # 顶部排到底部排手腕扭动
    #     r'^[yuiop][nm,./]',   # 右手区顶部到底部
        
    #     # 12. 同手食指过度使用（食指负担重）
    #     r'^[rfvytgbnujm]{3,}', # 食指负责的键连续3个以上
    #     r'[rfv][yhn]',         # 左手食指到右手食指
    #     r'[yhn][ujm]',         # 右手食指内部连续
        
    #     # 13. 需要小指按压的Shift组合模拟（符号键难按）
    #     r'[;\',./]{2,}',       # 符号键连续2个以上
    #     r'^[;\',./]',          # 以符号键开头
        
    #     # 14. 不自然的指法序列
    #     r'^[qaz][p;/][qaz]',   # 小指左右来回
    #     r'^[edc][ik,][edc]',   # 中指左右来回
    #     r'^[rfv][ujm][rfv]',   # 食指左右来回
        
    #     # 15. 需要手掌平移的序列
    #     r'^[qaz][p;/][qaz]',   # 左-右-左平移
    #     r'^[p;/][qaz][p;/]',   # 右-左-右平移
    # ]
    
    boring_code_re = [
        r'[q][gz]',
        r'[g][qz]',
        r'[z][qg]',
    ]
    
    boring_codes = set()
    # 对每个编码生用 boring_code_re 这的规则校验，匹配的添加到 boring_codes
    for code in used_codes:
        for pattern in boring_code_re:
            if re.search(pattern, code):
                boring_codes.add(code)
                break  # 匹配一个规则就足够，无需检查其他规则

    # 转换后的数据
    out_path = proj_dir / 'out' / 'boring_codes_xd.txt'
    if not out_path.parent.exists():
        out_path.parent.mkdir()
    with open(out_path, 'w', encoding='utf-8') as o:   
        for i in sorted(boring_codes):     
            o.write(f'{i}\n')
    print(f'\n✅ ➭ 已生成闲置编码条目 {out_path}')

    return
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
# 声笔象码
---
name: sbx
version: {datetime.now().date().strftime("%Y.%m")}
sort: by_weight
use_preset_vocabulary: false
...
""")
        
        for l in lines_sbx_sorted:
            o.write(f"{'\t'.join(l)}\n")

    print(f'\n✅ ➭ 已更新象码缩减码及补充条目 {out_path}')

if __name__ == '__main__':
    proj_dir = Path(__file__).resolve().parent.parent

    boring_code(proj_dir)