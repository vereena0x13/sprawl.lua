local assert            = require "luassert"

local pairs             = pairs
local table_getn        = table.getn


local function copy_into(dst, src)
    for k, v in pairs(src) do dst[k] = v end
end


local function copy(...)
    local r = {}
    local xs = {...}
    for i = 1, table_getn(xs) do
        local x = xs[i]
        if x ~= nil then
            copy_into(r, x)
        end
    end
    return r
end


describe("sprawl.lua array", function()
    local array

    setup(function() array = require "sprawl" end)
    teardown(function() array = nil end)

    describe("constructor", function()
        it("disallows 0D arrays", function()
            assert.has_error(function()
                array()
            end, "arrays must be at least 1-dimensional")
            
            assert.has_error(function()
                array{}
            end, "arrays must be at least 1-dimensional")
        end)

        it("errors on non-integer dimensions", function()
            assert.has_error(function()
                array("2")
            end, "expected integer, got string")

            assert.has_error(function()
                array(3.14)
            end, "expected integer, got 3.14")
        end)

        it("errors on dimensions < 0", function()
            assert.has_error(function()
                array(-2)
            end, "array dimensions must be > 0, got -2 for dimension #1")
        end)
    end)

    describe("properties", function()
        local shape = {3, 5, 2}
        local arr = array(unpack(shape))

        it("shape", function()
            assert.equal(#shape, #arr.shape)
            for i = 1, #shape do assert.equal(shape[i], arr.shape[i]) end
        end)

        it("dims", function()
            assert.equal(arr.dims, 3)
        end)

        it("size", function()
            assert.equal(3 * 5 * 2, arr.size)            
        end)
    end)

    describe("index", function()
        describe("1D", function()
            it("works", function()
                local N = 3
                local arr = array(N)
                for i = 0, N-1 do assert.equal(i, arr.index(i)) end
            end)
        end)

        describe("2D", function()
            it("works", function()
                local arr = array(2, 2)
                assert.equal(0, arr.index(0, 0))
                assert.equal(1, arr.index(1, 0))
                assert.equal(2, arr.index(0, 1))
                assert.equal(3, arr.index(1, 1))
            end)
        end)

        describe("3D", function()
            it("works", function()
                local arr = array(2, 2, 2)
                assert.equal(0, arr.index(0, 0, 0))
                assert.equal(1, arr.index(1, 0, 0))
                assert.equal(2, arr.index(0, 1, 0))
                assert.equal(3, arr.index(1, 1, 0))
                assert.equal(4, arr.index(0, 0, 1))
                assert.equal(5, arr.index(1, 0, 1))
                assert.equal(6, arr.index(0, 1, 1))
                assert.equal(7, arr.index(1, 1, 1))
            end)
        end)

        describe("bounds checks", function()
            it("work", function()
                local shape = {3, 5, 2}
                local arr = array(shape)

                local function check(i, v, e)
                    assert.has_error(function()
                        local is = {}
                        for i = 1, arr.dims do is[#is + 1] = 0 end
                        is[i] = v
                        arr.index(unpack(is))
                    end, e)
                end

                for i = 1, arr.dims do
                    check(i, -1, string.format("index %d out of bounds: -1, expected 0 to %d", i, shape[i] - 1))
                    check(i, shape[i], string.format("index %d out of bounds: %d, expected 0 to %d", i, shape[i], shape[i] - 1))
                end
            end)
        end)
    end)

    describe("set and get", function()
        it("work", function()
            local shape = {3, 5, 2}
            local arr = array(shape)
            
            local i = 42
            for z = 0, shape[3]-1 do
                for y = 0, shape[2]-1 do
                    for x = 0, shape[1]-1 do
                        assert.equal(nil, arr.get(x, y, z))
                        arr.set(x, y, z, i)
                        assert.equal(i, arr.get(x, y, z))
                        assert.equal(i, arr(x, y, z))
                        i = i + 1
                    end
                end
            end
        end)
    end)

    describe("iter", function()
        it("works", function()
            local shape = {3, 4, 2}
            local arr = array(shape)
            local Q = -41246
            
            local q = Q
            for it in arr.iter_raw() do
                local i = copy(it)
                i[#i + 1] = q
                arr.set(unpack(i))
                q = q * 2
            end

            q = Q
            for z = 0, shape[3]-1 do
                for y = 0, shape[2]-1 do
                    for x = 0, shape[1]-1 do
                        assert.equal(q, arr(x, y, z))
                        q = q * 2
                    end
                end
            end
            
            q = Q
            for i, j, k, v in arr.iter() do
                assert.equal(q, v)
                q = q * 2
            end
        end)
    end)

    describe("foreachi", function()
        it("works", function()
            local arr = array(2, 2, 2)

            local i = 0
            arr.foreachi(function(x, y, z, _)
                arr.set(x, y, z, i)
                i = i + 1
            end)

            assert.equal(0, arr.get(0, 0, 0))
            assert.equal(1, arr.get(1, 0, 0))
            assert.equal(2, arr.get(0, 1, 0))
            assert.equal(3, arr.get(1, 1, 0))
            assert.equal(4, arr.get(0, 0, 1))
            assert.equal(5, arr.get(1, 0, 1))
            assert.equal(6, arr.get(0, 1, 1))
            assert.equal(7, arr.get(1, 1, 1))

            i = 0
            arr.foreachi(function(x, y, z, v)
                assert.equal(arr.get(x, y, z), v)
                i = i + 1
            end)
        end)
    end)

    describe("foreachi", function()
        it("works", function()
            local arr = array(2, 2)

            local i = 1
            arr.foreachi(function(x, y, _)
                arr.set(x, y, i)
                i = i + 1
            end)

            assert.equal(1, arr.get(0, 0))
            assert.equal(2, arr.get(1, 0))
            assert.equal(3, arr.get(0, 1))
            assert.equal(4, arr.get(1, 1))

            local xs = {}
            arr.foreach(function(v) xs[v] = true end)

            assert.equal(arr.size, #xs) 
            for i = 1, arr.size do assert(xs[i]) end
        end)
    end)
end)