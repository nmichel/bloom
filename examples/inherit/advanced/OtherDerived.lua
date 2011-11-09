return {
    "OtherDerived",
    {inherit.advanced.Base},
    {
        __init__ =
            function(self, ...)
            end,

        myType = 
            function (self)
                return "OtherDerived"
            end,
            
        bar = 
            function (self)
                return "bar"
            end
    }
}
