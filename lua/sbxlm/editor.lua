-- 回头补码处理器
-- 适用于：声笔拼音和声笔简拼
-- 本处理器实现了自动回头补码的功能
-- 即在输入 aeiou' 时，如果末音节有 3 码，且前面至少还有一个音节，则将这个编码追加到首音节上
-- 注意，这里的音节是 Rime 中的音节概念，不一定只包含读音，也可能包含笔画

local rime = require "lib"
local this = {}

---@param env Env
function this.init(env)
  local function clear()
    env.engine.context:set_property("stroke_input", "")
    env.engine.context:refresh_non_confirmed_composition()
  end
  local context = env.engine.context
  context:delete_input()
  context.select_notifier:connect(clear)
  context.commit_notifier:connect(clear)
end

---@param key_event KeyEvent
---@param env Env
function this.func(key_event, env)
  local context = env.engine.context
  local input = rime.current(env.engine.context)
  if not input or input:len() == 0 then
    env.engine.context:set_property("stroke_input", "")
    return rime.process_results.kNoop
  end
  -- 只对无修饰按键生效
  if key_event.modifier > 0 then
    return rime.process_results.kNoop
  end
  local incoming = key_event:repr()
  if incoming == "apostrophe" then
    incoming = "'"
  end
  -- 如果输入为空格或数字，代表着作文即将上屏，此时把 kConfirmed 的片段改为 kSelected
  -- 这解决了 https://github.com/rime/home/issues/276 中的不造词问题
  if rime.match(incoming, "\\d") or incoming == "space" then
    for _, segment in ipairs(context.composition:toSegmentation():get_segments()) do
      if segment.status == rime.segment_types.kConfirmed then
        segment.status = rime.segment_types.kSelected
      end
    end
  end
  -- 在非顶功模式下和非回头补码时无效
  if not context:get_option("popping") and not context:get_option("back_insert") then
    return rime.process_results.kNoop
  end
  -- 只对 aeiou' 和 Backspace 键生效
  if not (rime.match(incoming, "[aeiou']") or incoming == "BackSpace") then
    return rime.process_results.kNoop
  end
  -- 判断是否满足补码条件：末音节有 3 码，且前面至少还有一个音节
  -- confirmed_position 是拼音整句中已经被确认的编码的长度，只有后面的部分是可编辑的
  -- current_input 获取的是这部分的编码
  -- 这样，我们就可以在拼音整句中多次应用补码，而不会影响到已经确认的部分
  local confirmed_position = context.composition:toSegmentation():get_confirmed_position()
  if not confirmed_position then
    confirmed_position = 0
  end
  local previous_caret_pos = context.caret_pos
  local current_input = context.input:sub(confirmed_position + 1, previous_caret_pos)

  -- 追加笔画
  if rime.match(current_input, "^[bpmfdtnlgkhjqxzcsrywv][aeuio']*|^[bpmfdtnlgkhjqxzcsrywv][aeuio']*[bpmfdtnlgkhjqxzcsrywv][aeuio']*") then
    local expression = "^[bpmfdtnlgkhjqxzcsrywv][aeuio']{2}.*"
    local expression2 = ".*[bpmfdtnlgkhjqxzcsrywv][aeiou']{2}"
    local len = 3
    if env.engine.schema.schema_id == "sbpy" then
      expression = "^[bpmfdtnlgkhjqxzcsrywv][aeuio']{4}.*"
      if env.engine.schema.schema_id == "sbpy" and rime.match(current_input, "^[bpmfdtnlgkhjqxzcsrywv][aeuio']{4,}") then
        expression2 = ".*[bpmfdtnlgkhjqxzcsrywv][aeiou']{4}"
      end
      len = 5
    end
    if rime.match(input, expression) then
      local stroke_input = context:get_property("stroke_input")
      if rime.match(current_input:sub(1, len) .. stroke_input, "[bpmfdtnlgkhjqxzcsrywv][aeiou']{8,}")
      and incoming ~= "BackSpace" then
        return rime.process_results.kAccepted
      end
      if incoming == "BackSpace" and stroke_input ~= "" then
        stroke_input = stroke_input:sub(1, -2)
      elseif rime.match(incoming, "[aeuio]") and rime.match(current_input, expression2) then
        stroke_input = stroke_input .. incoming
      else
        goto continue2
      end
      context:set_property("stroke_input", stroke_input)
      env.engine.context:refresh_non_confirmed_composition()
      return rime.process_results.kAccepted
    end
    ::continue2::
  end

  if not rime.match(current_input, ".+[bpmfdtnlgkhjqxzcsrywv][aeiou']{2}") then
    return rime.process_results.kNoop
  end
  -- 如果输入是 Backspace，还要验证是否有补码
  if incoming == "BackSpace" then
    if not rime.match(current_input, "[bpmfdtnlgkhjqxzcsrywv][aeiou']+.+") then
      return rime.process_results.kNoop
    end
  end
  -- 找出补码的位置（第二个音节之前），并添加补码
  -- 如果补码不足，则返回当前的位置，使得补码后的输入可以继续匹配词语；
  local position = current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2) - 1
  local offset = 0
  local len_limit = 3
  if env.engine.schema.schema_id == "sbpy" then
    len_limit = 5
  end

  if not rime.match(current_input, "^[bpmfdtnlgkhjqxzcsrywv][aeuio']*|^[bpmfdtnlgkhjqxzcsrywv][aeuio']*[bpmfdtnlgkhjqxzcsrywv][aeuio']*") then
    local position1 = current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2) - 1
    local position2 = 0
    local position3 = 0
    position = position1
    if (position1 > 2) then
      if current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2 + position1) then
        position2 = current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2 + position1) - 1
        if current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2 + position2)  then
          if (position2 - position1 > 2) then
            position3 = current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2 + position2) - 1
            offset = position2
            position = position3
            goto continue
          end
        end
        offset = position1
        position = position2
        goto continue
      end
    end
    if (position1 == 2) then
      if current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2 + position1) then
        position2 = current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2 + position1) - 1
        if current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2 + position2)  then
          if (position2 - position1 == 2) then
            position3 = current_input:find("[bpmfdtnlgkhjqxzcsrywv]", 2 + position2) - 1
            offset = position2
            position = position3
            goto continue
          end
        end
        offset = position1
        position = position2 - 1
        goto continue
      end
    end
    ::continue::
    len_limit = len_limit + offset
  end

  if position <= len_limit then
    context.caret_pos = confirmed_position + position
  end
  if incoming == "BackSpace" then
    if offset + confirmed_position == context.caret_pos - 1 then
      previous_caret_pos = context.caret_pos
      context.caret_pos = offset + confirmed_position
    end  
    context:pop_input(1)
  elseif position < len_limit then
    context:push_input(incoming)
  end
  --如果达到限制长度则禁止补码
  if position <= len_limit then
    if current_input:len() < context.input:len() then
      position = 0
    end
    if incoming == "BackSpace" then
      context.caret_pos = previous_caret_pos - 1 + position
    else
      context.caret_pos = previous_caret_pos + 1 + position
    end
  end
  return rime.process_results.kAccepted
end

return this
