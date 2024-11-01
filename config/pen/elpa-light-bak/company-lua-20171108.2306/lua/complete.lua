local function addmatch(word, kind, args, returns, doc)
  word = word and word or ""
  kind = kind and kind or ""
  args = args and args or ""
  returns = returns and returns or ""
  doc = doc and doc:gsub("\n", "\\n") or ""
  print(string.format("word:%s,kind:%s,args:%s,returns:%s,doc:%s", word, kind, args, returns, doc))
end

local getPath = function(str,sep)
  sep=sep or'/'
  return str:match("(.*"..sep..")")
end

local thisDir = getPath(arg[0])
package.path = package.path .. ";" .. thisDir .. "?.lua"

local stringStartsWith = function(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

local function getValueForKey(t, key)
  for k, v in pairs(t) do
    if k == key then
      if v.childs then
        return v.childs
      end
    end
  end
  return nil
end

local validForInterpreter = function(s, interp)
  if not s then
    return false
  end
  if interp == "lua51" then
    if string.match(s, "ADDED IN Lua") then
      return false
    end
  elseif interp == "lua52" then
    if string.match(s, "ADDED IN Lua 5.3") then
      return false
    end
  end
  return true
end

local function generateList()
  local interpreter = arg[1]
  local prefix = arg[2]
  local prefixTable = {}

  if not prefix then
    return
  end

  local lastCharIsTrigger = string.sub(prefix, -1) == '.'

  for str in string.gmatch(prefix, "[^.]+") do
    table.insert(prefixTable, str)
  end

  local apis = {"baselib"}
  if interpreter == "love" then
    table.insert(apis, "love2d")
  end

  for _, api in pairs(apis) do
    local status, module = pcall(require, "api/" .. api)
    if status and module then
      local mod = module
      for i = 1, #prefixTable do
        if i ~= #prefixTable or lastCharIsTrigger then
          local val = getValueForKey(mod, prefixTable[i])
          if val then
            mod = val
          else
            break
          end
        end

        if i == #prefixTable then
          for k, v in pairs(mod) do
            if stringStartsWith(k, prefixTable[i]) or lastCharIsTrigger then
              local word, kind, args, returns, doc
              word = k
              kind = v.type and v.type
              args = v.args and v.args
              returns = v.returns and v.returns
              doc = v.description and v.description
              if validForInterpreter(doc, interpreter) then
                addmatch(word, kind, args, returns, doc)
              end
            end
          end
        end
      end
    end
  end
end

generateList()
