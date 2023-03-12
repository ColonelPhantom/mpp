mpp = {}

mpp.c = require "c"

local function process(file)
    local f = assert(io.open(file, "r"))
    coroutine.yield([[
output = {}
function output:literal(x)
    table.insert(self, x)
end
function output:expression(f)
    table.insert(self, f)
end
]])

    for line in f:lines() do
        if line:find("^%s-" .. mpp.directive) then
            -- Line starts with MPP directive
            -- as such, it contains Lua code.
            coroutine.yield(
                line:gsub("^(%s-)" .. mpp.directive, " %1", 1))
        else
            -- Line contains host code
            -- do replace inline evaluations
            coroutine.yield(
                'output:literal("' ..
                line
                    :gsub('\\', '\\\\')
                    :gsub('"', '\\"')
                    :gsub('%$(.-)%$', '") output:expression(function() return %1 end) output:literal("')
                .. '\\n")'
            )
        end
        coroutine.yield("\n")
    end
    coroutine.yield("return output")
end

local function loadmpp(file)
    local generator = coroutine.wrap(function() process(file) end)
    local func = assert(load(generator, file))
    return func
end

local function outputmpp(file)
    local generator = coroutine.wrap(function() process(file) end)
    local f = assert(io.open(file .. ".lua", "w"))
    for line in generator do
        f:write(line)
    end
end

function mpp.execute(files)
    local outputs = {}
    for i,file in ipairs(files) do
        print("executing file " .. file)
        -- outputmpp(file .. ".mpp")
        outputs[i] = loadmpp(file .. ".mpp")()
    end
    for i,output in ipairs(outputs) do
        print("outputting file " .. files[i])
        local file = assert(io.open(files[i], "w"))
        for _, o in ipairs(output) do
            if type(o) == "string" then
                file:write(o)
            elseif type(o) == "function" then
                file:write(o())
            end
        end
        file:close()
    end
end

function mpp.hook()
    local hook = {}
    setmetatable(hook, {
        __call = function(self, code)
            table.insert(self, code .. "\n")
        end
    })
    return hook
end

function mpp.hooks()
    local hooks = {}
    setmetatable(hooks, {
        __index = function(self, key)
            self[key] = mpp.hook()
            return self[key]
        end,
        __call = function(self, key)
            output:expression(function()
                return table.concat(self[key])
            end)
        end,
    })
    return hooks
end


mpp.directive = "@"
-- mpp.execute{ "examples/template.c" }
mpp.execute{"examples/linkedlist.c"}
