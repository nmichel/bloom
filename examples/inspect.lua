package.path = package.path .. ";../?.lua"

require("bloom")

-- Helpers
-- 
function foreach(t, fn)
    fn = fn or print
    for k, v in pairs(t) do
        fn(k, v)
    end
end

-- Get the name of class to inspect
-- 
local className =
    (function ()
        if arg[1] then
            return arg[1]
        else
            io.write("Enter name of class to be inspected > ")
            return io.input():read()
        end
    end)()

io.write("Loading class : " .. className)

-- Load the class
-- 
class = bloom.loadClass(className, true)
if not class then
    io.write("\tFAILED\n")
    return -- <== 
end
io.write("\tOK\n")

-- Inspect the class
-- 

print("Inspecting class : " .. className)

print("* Class name \t", class:getName())
io.write("* Class superclasse(s) \t")
foreach(
    class:getSuperClasses(),
    function (_, v)
        io.write(v:getName() .. " ")
    end)
io.write("\n")

print("* Class methods")
local classStack = {}
table.insert(classStack, class)
local idx = 1
while idx <= #classStack do
    local c = classStack[idx]
    io.write("  * From " .. c:getName() .. "\t")
    foreach(
        c:getLocalMethods(),
        function (k, _)
            io.write(k .. " ")
        end)
    io.write("\n")
    foreach(
        c:getSuperClasses(),
        function(_, v)
            table.insert(classStack, v)
        end)
    idx = idx + 1
end
