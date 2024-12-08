local assert = require "luassert"
describe("sprawl.lua array", function()
    local array

    setup(function() array = require "sprawl" end)
    teardown(function() array = nil end)

    describe("constructor", function()
        it("disallows 0D arrays", function()
            assert.has_error(function()
                array()
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

                local function mkindices()
                    local xs = {}
                    for i = 1, arr.dims do xs[#xs + 1] = 0 end
                    return xs
                end

                local function check(i, v, e)
                    assert.has_error(function()
                        local is = mkindices()
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
                        i = i + 1
                    end
                end
            end
        end)
    end)
end)