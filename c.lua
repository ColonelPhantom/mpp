local c = {}

function c.struct(name, fields_init)
    local fields = fields_init or {}
    local struct = {}
    output:expression(function()
        local s = "struct " .. name .. " {\n"
        for _,v in pairs(fields) do
            s = s .. "\t" .. v .. ";\n"
        end
        return s.. "};\n"
    end)
    setmetatable(struct, {
        __index = fields,
        __newindex = function(self, key, value)
            if self[key] and self[key] ~= value then
                error("Conflicting defintions of " .. name .. "." .. key .. ":\n\t'" .. self[key] .. "'\n\t'" .. value .. "'");
            else
                fields[key] = value
            end
        end,
        __tostring = function()
            return "struct " .. name
        end
    })
    _G[name] = struct
    return struct
end

return c
