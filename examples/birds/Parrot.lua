return {
	"Parrot",
	{bloom.Object},
	{
		__init__ = 
			function(self, name)
                self.name = name
			end,
			
        says = 
            function(self, what, out)
                return (out or print)(self.name .. " says " .. tostring(what or "nothing"))
            end
    }
}
