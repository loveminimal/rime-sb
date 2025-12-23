-- Created by Jack Liu <https://aituyaa.com>
-- 
-- 主键区符号映射，如：
-- ;qq → ！  ss → _ ...
-- 使用 ; 作引导符结合两个主键位映射出全部半角字符及常用全角字符
-- ---------------------------------

-- 定义符号映射表（支持双字母组合）
-- 仍然有大量组合及空位未列出，可按照个人需求自定义添加、添加
-- ---------------------------------
-- 更新日志
-- 2025-10-09 10:49 增加多个字母组合模式支持，如 ;q, ;qq, ;qqq, ;abc 等

local mapping = {
    -- qq = "!", ww = "@", ee = "#", rr = "$", tt = "%", yy = "^", uu = "_", ii = "-", oo = "=", pp = "+",
    -- aa = "&", ss = "(", dd = ")", ff = "{", gg = "}", hh = "=", jj = ",", kk = ".", ll = ";", 
    -- zz = "|", xx = "[", cc = "]", vv = "*", bb = "`", nn = "〔", mm = "〕"
    
    -- 主键双击
    qq = "@"        , ww = "!"  , ee = "#"  , rr = "$"  , tt = "%"  , yy = "^"  , uu = "_"  , ii = "-"  , oo = "="  , pp = "~"  ,
      aa = "&"      , ss = ":"  , dd = "`"  , ff = ";"  , gg = "*"  , hh = "|"  , jj = "+"  , kk = "'"  , ll = '"'  ,
        zz = "\\"   , xx = ","  , cc = "."  , vv = "<"  , bb = ">"  , nn = "/"  , mm = "?"  ,

    -- 全角映射
    qa = ""       , ws = "！" , ed = " "  , rf = "¥"  , tg = "％" , yh = "……", uj = "¦"  , ik = "——"  , ol = "・",
      az = "&&"    , sx = "：" , dc = " "  , fv = "；" , gb = "×"  , hn = "||"   , jm = "＊"   ,
        za = "、" , xs = "，" , cd = "。" , vf = "《" , bg = "》" , nh = "·"   , mj = "？" ,

    -- 对符映射
    qw = "1"    , wq = "2"  , we = "3"  , ew = "4"  , er = "5"   , re = "6"   , rt = " "   , tr = " "   , ty = "  " , yt = " "  , yu = ' '  , uy = " "  , ui = " "  , iu = " "  , io = " "  , oi = " "  , op = " "  , po = " "  ,
      as = "7"  , sa = "8"  , sd = "("  , ds = ")"  , df = "["   , fd = "]"   , fg = "{"   , gf = "}"   , gh = '【 ', hg = ' 】', hj = "『 ", jh = " 』", jk = "‘"  , kj = "’"  , kl = "“"  , lk = "”"  ,
        zx = "9", xz = "0"  , xc = "（" , cx = "）" , cv = "「 " , vc = " 」" , vb = "〔 " , bv = " 〕" , bn = '〈' , nb = "〉" , nm = "《", mn = "》"  ,
    
    -- 其它「 调整手感 」
    dh = "、", sl = "：“",

    -- 空白符
    zb = "	",fj = "	",kg = "    ",

    -- 序号映射
    aq = "❶",sw = "❷",de = "❸",fr = "❹",gt = "❺",hy = "❻",ju = "⓿",
    zq = "①",xw = "②",ce = "③",vr = "④",bt = "⑤",ny = "⑥",mu = "⓪",
    qz = "¹" ,wx = "²" ,ec = "³" ,rv = "⁴" ,tb = "⁵" ,yn = "⁶" ,um = "⁰" ,


    -- 常用 Emoji「 只放常用 」
    kx = "😄", xk = "🤣", sq = "😤", fn = "😡", kq = "😭", hx = "😏", tx = "🤭", em = "😈", yl = "👻", jq = "🤖", 
    ax = "💖", ct = "🎉",
    ok = "👌", dz = "👍", qd = "💰",
    ls = "📘", hs = "📕", ck = "📖", bj = "📒", wd = "📄", bw = "📋", wjj = "📁", gd = "🗂️", jp = "⌨️",
    th = "❗", wh = "❓", xh = "❌", db = "✔" , cb = "✘" , dl = "✓" , cl = "✗" , wc = "☑️", dg = "✅", cg = "❎", 
    jg = "⚠️" , bx = "🚫", ts = "🪧", hm = "🔥", mf = "🔮", sc = "⭐️", nl = "🔔", nz = "⏰", dp = "💡",
    td = "📌", hq = "🚩", lg = "💡", sn = "⚡️",
    so = "🔜", jy = "→" , jz = "←", js = "↑" , jx = "↓",jt = "➭", jl = "⇄",
    wn = "🐌", djs = "🦄", nt = "🐮",
    fq = "🍅", syc = "🍀",
    tm = "™️" , ri = "☀️",
    yf = "♪",
    
    -- 编辑常用符号
    ms = "> :: ", lo = "loveminimal", si = "https://aituyaa.com", ai = "aituyaa",
    dy = "`> `",  dk = "```",

}

-- 初始化符号输入的状态
local function init(env)
    -- 读取 RIME 配置文件中的引导符号模式
    local config = env.engine.schema.config
    -- 动态读取符号和文本重复的引导模式
    local quick_symbol_pattern = config:get_string("recognizer/patterns/quick_symbol") or "^;.*$"
    -- 提取配置值中的第二个字符作为引导符
    local quick_symbol = string.sub(quick_symbol_pattern, 2, 2) or ";"

    -- 生成多字母组合模式，匹配 ; 加一个或多个字母
    env.multi_symbol_pattern = "^" .. quick_symbol .. "([a-zA-Z]+)$"
end

-- 处理符号和文本的重复上屏逻辑
local function processor(key_event, env)
    local engine = env.engine
    local context = engine.context
    local input = context.input -- 当前输入的字符串

    -- 检查当前输入是否匹配多字母组合模式 ;q, ;qq, ;qqq, ;abc 等
    local chars = string.match(input, env.multi_symbol_pattern)
    if chars then
        -- 从映射表中获取对应的符号或文本
        local symbol = mapping[chars]
        if symbol then
            -- 将符号或文本直接上屏
            engine:commit_text(symbol)
            context:clear() -- 清空输入
            return 1 -- 捕获事件，处理完成
        end
    end
    return 2 -- 未处理事件，继续传播
end

-- 导出到 RIME
return {
    init = init,
    func = processor
}