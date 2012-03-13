package.path = package.path .. ";../?.lua"

require("bloom")

log = (arg[1] == "verbose") and print or function (...) end

function dt(t, out)
	for k, v in pairs(t) do
		(out or print)(k,v) 
	end
end

-- Build class Parrot using MetaClass
-- 
parrotDesc =
	{
		"Parrot",
		{bloom.Object},
		{
			__init__ =
				function(self, name)
					self.name = name or "Rio"
				end,
				
			says =
				function(self, what, out)
					return (out or log)(self.name .. " says " .. tostring(what or "nothing"))
				end
		}
	}
Parrot = bloom.MetaClass:makeClass(unpack(parrotDesc))

-- Build class TalkingMetaClass using MetaClass
-- 
metaclassDesc = 
	{
		"TalkingMetaClass",
		{bloom.MetaClass},
		{
			__init__ =
				function(self)
				end,

			findMethodInBases =
				function(self, what, out)
					log("* TalkingMetaClass.findMethodInBases ", out)
					return self:super(bloom.MetaClass)(what, out)
				end
		}
	}
TalkingMetaClass = bloom.MetaClass:makeClass(unpack(metaclassDesc))

-- Instanciate a TalkingMetaClass object
-- 
tmc = TalkingMetaClass:instanciate()

-- Build class TalkingParrot using MetaClass
-- 
talkingParrotDesc =
	{
		"TalkingParrot",
		{Parrot},
		{
			__init__ =
				function(self, name)
					self.name = name or "Rio"
				end,
				
			says = 
				function(self, what, out)
					self:super()(what, out)
				end
		}
	}
TalkingParrot = tmc:makeClass(unpack(talkingParrotDesc))

-- Instanciate and use a TalkingParrot
-- 
tp = TalkingParrot:instanciate()
log(tp:says("Coco"))
