--[[ 
这里追加一些 Lua 工具脚本
-- by Jack Liu <https://aituyaa.com>

其中：
- p_ 前缀表示 processors  → lua_processor@*p_func
- s_ 前缀表示 segmentors  → affix_segmentor
- t_ 前缀表示 translators → lua_translator@*t_func
- f_ 前缀表示 filters     → lua_filter@*f_func
--]] 

local rime = require "lib"

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

return {
   t_date = t_date
}
