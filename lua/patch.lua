--[[ 
这里追加一些 Lua 工具脚本
-- by Jack Liu <https://aituyaa.com>

其中：
- p_ 前缀表示 processors  → lua_processor@*p_func
- s_ 前缀表示 segmentors  → affix_segmentor
- t_ 前缀表示 translators → lua_translator@*t_func
- f_ 前缀表示 filters     → lua_filter@*f_func
--]] --
local rime = require "lib"
-- local logger = require "logger"
-- local code_table = require "code_table"

local function is_chinese_char(char)
    local codepoint = utf8.codepoint(char, 1)
    if not codepoint then
        return false
    end
    return (
        (codepoint >= 0x4E00  and codepoint <= 0x9FFF) or    --  基本汉字
        (codepoint >= 0x3400  and codepoint <= 0x4DBF) or    --  扩展 A
        (codepoint >= 0x20000 and codepoint <= 0x2A6DF) or   --  扩展 B
        (codepoint >= 0x2A700 and codepoint <= 0x2B739) or   --  扩展 C
        (codepoint >= 0x2B740 and codepoint <= 0x2B81D) or   --  扩展 D
        (codepoint >= 0x2B820 and codepoint <= 0x2CEAF) or   --  扩展 E
        (codepoint >= 0x2CEB0 and codepoint <= 0x2EBEF) or   --  扩展 F
        (codepoint >= 0x30000 and codepoint <= 0x3134A) or   --  扩展 G
        (codepoint >= 0xF900  and codepoint <= 0xFAFF) or    --  兼容汉字
        (codepoint >= 0x2E80  and codepoint <= 0x2EFF) or    --  部首补充
        (codepoint >= 0x2F00  and codepoint <= 0x2FDF) or    --  康熙部首
        (codepoint >= 0x2FF0  and codepoint <= 0x2FFF) or    --  汉字结构符
        -- (codepoint >= 0x3000  and codepoint <= 0x303F) or    --  中文标点
        (codepoint >= 0x3105  and codepoint <= 0x312F)       --  注音符号
    )

end

-- 输入特定的日期时间缩写，输出对应的日期时间字符串
local t_date = {}
function t_date.func(input, seg)
    ---@type (string | osdate)[]
    local datetimes = {}
    if (input == "oii") then
        table.insert(datetimes, os.date("%Y-%m-%d"))
        table.insert(datetimes, os.date("%Y-%m-%d %H:%M"))
        table.insert(datetimes, os.date("`> %Y-%m-%d %H:%M`"))
        table.insert(datetimes, os.date("%H:%M"))
    end
    for _, entry in ipairs(datetimes) do
        ---@cast entry string
        rime.yield(rime.Candidate("datetime", seg.start, seg._end, entry, ""))
    end
end

-- 注释那些事儿
local function f_comment(input, env)
    -- logger.info(env.engine.context.input)
    for cand in input:iter() do
        -- local pinyin = code_table.pinyin[cand.text]
        -- local index = code_table.index[cand.text]
        -- local is_chinese = is_chinese_char(cand.text)

        -- logger.info(cand.text, pinyin, idx)
        -- logger.info(is_chinese)

        -- 修改自造用户词提示图标
        if cand.type == 'user_table' and cand.comment:find('☯') then
            cand:get_genuine().comment = '🦄' -- 
        end

        -- 标识非 8105 通规字
        -- cand:get_genuine().comment = cand.comment .. (is_chinese and (index and '' or ' ✗') or '')

        yield(cand)
    end
end

return {
    t_date = t_date,
    f_comment = f_comment
}
