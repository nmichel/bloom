package.path = package.path .. ";../?.lua"

require("bloom")

bloom.defaultClassLoader:addLookupPath("../")

bloom.loadClass("inherit.simple.Base")
bloom.loadClass("inherit.simple.Derived")

local b = inherit.simple.Base:instanciate("b")
local d = inherit.simple.Derived:instanciate("d")

local function says(who, what)
    who:says(what)
end

says(b, "Hello world!")
says(d, "Hello world!")
