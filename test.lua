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


local arr2 = sprawl.array(3, 4, 2)
print(arr, arr2)


for k = 0, arr2.shape[3]-1 do
    for j = 0, arr2.shape[2]-1 do
        for i = 0, arr2.shape[1]-1 do
            print(i, j, k, arr2.get(i, j, k))
        end
    end
end
