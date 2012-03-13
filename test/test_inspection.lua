package.path = package.path .. ";../?.lua"

require("bloom")

log = (arg[1] == "verbose") and print or function (...) end

function dt(t, out)
	for k, v in pairs(t) do
		(out or print)(k,v) 
	end
end


--[[
	Assertions on core classes
--]]

assert(bloom.Object:getName() == "Object")
assert(bloom.Object:getClass() == bloom.Class)
assert(bloom.Object:getClass():getClass() == bloom.Class)
assert(bloom.Object:getClass():getClass():getClass() == bloom.Class)
assert(#(bloom.Object:getSuperClasses()) == 0)

assert(bloom.Class:getClass() == bloom.Class)
assert(#(bloom.Class:getSuperClasses()) == 1)
assert((bloom.Class:getSuperClasses())[1] == bloom.Object)

assert(bloom.MetaClass:getName() == "MetaClass")
assert(bloom.MetaClass:getClass() == bloom.MetaClass)
assert(bloom.MetaClass:getClass():getName() == "MetaClass")
assert(#(bloom.MetaClass:getClass():getSuperClasses()) == 1)
assert((bloom.MetaClass:getClass():getSuperClasses())[1] == bloom.Object)
assert(bloom.MetaClass:getClass() == bloom.MetaClass.__class__)

--[[
	Assertions on user defined classes and objects
--]]

Test = bloom.MetaClass:makeClass(
	"Test",
	{bloom.Object},
	{
		__init__ =
			function (self)
			end
	})

assert(Test:getClass() == bloom.Class)

test = Test:instanciate()
assert(test:getClass() == Test)
assert(test:getClass():getClass() == bloom.Class)

--[[
	Assertions on user defined metaclasses
--]]

MyMetaClass = bloom.MetaClass:makeClass(
	"CountingMetaClass",
	{bloom.MetaClass},
	{
		__init__ =
			function(self)
				self.count = 0
			end,
			
		findMethodInBases =
			function(self, what, out)
				log("* CountingMetaClass.findMethodInBases for [" .. what:getName() .. "]", out)
				self.count = self.count + 1
				return self:super(bloom.MetaClass)(what, out)
			end,

		getCount =
			function (self)
				return self.count
			end,

		resetCount =
			function (self)
				self.count = 0
			end
	}
)

myMetaClass = MyMetaClass:instanciate()

assert((myMetaClass:getClass():getSuperClasses())[1] == bloom.MetaClass)

MyTest = myMetaClass:makeClass(
	"MyTest",
	{bloom.Object},
	{
		__init__ =
			function (self)
			end,
	})
myTest = MyTest:instanciate()
assert(myMetaClass:getCount() == 1)
myMetaClass:resetCount()

myTest:getClass()
assert(myMetaClass:getCount() == 2)
myMetaClass:resetCount()

