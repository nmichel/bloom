return {
	"Coroutine",
	{bloom.Object},
	{
		__init__ =
			function(self)
                self.co = coroutine.create(function (...) self:run() end)
			end,

        resume = 
            function(self, ...)
                return coroutine.resume(self.co, unpack(arg))
            end,
    
        yield = 
            function (self, ...)
                return coroutine.yield(unpack(arg))
            end,
            
		run =
			function(self, ...)
			end
	}
}
