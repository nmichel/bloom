package.path = package.path .. ";../?.lua"

require("bloom")

bloom.defaultClassLoader:addLookupPath("../")

bloom.loadClass("inherit.advanced.Base")
bloom.loadClass("inherit.advanced.Derived")
bloom.loadClass("inherit.advanced.OtherDerived")
bloom.loadClass("inherit.advanced.MultiDerived")

local d = inherit.advanced.Derived:instanciate("d")
local od = inherit.advanced.OtherDerived:instanciate("od")
local md = inherit.advanced.MultiDerived:instanciate("md")

print("d:foo()", pcall(d.foo, d))
print("od:foo()", pcall(od.foo, od)) -- Fail

print("d:bar()", pcall(d.bar, d)) -- Fail
print("od:bar()", pcall(od.bar, od))

print("md:bar()", pcall(md.foo, md))
print("md:foo()", pcall(md.bar, md))

local function says(who, what)
    who:says(what)
end

says(d, "Hello world!")
says(od, "Hello world!")
says(md, "Hello world!")
