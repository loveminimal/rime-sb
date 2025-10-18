-- 这里追加一些 Lua 工具脚本
local rime = require "lib"

-- 输入特定的日期时间缩写，输出对应的日期时间字符串
local D = {}
function D.func(input, seg)
   ---@type (string | osdate)[]
   local datetimes = {}
   if (input == "oii") then
      table.insert(datetimes, os.date("%Y-%m-%d"))
      table.insert(datetimes, os.date("%Y-%m-%d %H:%M"))
      table.insert(datetimes, os.date("`> %Y-%m-%d %H:%M`"))
   end
   for _, entry in ipairs(datetimes) do
      ---@cast entry string
      rime.yield(rime.Candidate("datetime", seg.start, seg._end, entry, ""))
   end
end

return {
   D = D
}
