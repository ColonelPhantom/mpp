local mpp = {}

local output = {}

local function process(file)
    local script = ""
    local f = io.open(file, "r")
    coroutine.yield([[
local output = {}
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
    local f = io.open(file .. ".lua", "w")
    for line in generator do
        f:write(line)
    end
end

function mpp.execute(files)
    local outputs = {}
    for i,file in ipairs(files) do
        outputmpp(file .. ".mpp")
        outputs[i] = loadmpp(file .. ".mpp")()
    end
    for i,output in ipairs(outputs) do
        local file = io.open(files[i], "w")
        for j, o in ipairs(output) do
            if type(o) == "string" then
                file:write(o)
            elseif type(o) == "function" then
                file:write(o())
            end
        end
        file:close()
    end
end


mpp.directive = "@"
mpp.execute{ "template.c" }