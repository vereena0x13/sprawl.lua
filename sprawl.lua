local type              = type
local tostring          = tostring
local error             = error
local select            = select
local unpack            = unpack and unpack or table.unpack
local pairs             = pairs
local ipairs            = ipairs
local setmetatable      = setmetatable
local math_floor        = math.floor
local string_sub        = string.sub
local sprintf           = string.format
local table_concat      = table.concat


local loadstr
if type(setfenv) == "function" then
    local loadstring = loadstring
    local setfenv = setfenv
    loadstr = function(code, name, env)
        local fn, err = loadstring(code, name)
        if err then error(err) end
        if env then setfenv(fn, env) end
        return fn
    end
else
    local load = load
    loadstr = function(code, name, env)
        local fn, err
        if env then fn, err = load(code, name, "t", env) else fn, err = load(code, name, "t") end
        if err then error(err) end
        return fn
    end
end


local function copy_into(dst, src)
    for k, v in pairs(src) do dst[k] = v end
end


local function copy(...)
    local r = {}
    local xs = {...}
    for i = 1, #xs do
        local x = xs[i]
        if x ~= nil then
            copy_into(r, x)
        end
    end
    return r
end


local function errorf(...) return error(sprintf(...)) end


local function shape_key(shape)
    local buf = {}
    for _, v in ipairs(shape) do buf[#buf + 1] = tostring(v) end
    return table_concat(buf, "x")
end


local indexer_cache = setmetatable({}, { __mode = "v" })
local function indexer(shape)
    local key = shape_key(shape)
    if indexer_cache[key] then return indexer_cache[key] end

    local buf = {}
    local function emit(fmt, ...) buf[#buf + 1] = sprintf(fmt, ...) end

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
    local fn = loadstr(code, "indexer(" .. key .. ")", { error = error })

    indexer_cache[key] = fn
    return fn
end


local function generate_access(arr, index, data, name, fstr)
    local buf = {}
    local function emit(fmt, ...) buf[#buf + 1] = sprintf(fmt, ...) end

    local n = arr.dims
    if name == "set" then n = n + 1 end

    emit("return function(index, data)")
        emit("return function(...)")
            emit("local nargs = select(\"#\", ...)")
            emit("if nargs ~= %d then", n)
                emit("error(\"%s::%s got \" .. nargs .. \" arguments\")", tostring(arr), name)
            emit("end")
        emit("%s", fstr)
        emit("end")
    emit("end")

    local code = table_concat(buf, ' ')
    local fn = loadstr(code, tostring(arr) .. "::" .. name .. "ter")
    return fn()(index, data)
end


local function array(...)
    local shape = {...}

    if #shape == 0 then error("arrays must be at least 1-dimensional") end
    
    if #shape == 1 and type(shape[1]) == "table" then shape = shape[1] end
    setmetatable(shape, { __newindex = function() error("access violation") end })

    if #shape == 0 then error("arrays must be at least 1-dimensional") end -- TODO: deduplicate

    local dims = #shape
    local size = 1
    for i = 1, dims do
        local d = shape[i]
        if type(d) ~= "number" then error("expected integer, got " .. type(d)) end
        if d ~= math_floor(d) then error("expected integer, got " .. tostring(d)) end
        if d <= 0 then errorf("array dimensions must be > 0, got %d for dimension #%d", d, i) end
        size = size * d
    end

    local data = {}
    local index = indexer(shape)

    local arr = {
        index = index,
        shape = shape,
        dims = dims,
        size = size,
    }

    function arr.iter_raw()
        local is = {}
        for i = 1, dims do is[#is + 1] = 0 end

        local run = true
        return function()
            if not run then return end

            local xs = copy(is)

            for i = 1, dims do
                local t = is[i] + 1
                if t >= shape[i] then
                    is[i] = 0
                    if i == dims then run = false end
                else
                    is[i] = t
                    break
                end
            end

            xs[#xs + 1] = arr.get(unpack(xs))
        
            return xs
        end
    end

    function arr.iter()
        local it = arr.iter_raw()
        return function()
            local xs = it()
            if not xs then return end
            return unpack(xs)
        end
    end

    function arr.foreachi(fn)
        for it in arr.iter_raw() do
            fn(unpack(it))
        end
    end

    function arr.foreach(fn)
        for it in arr.iter_raw() do
            fn(it[#it])
        end
    end

    -- TODO: clean up the following code
    local arrstr = sprintf("array(%s):%s", shape_key(shape), string_sub(tostring(arr), 10))
    local mt = {
        __metatable = "< sprawl array >",
        __tostring = function() return arrstr end,
    }
    setmetatable(arr, mt)

    arr.get = generate_access(arr, index, data, "get", "return data[1 + index(...)]")
    arr.set = generate_access(arr, index, data, "set", "data[1 + index(...)] = select(nargs, ...)")

    function mt.__newindex() error("access violation") end
    
    local arr_get = arr.get
    function mt.__call(_, ...) return arr_get(...) end

    return arr
end


return setmetatable({
    array        = array,
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
    __newindex  = function() error("access violation") end,
    __tostring  = function() return "sprawl.lua" end,
    __call      = function(_, ...) return array(...) end
})