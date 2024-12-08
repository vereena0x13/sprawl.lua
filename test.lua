local sprawl = require "sprawl"


--[[
local arr = sprawl.array(3, 4, 2)

for k = 0, arr.shape[3]-1 do
    for j = 0, arr.shape[2]-1 do
        for i = 0, arr.shape[1]-1 do
            arr.set(i, j, k, arr.index(i, j, k))
            print(i, j, k, arr.get(i, j, k))
        end
    end
end
]]
local xs = sprawl.array(4)
xs.set(0, 1)
xs.set(1, 4)
xs.set(2, "a")
xs.set(3, {})

for i = 0, 3 do print(xs.get(i)) end