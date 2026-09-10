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
-- local logger = require "logger"	-- 💡注意开发测试完毕后要关闭，否则配置在移动端会出问题
-- local code_table = require "code_table"

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
    local first_char = input_code:sub(1, 1)
    local second_char = input_code:sub(2, 2)
    -- local sbfm_ext_prefix = env.engine.schema.config:get_string("sbfm_ext/prefix") or "'"	-- 获取飞码长词引导符
    
    -- if first_char ~= 'u' and first_char ~= sbfm_ext_prefix or #input_code <= 1 then
    -- if first_char ~= 'u' and first_char ~= 'e' or #input_code <= 1 then
    -- if input_code:match("^u[bpmfdtnlgkhjqxzcsrywv][a-z]*$") == nil then
    -- 笔画类的直接放行 
    if input_code:match("^u[aeuio]*$") ~= nil then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end
    
    local first_cand = nil
    local second_cand = nil
    local has_output = false
    
    for cand in input:iter() do
        if not first_cand then
            first_cand = cand
        elseif not second_cand then
            second_cand = cand
            -- 发现第二个候选，开始输出
            yield(first_cand)
            yield(second_cand)
            has_output = true
        else
            -- 继续输出后续候选
            yield(cand)
        end
        
    end
    
    -- 循环结束后的处理 -- 说明只有0或1个候选
    if not has_output and first_cand then
        env.engine:commit_text(first_cand.text)
        context:clear()
    end
end

-- 注释那些事儿
local function f_comment(input, env)
    local context = env.engine.context
    local input_code = context.input

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

-- 除首选外不显示词
local function f_filter_non_first_word(input, env)
    -- local is_sbxd = env.engine.schema.schema_id == 'sbxd'
    local context = env.engine.context
	local is_show_word = context:get_option("is_show_word") or false    
    local count = 0
    local first_char = context.input:sub(1, 1)
    
    for cand in input:iter() do
        count = count + 1
        
        -- if is_show_word then
        if is_show_word or string.find('aeuio', first_char) then
            yield(cand)
        else
            if count == 1 then
                yield(cand)
            else
                if (utf8.len(cand.text) == 1) then
                    yield(cand)
                end
            end
        end    
    end    
end

-- 暴力 GC
-- 详情 https://github.com/hchunhui/librime-lua/issues/307
-- collectgarbage()：默认调用，等同于 collectgarbage("collect")，触发完整的垃圾回收。
-- collectgarbage("step")：执行垃圾回收的一小步。这个函数会返回一个布尔值，表示这一步是否完成了整个收集周期。
-- 这样也不会导致卡顿，那就每次都调用一下吧，内存稳稳的
local function t_force_gc()
    -- collectgarbage()
    collectgarbage("step")
end


return {
    -- p_lower_first_char = p_lower_first_char,
    t_date = t_date,
    t_force_gc = t_force_gc,
    f_auto_select = f_auto_select,
    f_comment = f_comment,
    -- f_filter_non_first_word = f_filter_non_first_word,
}
