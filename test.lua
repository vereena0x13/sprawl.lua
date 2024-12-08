local sprawl = require "sprawl"


local arr = sprawl.array(3, 4, 2)

for k = 0, arr.shape[3]-1 do
    for j = 0, arr.shape[2]-1 do
        for i = 0, arr.shape[1]-1 do
            arr.set(i, j, k, arr.index(i, j, k))
            print(i, j, k, arr.get(i, j, k))
        end
    end
end