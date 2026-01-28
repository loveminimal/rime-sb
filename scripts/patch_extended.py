from datetime import datetime
from pathlib import Path
import threading
from is_chinese_char import is_chinese_char
from sync_user_dict import combine, convert


def ask_yes_no(question, timeout=5):
    '''
    询问是否继续操作  
    question - 具体请求描述  
    timeout - 默认超过 5s 自动取消
    '''
    answer = [None]  # 使用列表以便在嵌套函数中修改
    def input_thread():
        answer[0] = input(f"{question} ? (y/n) y: ").strip().lower() or "y"

    print(f"\n--- 默认 {timeout} 秒后取消操作 ---")
    thread = threading.Thread(target=input_thread)
    thread.daemon = True
    thread.start()
    thread.join(timeout)
    if answer[0] in ("y", "yes"):
        print("🔜  » 继续操作 ¦ 即将开始执行...")
        return True
    else:
        print('\n🎉  » 取消操作 ¦ 祝你使用愉快')
        return False
    

def sync_user_dict():
    # 调用同步合并脚本，直接合并至扩展词库
    src_dir = Path('C:\\Users\\jack\\Nutstore\\1\\我的坚果云\\RimeSync\\sb-rime')
    out_dir = Path('C:\\Users\\jack\\AppData\\Roaming\\Rime')
    src_file = 'sbxm.userdb.txt'
    out_file = 'sbxm.extended.dict.yaml'

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


def patch_extended(proj_dir):
    is_patch_extended = ask_yes_no("🔔  是否已经处理好 Patch 词库中的多音字？")
    if not is_patch_extended:
        return False;
    
    patch_lines = []
    patch_path = proj_dir / 'patch.dict.yaml'
    extended_path = proj_dir / 'sbxm.extended.dict.yaml'
    
    with open(patch_path, 'a+', encoding='utf-8') as p:
        p.seek(0)
        patch_lines = p.readlines()
        
        p.seek(0)
        p.truncate()
        p.write(f"""# Rime dictionary - patch.dict.yaml
# encoding: utf-8
---
name: patch
version: {datetime.now().date().strftime("%Y.%m")}
sort: by_weight
use_preset_vocabulary: false
...
""")
        
    with open(extended_path, 'a+', encoding='utf-8') as e:
        for line in patch_lines:
            if not line or not is_chinese_char(line[0]):
                continue
            e.write(line)
    print(f'✅  » 已追加至生成扩展词库 {proj_dir / "sbxm.extended.dict.yaml"}\n')
    
    # 调用同步合并脚本，直接合并至扩展词库
    sync_user_dict()


if __name__ == '__main__':
    proj_dir = Path(__file__).resolve().parent.parent
    patch_extended(proj_dir)
