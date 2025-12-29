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
local logger = require "logger"
-- local code_table = require "code_table"

logger.info('➭ patch.lua loaded...')

-- 用于声笔飞虎中首字母大写转小写（纯习惯）
-- local function p_lower_first_char(key_event, env)
--     local context = env.engine.context
--     local input_text = context.input
--     if input_text:match('^%u') then
--         local lower_input = input_text:sub(1,1):lower() .. input_text:sub(2)
--         context.input = lower_input
--     end
--     return 2
-- end

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

-- 以 u、e 引导的候选唯一时上屏
local function f_auto_select(input, env)
    local context = env.engine.context
    local input_code = context.input
    -- local t_b = {
    --     ['a'] = true,
    --     ['e'] = true,
    --     ['u'] = true,
    --     ['i'] = true,
    --     ['o'] = true
    -- }

    local candidates = {}
    local cand_count = 0

    -- 统计候选数量
    for cand in input:iter() do
        cand_count = cand_count + 1
        candidates[cand_count] = cand
    end
    env.candidate_count = cand_count

    for i = 1, cand_count do
        local cand = candidates[i]

        if input_code:sub(0, 1) == 'e' or input_code:sub(0, 1) == 'u' then
            local len_ic = #input_code
            -- logger.info('→ ' .. len_ic)
            -- logger.info('➭ ' .. env.candidate_count)
            -- 候选唯一时直接上屏
            if len_ic > 1 and env.candidate_count == 1 then
                env.engine:commit_text(cand.text)
                context:clear()
            end
            -- local fi_ic = input_code:sub(6, 6)
            -- local si_ic = input_code:sub(7, 7)
            -- if len_ic == 5 and i == 1 then
            --     logger.info(i)
            --     logger.info(cand.text)
            --     env.cand_text = cand.text
            -- end
        end

        yield(cand)
    end
end

-- 注释那些事儿
local function f_comment(input, env)
    local context = env.engine.context
    local input_code = context.input
    -- logger.info(input_code)

    for cand in input:iter() do
        -- 移除临时飞码长词编码补全中的 ~ 符号
        -- if input_code:sub(0,1) == 'e' and cand.comment:find('~') then
        if cand.type == 'completion' and cand.comment:find('~') then
            cand:get_genuine().comment = cand.comment:sub(2)
        end

        -- 修改自造用户词提示图标
        if cand.type == 'user_table' and cand.comment:find('☯') then
            -- cand:get_genuine().comment = '🦄' -- 
            cand:get_genuine().comment = cand.comment:gsub('☯', '🦄')
        end

        -- local mark = ''
        -- ¹标识非 8105 通规字
        -- mark = code_table.index[cand.text] and '⁸' or ''
        -- cand:get_genuine().comment = mark .. cand.comment
        -- ²标识声笔字
        -- mark = (#input_code == 2 and code_table.sb[cand.text]) and 'ᵇ ' or ''
        -- cand:get_genuine().comment = mark .. cand.comment
        -- ³标识声偏字
        -- mark = (#input_code == 2 and code_table.sp[cand.text]) and 'ᵖ ' or ''
        -- cand:get_genuine().comment = mark .. cand.comment
        -- ⁴标识多音字
        -- local m_pinyin = code_table.multi[cand.text] and (' ' ..  code_table.multi[cand.text]) or ''
        -- mark = (code_table.multi[cand.text]) and 'ᵐ ' or ''
        -- cand:get_genuine().comment = mark .. cand.comment .. m_pinyin

        yield(cand)
    end

end

return {
    p_lower_first_char = p_lower_first_char,
    t_date = t_date,
    f_auto_select = f_auto_select,
    f_comment = f_comment
}
