return {
    "Base",
    {bloom.Object},
    {
        __init__ =
            function(self, name)
                self.name = name or "John Doe"
            end,

        myType = 
            function (self)
                return "Base"
            end,
            
        says =
            function(self, what, out)
                return (out or print)(self.name .. " of class " .. self:myType() .. " says " .. tostring(what or "nothing"))
            end
    }
}
