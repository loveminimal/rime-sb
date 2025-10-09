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
-- 2025-10-09 15:54 当 3 个字母组合不再需要结束标识符，直接作为 key 查找
-- 2025-10-09 10:49 增加多个字母组合模式支持，如 ;q;' , ;qq;' , ;abc 等

local logger = require("logger")
-- —— 设置 ——
-- 结尾识别符「 支持正则 」，为空时仅支持主键单击
local end_identifier = "[;']"	-- ; 或 '

local mapping = {
    -- qq = "!", ww = "@", ee = "#", rr = "$", tt = "%", yy = "^", uu = "_", ii = "-", oo = "=", pp = "+",
    -- aa = "&", ss = "(", dd = ")", ff = "{", gg = "}", hh = "=", jj = ",", kk = ".", ll = ";", 
    -- zz = "|", xx = "[", cc = "]", vv = "*", bb = "`", nn = "〔", mm = "〕"
    
    -- 主键单击「 半角 」
    q = "@"			, w = "!"	, e = "#"	, r = "$"	, t = "%"	, y = "^"	, u = "_"	, i = "-"	, o = "="	, p = "~"	,
      a = "&"		, s = ":"	, d = "`"	, f = ";"	, g = "*"	, h = "|"	, j = "+"	, k = "'"	, l = '"'	,
        z = "\\"	, x = ","	, c = "."	, v = "<"	, b = ">"	, n = "/"	, m = "?"	,
    -- 主键双击「 全角+ 」
    qq = ""			, ww = "！"	, ee = ""	, rr = "¥"		, tt = "％"	, yy = "……"	, uu = "¦"	, ii = "——"	, oo = "・"	, pp = ""  ,
      aa = "&&"		, ss = "："	, dd = "、"	, ff = "；" 	, gg = "×"	, hh = "||"	, jj = "+"	, kk = "'"	, ll = '"'	,
        zz = "、"	, xx = "，"	, cc = "。"	, vv = "《" 	, bb = "》"	, nn = "·"	, mm = "？"	,

    -- 全角映射「 废弃 」
    -- qa = ""			, ws = ""	, ed = ""	, rf = ""	, tg = ""	, yh = ""	, uj = ""	, ik = ""	, ol = ""	,
    --   az = ""		, sx = ""	, dc = ""	, fv = ""	, gb = ""	, hn = ""	, jm = ""	,
    --     za = ""		, xs = ""	, cd = ""	, vf = ""	, bg = ""	, nh = ""	, mj = ""	,

    -- 对符映射
    qw = "1"	, wq = "2"	, we = "3"		, ew = "4"		, er = "5"		, re = "6"		, rt = ""		, tr = ""		, ty = ""		, 
      yt = ""	, yu = ' '	, uy = ""		, ui = ""		, iu = ""		, io = ""		, oi = ""		, op = ""		, po = ""		,
          as = "7"			, sa = "8"		, sd = "("		, ds = ")"		, df = "["		, fd = "]"		, fg = "{"		, gf = "}"		, 
            gh = '【 '		, hg = ' 】'	, hj = "『 "	, jh = " 』"	, jk = "‘"		, kj = "’"		, kl = "“"		, lk = "”"		,
                zx = "9"	, xz = "0"		, xc = "（"		, cx = "）"		, cv = "「 "	, vc = " 」"	, vb = "〔 "	, bv = " 〕"	, 
                  bn = '〈'	, nb = "〉"		, nm = "《"		, mn = "》"		,
    
    -- 其它「 调整手感 」
    dh = "、"	, sl = "：“"	,

    -- 空白符
    fj = "	"	, kg = "    "	,

    -- 序号映射
    aq = "❶"	, sw = "❷"	, de = "❸"	, fr = "❹"	, gt = "❺"	, hy = "❻"	, ju = "⓿"	,
    zq = "①"	, xw = "②"	, ce = "③"	, vr = "④"	, bt = "⑤"	, ny = "⑥"	, mu = "⓪"	,
    qz = "¹"	 , wx = "²"	  , ec = "³"	, rv = "⁴"	, tb = "⁵"	 , yn = "⁶"	  , um = "⁰"	,


    -- 常用 Emoji「 只放常用 」
    kx = "😄", xk = "🤣", sq = "😤", fn = "😡", kq = "😭", hx = "😏", tx = "🤭", em = "😈", yl = "👻", jq = "🤖", 
    ax = "💖", cd = "🎉",
    ok = "👌", dz = "👍", qd = "💰",
    xls = "📘", xhs = "📕", ck = "📖", cks = "📖", bjb = "📒", wd = "📄", bwl = "📋", wjj = "📁", gd = "🗂️", jp = "⌨️",
    th = "❗", wh = "❓", ch = "❌", dhz = "☑️", dhl = "✅", chl = "❎", dhc = "✔" , chc = "✘", dhx = "✓", chx = "✗",  
    jz = "🚫", ts = "🪧", hm = "🔥", mf = "🔮", sc = "⭐️", nl = "🔔", nz = "⏰", dp = "💡",
    zd = "📌", hq = "🚩", lg = "💡", xsd = "⚡️",
    so = "🔜", jty = "→", jtz = "←", jts = "↑", jtx = "↓", jt = "➭" ,
    wn = "🐌", djs = "🦄", nt = "🐮",
    fq = "🍅", syc = "🍀",
    
    tm = "™️", ri = "☀️", jg = "⚠️", yf = "♪",
    
    -- 编辑常用符号
    ms = "> :: ", sj = "18539282698", lo = "loveminimal", si = "https://aituyaa.com", ai = "aituyaa",
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

    -- 生成多字母组合模式
    -- 匹配 ; 加一个或多个字母，以 ;或' 结尾（传统模式）
    env.traditional_pattern = "^" .. quick_symbol .. ("([a-zA-Z]+)" .. end_identifier .. "$")
    -- 新增：匹配 ; 加正好3个字母（新需求，不需要结束标识符）
    env.three_letter_pattern = "^" .. quick_symbol .. ("([a-zA-Z][a-zA-Z][a-zA-Z])$")
end

-- 处理符号和文本的重复上屏逻辑
local function processor(key_event, env)
    local engine = env.engine
    local context = engine.context
    local input = context.input -- 当前输入的字符串

    -- 首先检查是否是3字母组合（新需求）
    local three_letter_chars = string.match(input, env.three_letter_pattern)
    if three_letter_chars then
        local symbol = mapping[three_letter_chars]
        if symbol then
            engine:commit_text(symbol)
            context:clear()
            return 1
        end
    end

    -- 然后检查传统模式（需要结束标识符）
    local chars = string.match(input, env.traditional_pattern)
    if chars then
        local symbol = mapping[chars]
        if symbol then
            engine:commit_text(symbol)
            context:clear()
            return 1
        end
    end
    
    return 2 -- 未处理事件，继续传播
end

-- 导出到 RIME
return {
    init = init,
    func = processor
}