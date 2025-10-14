import re
from pathlib import Path
from code_table import code_table
from is_chinese_char import is_chinese_char
from timer import timer

@timer
def filter_8105(src_dir, out_dir, file_endswith_filter):
    dict_num = 0
    word_num = 0
    # 预编译正则表达式
    tab_split_re = re.compile(r'\t+')
    
    # 一次性读取所有文件内容
    lines_total = []
    for filepath in src_dir.iterdir():
        if filepath.is_file() and (not file_endswith_filter or filepath.name.endswith(file_endswith_filter)):
            dict_num += 1
            # word_num = 0
            
            # if filepath.name in [ 'sbf.dict.yaml', 'sbfd.dict.yaml' ]:
            if True:
                print(f'☑️  已加载第 {dict_num} 份码表 » {filepath}')
            
                with open(filepath, 'r', encoding='utf-8') as f:
                    res = ''
                    res_list = []
                    
                    for line in f.readlines():
                        if not is_chinese_char(line[0]):
                            # print(line)
                            res += line
                        else:
                            parts = tab_split_re.split(line.strip())
                            word = parts[0]
                            word_len = len(word)
                            
                            is_add = True
                            for w in word:
                                # 判断是词条项否在 8105 范围内
                                if w not in code_table:
                                    word_num += 1
                                    # print(word_num, word)
                                    is_add = False
                            if is_add:
                                res += line
                        
                    with open(out_dir / filepath.name, 'w', encoding='utf-8') as o:                        
                        o.writelines(res)
                        print(f'✅ 已生成码表 » {out_dir / filepath.name}\n')
                        

if __name__ == '__main__':
    proj_dir = Path(__file__).resolve().parent.parent
    print(proj_dir)
    
    src_dir = proj_dir
    out_dir = proj_dir / 'out'
    file_endswith_filter = '.dict.yaml'

    # out_file_name = 'jk_wubi_zj.dict.yaml'
    # out_file_path = out_dir / out_file_name
    
    # if out_file_path.exists():
    #     out_file_path.unlink()
        
    if not out_dir.exists():
        out_dir.mkdir()

    filter_8105(src_dir, out_dir, file_endswith_filter)