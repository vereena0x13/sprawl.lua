local type              = type
local tostring          = tostring
local error             = error
local select            = select
local setfenv           = setfenv
local setmetatable      = setmetatable
local loadstring        = loadstring
local math_floor        = math.floor
local string_sub        = string.sub
local string_format     = string.format
local table_concat      = table.concat



local function shape_key(shape)
    local buf = {}
    for _, v in ipairs(shape) do buf[#buf + 1] = tostring(v) end
    return table.concat(buf, "x")
end


local indexer_cache = setmetatable({}, { __mode = "v" })
local function indexer(shape)
    local key = shape_key(shape)
    if indexer_cache[key] then return indexer_cache[key] end

    local buf = {}
    local function emit(fmt, ...) buf[#buf + 1] = string_format(fmt, ...) end

    emit("local xs = {...}")

    local dims = #shape
    for i = 1, dims do
        emit("if xs[%d] < 0 or xs[%d] >= %d then", i, i, shape[i])
        emit("error(\"index %d out of bounds: \" .. xs[%d] .. \", expected 0 to %d\")", i, i, shape[i] - 1)
        emit("end")
    end

    emit("return ")
    local m = 1
    for i = 1, dims do
        if i > 1 then emit("+") end
        emit("xs[%d]*%d", i, m)
        m = m * shape[i]
    end

    local code = table_concat(buf, " ")
    local fn = loadstring(code, "indexer(" .. key .. ")")
    setfenv(fn, { error = error })

    indexer_cache[key] = fn
    return fn
end


local function array(...)
    local shape = {...}
    if #shape == 1 and type(shape[1]) == "table" then shape = shape[1] end

    if #shape == 0 then error("arrays must be at least 1-dimensional") end

    local size = 1
    for i = 1, #shape do
        local d = shape[i]
        if type(d) ~= "number" then error("expected integer, got " .. type(d)) end
        if d ~= math_floor(d) then error("expected integer, got " .. tostring(d)) end
        if d <= 0 then error(string_format("array dimensions must be > 0, got %d for dimension #%d", d, i)) end
        size = size * d
    end

    local index = indexer(shape)
    local dims = #shape
    local data = {}

    local arr = {
        index = index,
        shape = (function()
            local xs = {}
            for i = 1, #shape do xs[#xs + 1] = shape[i] end
            return xs
        end)(),
        dims = dims,
        size = size,
        get = function(...)
            local nargs = select("#", ...)
            if nargs ~= dims then
                error(string_format("%d-dimensional array `get` got %d arguments", dims, nargs))
            end
            return data[1 + index(...)]
        end,
        set = function(...)
            local nargs = select("#", ...)
            if nargs ~= dims + 1 then
                error(string_format("%d-dimensional array `set` got %d arguments", dims, nargs))
            end
            data[1 + index(...)] = select(nargs, ...)
        end,
    }
    local arrstr = string_format("array(%s):%s", shape_key(shape), string_sub(tostring(arr), 10))
    return setmetatable(arr, {
        __metatable = "< sprawl array >",
        __newindex = function() error("array is protected") end,
        __tostring = function() return arrstr end,
        __call = function(_, ...) return arr.get(...) end
    })
end


return setmetatable({
    array = array,
    _VERSION     = 'sprawl.lua v0.1.0',
    _DESCRIPTION = '',
    _URL         = 'https://github.com/vereena0x13/sprawl.lua',
    _LICENSE     = [[
        MIT LICENSE

        Copyright (c) 2024 Vereena Inara

        Permission is hereby granted, free of charge, to any person obtaining a
        copy of this software and associated documentation files (the
        "Software"), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, sublicense, and/or sell copies of the Software, and to
        permit persons to whom the Software is furnished to do so, subject to
        the following conditions:

        The above copyright notice and this permission notice shall be included
        in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
        CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
        TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
        SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]],
}, {
    __metatable = "sprawl.lua",
    __newindex = function(_, _, _) error() end,
    __tostring = function() return "sprawl.lua" end,
    __call = function(_, ...) return array(...) end
})