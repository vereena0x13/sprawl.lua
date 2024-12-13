--[[

local function iter()
    local x = 0
    return function()
        x = x + 1
        if x == 3 then return end
        return x, x*2, x*4, x*8
    end
end

for i, j, k, l in iter() do
    print(i, j, k, l)
end

]]

local sprawl = require "sprawl"


local arr = sprawl.array(3, 4, 2)

for i, j, k in arr.iter() do arr.set(i, j, k, i + j + k) end

for i, j, k, v in arr.iter() do
    print(i, j, k, v)
end