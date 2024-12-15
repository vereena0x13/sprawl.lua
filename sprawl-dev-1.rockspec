rockspec_format = "3.0"

package = "sprawl"
version = "dev-1"

source = {
    url = "git://github.com/vereena0x13/sprawl.lua.git",
    branch = "main"
}

description = {
    summary = "Multidimensional arrays",
    detailed = [[
        Just a toy project to pass the time.
    ]],
    homepage = "https://github.com/vereena0x13/sprawl.lua",
    issues_url = "https://github.com/vereena0x13/sprawl.lua/issues",
    maintainer = "vereena0x13",
    license = "MIT",
    labels = {}
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = "builtin",
    modules = {
        ["sprawl"] = "sprawl.lua"
    },
    copy_directories = {
        "spec"
    }
}

test_dependencies = {
    "busted",
    "busted-htest"
}

test = {
    type = "busted"
}