package.path = package.path .. ";../?.lua"

require("bloom")

bloom.setLogger(print)

local NoCreate = bloom.MetaClass:makeClass("NoCreate", {bloom.Object},
    {
        __init__ =
            function(self, who)
                self.who = who
            end,
        
        createField =
            function(self)
                self.who = "changed " .. self.who
                self.newfield = 42 -- NOT ALLOWED !
            end
    })


local noCreate = NoCreate:instanciate("Donald")
noCreate:createField() -- ERROR !
