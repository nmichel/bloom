package.path = package.path .. ";../?.lua"

require("bloom")

local HelloWorld = bloom.MetaClass:makeClass("HelloWorld", {bloom.Object},
	{
		__init__ =
			function(self, who)
				self.who = who
			end,
		
		salute =
			function(self)
				return tostring(self.who) .. " says \"Hello world!\""
			end
	})


local helloWorld = HelloWorld:instanciate("Donald")
local salute = helloWorld:salute()
print(salute)
