-- lib/class.lua
local function include_helper(to, from, seen)
    if from == nil then return to end
    seen = seen or {}
    seen[from] = true
    for k, v in pairs(from) do
        if type(v) == "table" and not seen[v] then
            to[k] = to[k] or {}
            include_helper(to[k], v, seen)
        else
            to[k] = to[k] or v
        end
    end
    return to
end

local function Class(base)
    local c = {}
    if type(base) == "table" then
        for k, v in pairs(base) do
            c[k] = v
        end
        c._base = base
    end
    c.__index = c

    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = setmetatable({}, c)
        if obj.init then
            obj:init(...)
        end
        return obj
    end

    c.include = function(self, from)
        return include_helper(self, from)
    end

    return setmetatable(c, mt)
end

return Class