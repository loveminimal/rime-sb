-- Created by Jack Liu <https://aituyaa.com>
-- 
-- 主键区符号映射，如：;q -> @、;w -> !
-- 使用 ; 作引导符，输入一个主键后立即上屏
-- ---------------------------------

local mapping = {
    -- 数字组合
    ['1'] = "📌", ['2'] = "(", ['3'] = "⭐️", ['4'] = ")", ['5'] = "🔔", 
    ['6'] = "🔥", ['7'] = "🪧", ['8'] = "🚫", ['9'] = "💡", ['0'] = "🦄", 
    -- 符号组合
    ['-'] = "_",  ['='] = "+",
    ['['] = ",",  [']'] = "'", ['\\'] = "|", 
    [';'] = ";", ['\''] = "'", 
    [','] = ",", ['.'] = ".", ['/'] = "/", 
    -- 主键单击
    q = "!"  , w = "@"  , e = "#"  , r = "$"  , t = "%"  , y = "^"  , u = "_"  , i = "-"  , o = "="  , p = "➭",
      a = "&", s = ":"  , d = "`"  , f = "	"  , g = "*"  , h = "|"  , j = "+"  , k = "?"  , l = '"',
        z = "\\", x = "{", c = "}"  , v = "["  , b = "]"  , n = "<"  , m = ">",


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
    yf = "♪",  ig = "⏭️",
}

-- 初始化符号输入的状态
local function init(env)
    local config = env.engine.schema.config
    env.quick_symbol_pattern = config:get_string("recognizer/patterns/quick_symbol") or "^;.$"
end

local function get_key_char(key_event)
    if key_event:release() or key_event:ctrl() or key_event:alt() or key_event:super() then
        return nil
    end
    if key_event.keycode < 0x20 or key_event.keycode > 0x7e then
        return nil
    end
    return string.char(key_event.keycode):lower()
end

local function processor(key_event, env)
    local engine = env.engine
    local context = engine.context
    local input = context.input

    -- 处理器运行在 speller 之前，需把当前按键补到已有输入后再匹配
    if input == ";" then
        local char = get_key_char(key_event)
        local pending_input = char and (input .. char) or input
        local symbol = pending_input:match(env.quick_symbol_pattern) and mapping[char]
        if symbol then
            engine:commit_text(symbol)
            context:clear()
            return 1
        end
    end
    return 2
end

-- 导出到 RIME
return {
    init = init,
    func = processor
}
