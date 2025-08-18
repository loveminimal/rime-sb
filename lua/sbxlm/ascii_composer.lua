-- 中英混输处理器
-- 通用（不包含声笔系列码的特殊逻辑）
-- 本处理器实现了 Shift+Enter 反转首字母大小写、Control+Enter 反转编码大小写等功能

local XK_Return = 0xff0d
local XK_Tab = 0xff09
local XK_Escape = 0xff1b
local XK_space = 0x0020
local rime = require "lib"
local core = require "sbxlm.core"

local this = {}

---@class AsciiComposerEnv: Env
---@field ascii_composer Processor
---@field selector Processor
---@field single_selection boolean
---@field delayed_pop boolean
---@field connection Connection

---@param env AsciiComposerEnv
function this.init(env)
  env.ascii_composer = rime.Processor(env.engine, "", "ascii_composer")
  env.selector = rime.Processor(env.engine, "", "selector")
  local config = env.engine.schema.config
  env.single_selection = config:get_bool("translator/single_selection") or false
  env.delayed_pop = env.engine.context:get_option("delayed_pop") or false
end

---@param ch number
local function is_upper(ch)
  -- ch >= 'A' and ch <= 'Z'
  return ch >= 0x41 and ch <= 0x5a
end

---@param ch number
local function is_lower(ch)
  -- ch >= 'a' and ch <= 'z'
  return ch >= 0x61 and ch <= 0x7a
end

---@param context Context
---@param env AsciiComposerEnv
local function switch_inline(context, env)
  context:set_option("ascii_mode", true)
  env.connection = context.update_notifier:connect(function(ctx)
    if not ctx:is_composing() then
      env.connection:disconnect()
      ctx:set_option("ascii_mode", false)
    end
  end)
end

---@param key_event KeyEvent
---@param env AsciiComposerEnv
function this.func(key_event, env)
  local context = env.engine.context
  local input = context.input
  local ascii_mode = context:get_option("ascii_mode")
  local auto_inline = context:get_option("auto_inline")
  local schema_id = env.engine.schema.schema_id

  -- auto_inline 启用时，首字母大写时自动切换到内联模式
  if not ascii_mode and auto_inline and input:len() == 0 and is_upper(key_event.keycode) and not key_event:caps() then
    if (key_event:shift() and key_event:ctrl()) or key_event:alt() or key_event:super() or key_event:release() then
      return rime.process_results.kNoop
    end
    context:push_input(string.char(key_event.keycode))
    switch_inline(context, env)
    -- hack，随便发一个没用的键让 ascii_composer 忘掉之前的 shift
    env.engine:process_key(rime.KeyEvent("Release+A"))
    return rime.process_results.kAccepted
  end

  -- 首字母后的 Tab 键切换到临时英文，Shift+Tab 键切换到缓冲模式
  local segment = env.engine.context.composition:back()
  if not segment then
    return rime.process_results.kNoop
  end
  if (not ascii_mode and segment and not segment:has_tag("punct") and not key_event:release()) then
    if input:len() == 1 and key_event.keycode == XK_Tab then
      if key_event:shift() then
        if not context:get_option("is_buffered") then
          context:set_option("is_buffered", true)
        end
        context:set_option("temp_buffered", true)
      else
        switch_inline(context, env)
      end
      return rime.process_results.kAccepted
    elseif segment._end > segment._start and key_event.keycode == XK_Return and context:get_option("is_buffered") then
      context:commit()
      return rime.process_results.kAccepted
    end
  end
  -- 在码长为4以上时，设置临时重码提示，飞系单字除外
  if (not ascii_mode and segment and segment:has_tag("abc") and input:len() >= 4 and input:len() <= 5
        and key_event.keycode == XK_Tab and not key_event:release()
        and not (core.feixi(schema_id) and rime.match(input, "[bpmfdtnlgkhjqxzcsrywv][a-z][aeuio]{2}"))) then
    if env.single_selection and context:get_option("single_display")
        and not context:get_option("not_single_display") then
      context:set_option("not_single_display", true)
      if not ((core.fm(schema_id) or core.fy(schema_id)) and context:get_option("delayed_pop")
            and rime.match(input, "([bpmfdtnlgkhjqxzcsrywv][a-z]){2}[aeuio]*"))
          and key_event.modifier ~= rime.modifier_masks.kShift then
        env.selector:process_key_event(key_event)
        return rime.process_results.kAccepted
      end
    end
    return rime.process_results.kNoop
    -- 声笔简码在码长5以上时，单引号进入打空造词
  elseif (not ascii_mode and segment and segment:has_tag("abc") and segment.length >= 5
        and key_event.keycode == string.byte("'") and not key_event:release()
        and core.jm(env.engine.schema.schema_id)) then
    local diff = 0
    if segment.length == 6 then diff = 1 end
    context:pop_input(segment.length - 4)
    context.caret_pos = segment.start + 1
    context:push_input(input:sub(input:len() - diff, -1))
    return rime.process_results.kAccepted
    -- 声笔双拼在码长5以上时，单引号进入打空造词
  elseif (not ascii_mode and segment and segment:has_tag("abc") and segment.length >= 5
        and key_event.keycode == string.byte("'") and not key_event:release()
        and core.sp(env.engine.schema.schema_id)) then
    local diff = 0
    if segment.length == 6 then diff = 1 end
    context:pop_input(segment.length - 4)
    context.caret_pos = segment.start + 2
    context:push_input(input:sub(input:len() - diff, -1))
    return rime.process_results.kAccepted
    -- 声笔飞码在码长5以上时，单引号进入打空造词，但丢弃已经追加的笔画
  elseif (not ascii_mode and segment and segment:has_tag("abc") and segment.length >= 5
        and key_event.keycode == string.byte("'") and not key_event:release()
        and core.fm(env.engine.schema.schema_id)) then
    local diff = 0
    if segment.length == 6 then diff = 1 end
    context:pop_input(segment.length - 4)
    context.caret_pos = segment.start + 2
    return rime.process_results.kAccepted
  end
  -- 在码长为1时，取消临时重码提示
  if not ascii_mode and segment and segment:has_tag("abc") and core.zici(schema_id)
      and not key_event:release() and input:len() == 1 and context:get_option("single_display") then
    context:set_option("not_single_display", false)
  end

  -- 声笔拼音和声笔简拼在混合模式时的回头补码状态
  if not ascii_mode and segment and segment:has_tag("abc") and (schema_id == "sbpy" or schema_id == "sbjp")
      and not key_event:release() and input:len() == 2 and context:get_option("mixed") then
    if is_lower(key_event.keycode) then
      if rime.match(input, "[bpmfdtnlgkhjqxzcsrywv]{2}") then
        context:set_option("back_insert", true)
      else
        context:set_option("back_insert", false)
      end
    end
  end

  -- 声笔拼音和声笔简拼在组合变换时不造词
  if not ascii_mode and segment and segment:has_tag("abc") and (schema_id == "sbpy" or schema_id == "sbjp")
      and not key_event:release() then
    local str = input:sub(segment._start, segment._end)
    if key_event.keycode == string.byte(";") then
      if rime.match(str, "[bpmfdtnlgkhjqxzcsrywv]{2}[a-z]?") then
        context.caret_pos = segment.start + 1
        context:commit()
        context:push_input(str:sub(2))
        context:commit()
        return rime.process_results.kAccepted
      elseif key_event.keycode == string.byte(";") and rime.match(str, "[bpmfdtnlgkhjqxzcsrywv]{3}[a-z]") then
        context.caret_pos = segment.start + 2
        context:commit()
        context:push_input(str:sub(3))
        context:commit()
        return rime.process_results.kAccepted
      end
    end
    if key_event.keycode == string.byte("'")
        or key_event.keycode == XK_space and key_event.modifier == rime.modifier_masks.kShift then
      if rime.match(str, "[bpmfdtnlgkhjqxzcsrywv]{3}") then
        context.caret_pos = segment.start + 1
        context:commit()
        context:push_input(str:sub(2, 2))
        context:commit()
        context:push_input(str:sub(3, 3))
        context:commit()
        return rime.process_results.kAccepted
      end
    end
    if key_event.keycode == XK_Tab then
      if rime.match(str, "[bpmfdtnlgkhjqxzcsrywv]{3}") then
        context.caret_pos = segment.start + 2
        context:commit()
        context:push_input(str:sub(3, 3))
        context:commit()
        return rime.process_results.kAccepted
      end
    end
    if key_event.keycode == XK_space and key_event.modifier == rime.modifier_masks.kShift then
      if rime.match(str, "[bpmfdtnlgkhjqxzcsrywv]{4}") then
        context.caret_pos = segment.start + 2
        context:commit()
        context:push_input(str:sub(3, 3))
        context:commit()
        context:push_input(str:sub(4, 4))
        context:commit()
        return rime.process_results.kAccepted
      end
    end
  end

  if input:len() == 0 then
    return rime.process_results.kNoop
  end

  -- 用 Shift+Return 或者 Control+Return 反转大小写
  if key_event.modifier == rime.modifier_masks.kShift and key_event.keycode == XK_Return then
    if is_upper(input:byte(1)) then
      env.engine:commit_text(input:sub(1, 1):lower() .. input:sub(2))
    else
      env.engine:commit_text(input:sub(1, 1):upper() .. input:sub(2))
    end
    context:clear()
    return rime.process_results.kAccepted
  end
  if key_event.modifier == rime.modifier_masks.kControl and key_event.keycode == XK_Return then
    env.engine:commit_text(input:upper())
    context:clear()
    return rime.process_results.kAccepted
  end

  -- Esc 键取消输入
  if key_event.keycode == XK_Escape then
    context:clear()
    return rime.process_results.kAccepted
  end
  return rime.process_results.kNoop
end

return this
