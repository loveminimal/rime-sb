-- 固顶过滤器
-- 适用于：声笔拼音及其衍生方案
-- 本过滤器读取用户自定义的固顶短语，将其与当前翻译结果进行匹配，如果匹配成功，则将特定字词固顶到特定位置
-- 仅在模式为固顶、混顶、纯顶时才执行

local rime = require "lib"
local core = require "sbxlm.core"

local this = {}

---@class FixedFilterEnv: Env
---@field fixed { string : string[] }

---@param env FixedFilterEnv
function this.init(env)
  ---@type { string : string[] }
  env.fixed = {}
  local path = rime.api.get_user_data_dir() .. ("/%s.fixed.txt"):format(env.engine.schema.schema_id)
  local file = io.open(path, "r")
  if not file then
    return
  end
  for line in file:lines() do
    ---@type string, string
    local code, content = line:match("([^\t]+)\t([^\t]+)")
    if not content or not code then
      goto continue
    end
    local words = {}
    for word in content:gmatch("[^%s]+") do
      table.insert(words, word)
    end
    env.fixed[code] = words
    ::continue::
  end
  file:close()
end

---@param segment Segment
---@param env Env
function this.tags_match(segment, env)
  return segment:has_tag("abc") and segment.length <= 3
end

---@param translation Translation
---@param env FixedFilterEnv
function this.func(translation, env)
  local context = env.engine.context
  local has_fixed = not context:get_option("free")
  local fix_combination = env.engine.schema.config:get_bool("translator/fix_combination") or false
  -- 取出输入中当前正在翻译的一部分
  local segment = context.composition:toSegmentation():back()
  local input = rime.current(context)
  if not segment or not input then
    return rime.process_results.kNoop
  end
  local fixed_phrases = env.fixed[input]
  if has_fixed and fix_combination and core.sss(input) then
    local ss = (env.fixed[input:sub(1, 2)] or {})[1]
    local s = (env.fixed[input:sub(3, 3)] or {})[1]
    if ss and s then
      local candidate = rime.Candidate("combination", segment.start, segment._end, ss .. s, "")
      candidate.preedit = input:sub(1, 1) .. ' ' .. input:sub(2, 2) .. ' ' .. input:sub(3, 3)
      rime.yield(candidate)
    end
  end
  if not fixed_phrases or not has_fixed then
    for candidate in translation:iter() do
      rime.yield(candidate)
    end
    return
  end
  -- 生成固顶候选
  ---@type Candidate[]
  local unknown_candidates = {}
  ---@type { string: Candidate }
  local known_candidates = {}
  local i = 1
  for candidate in translation:iter() do
    local text = candidate.text
    local is_fixed = false
    -- 对于一个新的候选，要么加入已知候选，要么加入未知候选
    for _, phrase in ipairs(fixed_phrases) do
      if text == phrase then
        known_candidates[phrase] = candidate
        is_fixed = true
        break
      end
    end
    if not is_fixed then
      table.insert(unknown_candidates, candidate)
    end
    -- 每看过一个新的候选之后，看看是否找到了新的固顶候选，如果找到了，就输出
    local current = fixed_phrases[i]
    if current and known_candidates[current] then
      local cand = known_candidates[current]
      local select = "14560"
      local select2 = "aeuio"
      local is_hidden = env.engine.context:get_option("is_hidden")
      local id = env.engine.schema.schema_id
      if (id == 'sbpy' or id == 'sbjp') then
        local comment = fixed_phrases[i + 5] == nil and "" or fixed_phrases[i + 5]
        local comment2 = fixed_phrases[i + 12] == nil and "" or fixed_phrases[i + 12]
        if i > 1 and not is_hidden then
          cand.comment = comment .. select:sub(i - 1, i - 1)
          if rime.match(input, "[bpmfdtnlgkhjqxzcsrywv]") and id == 'sbpy' then
            cand.comment = cand.comment .. comment2 .. select2:sub(i - 1, i - 1)
          end
        elseif i == 1 then
          if rime.match(input, "[bpmfdtnlgkhjqxzcsrywv][aeuio]?") and id == 'sbjp' then
            cand.comment = fixed_phrases[i + 12] .. ";" .. fixed_phrases[i + 11] .. "'"
          elseif rime.match(input, "[bpmfdtnlgkhjqxzcsrywv]") and id == 'sbpy' then
            cand.comment = fixed_phrases[i + 12] .. ";" .. fixed_phrases[i + 11] .. "'"
          end
        end
      end
      cand.type = "fixed"
      rime.yield(cand)
      i = i + 1
    end
  end
  -- 输出设为固顶但是没在候选中找到的候选
  -- 因为不知道全码是什么，所以只能做一个 SimpleCandidate
  while fixed_phrases[i] do
    local cand = rime.Candidate("fixed", segment.start, segment._end, fixed_phrases[i], "")
    cand.preedit = input
    local select = "14560"
    local select2 = "aeuio"
    local is_hidden = env.engine.context:get_option("is_hidden")
    local id = env.engine.schema.schema_id
    if (id == 'sbpy' or id == 'sbjp') then
      local comment = fixed_phrases[i + 5] == nil and "" or fixed_phrases[i + 5]
      local comment2 = fixed_phrases[i + 12] == nil and "" or fixed_phrases[i + 12]
      if i > 1 and not is_hidden then
        cand.comment = comment .. select:sub(i - 1, i - 1)
        if rime.match(input, "[bpmfdtnlgkhjqxzcsrywv]") and id == 'sbpy' then
          cand.comment = cand.comment .. comment2 .. select2:sub(i - 1, i - 1)
        end
      elseif i == 1 then
        if rime.match(input, "[bpmfdtnlgkhjqxzcsrywv][aeuio]?") and id == 'sbjp' then
          cand.comment = fixed_phrases[i + 11] .. "'" .. fixed_phrases[i + 12] .. ";"
        elseif rime.match(input, "[bpmfdtnlgkhjqxzcsrywv]") and id == 'sbpy' then
          cand.comment = fixed_phrases[i + 11] .. ";" .. fixed_phrases[i + 12] .. "'"
      end
    end
    end
    rime.yield(cand)
    i = i + 1
  end
  -- 输出没有固顶的候选
  for _, candidate in ipairs(unknown_candidates) do
    rime.yield(candidate)
  end
end

return this
