return {
    "Derived",
    {inherit.simple.Base},
    {
        __init__ =
            function(self, ...)
            end,

        myType = 
            function (self)
                return "Derived (derived from " .. self:super()().. ")" -- Note call to base class version of myType() using self:super()()
            end
    }
}
