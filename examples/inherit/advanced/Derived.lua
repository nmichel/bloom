return {
    "Derived",
    {inherit.advanced.Base},
    {
        __init__ =
            function(self, ...)
            end,

        myType = 
            function (self)
                return "Derived"
            end,
            
        foo = 
            function (self)
                return "foo"
            end
    }
}
