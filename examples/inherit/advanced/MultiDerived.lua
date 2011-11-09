return {
    "MultiDerived",
    {inherit.advanced.Derived, inherit.advanced.OtherDerived},
    {
        __init__ =
            function(self, ...)
            end,

        myType = 
            function (self)
                local res = ""
                for _, v in pairs(self:getClass():getSuperClasses()) do
                    res = res .. " " .. self:super(v)() -- Calling myType() for each base class
                end
                return "MultiDerived (" .. res .. " )"
            end,
            
        bar =
            function (self)
                return self:super()()
            end
    }
}
