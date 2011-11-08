package.path = package.path .. ";../?.lua"

require("bloom")

bloom.defaultClassLoader:addLookupPath("../")

bloom.loadClass("tools.Coroutine")

local ForLoop = bloom.MetaClass:makeClass("ForLoop", {bloom.tools.Coroutine},
    {
        __init__ =
            function(self, start, step, upper)
                self.val = start
                self.step = step
                self.upper = upper
            end,
        
        run =
            function(self)
                while self.val < self.upper do
                    self.val = self.val + self.step
                    local newVal = self:yield(self.val)
                    self.val = newVal or self.val
                end
            end
    })

local co = ForLoop:instanciate(1, 1, 100)
local cont = true
local res = 0
local update = false
while cont do
    if update then
        cont, res = co:resume(res*2)
    else
        cont, res = co:resume()
    end
    update = not update
    
    if cont then
        if res then 
            print(res)
        else
            cont = false
        end
    else
        print("Coroutine raised an error : ", res)
    end
end
