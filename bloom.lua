module("bloom", package.seeall)

local logger = nil

local log =
    function(...)
        if logger then
            logger(...)
        end
    end

Class = nil

MetaClass = {
    __name__ = "MetaClass",
    __methods__ = {}
}
MetaClass.__meta__ = MetaClass

MetaClass.__methods__.__init__ =
    function(self)
    end

MetaClass.__methods__.makeClass =
    function(metaClass, name, bases, methods)
        local c = {}
        c.__name__ = name
        c.__meta__ = metaClass
        c.__class__ = Class -- A class object is always an instance of class Class :)
        c.__bases__ = bases
        c.__methods__ = {}

        setmetatable(
            c,
            {
                __index =
                    function(t, k)
                        method = t.__meta__:findMethodInClass(Class, k)
                        if method ~= nil then
                            return method
                        end
                        
                        return t.__meta__:findMethodInBases(Class, k)
                    end
            })

            if methods == nil then
                return c
            end
            
            for name, func in pairs(methods) do
                if name == "__init__" then
                    local ctor =
                        function (self, ...)
                            for _, v in pairs(c.__bases__) do
                                v.__methods__.__init__(self, ...)
                            end
                            local i = func
                            func(self, ...)
                        end
                        
                    metaClass:makeMethod(c, name, ctor)                        
                else
                    metaClass:makeMethod(c, name, func)
                end
            end

        return c
    end

MetaClass.__methods__.findMethodInClass = 
    function(metaClass, clazz, name)
        return rawget(clazz.__methods__, name)
    end

MetaClass.__methods__.findBaseClass =
    --[[
    Search (breadth-first) for the first base class of a class for which call to "predicate" returns a non nil value as first result.
    Return the class AND the result of the call to predicate()
    
    Note : only 'clazz' metaclass matters to determine the way we walk through base classes. We do not recurse on calling findBaseClass()
    for each base class metaclass. The inheritance tree is considered as a single data structure the find algorithm works on. Thus, having 
    a class A with metaclass MA inheriting from class B with metaclass MB, the algorithm for finding base class of A does not depend on the
    one for class B.
    --]]
    function (metaClass, clazz, predicate)
        local stack = {}
        for _, v in pairs(clazz.__bases__) do -- [FIXME - suppose base classes are ordered as in class declaration ! Must check.]
            table.insert(stack, v)
        end
        
        idx = 1
        while idx <= #stack do
            local base = stack[idx]
            local res = {predicate(base)}
            if res[1] then
                return base, unpack(res) -- <== 
            end
            
            for _, v in pairs(base.__bases__) do -- [FIXME - suppose base classes are ordered as in class declaration ! Must check.]
                table.insert(stack, v)
            end
            
            idx = idx+1
        end

        return nil
    end

MetaClass.__methods__.findMethodInBase =
    function (metaClass, clazz, name, baseClass)
        local function predClassIs(class)
            return class == baseClass -- <== 
        end
        
        local c = metaClass:findBaseClass(clazz, predClassIs)

        return metaClass:findMethodInClass(c, name)
    end

MetaClass.__methods__.findMethodInBases =
    function (metaClass, clazz, name)
        local function predClassHasMethod(class)
            return metaClass:findMethodInClass(class, name) -- <== 
        end
        
        local c, m = metaClass:findBaseClass(clazz, predClassHasMethod)

        return m
    end
    
MetaClass.__methods__.makeBinder =
    function(metaClass, func, sup)
        --[[
        When invoked the binder modifies the "self" table to locally bind the "super" method, built in MetaClass.makeMethod. So it has
        to restore self["super"] to its previous state before returning.
        Otherwise statement like : super(Base1)() + super(Base2)() wouldn't work.
        --]]

        return
            function (self, ...)
                local oldSuper = self.super
                self.super = sup
                local pack = {func(self, ...)}
                self.super = oldSuper
                return unpack(pack)
            end
    end

MetaClass.__methods__.makeMethod =
    function(metaClass, clazz, name, func)
        --[[
        Inside the body of a method, the call self:super([BaseClass]) return a closure, which when called, invoke 
        a base version of the method, with "self" bound. This is why "self" is not repeated in the parameter list
        of the call to the that closure. e.g. self:super()(p1, p2) -- NOT self:super()(self, p1, p2)
        --]]

        local __super =
            --[[
            [FIXME - Currently, no check are done to ensure baseClass *actually* is a base class of instance. Should be.]
            --]]
            function (instance, baseClass)
                if baseClass == nil then
                    return
                        function(...)
                            local m = clazz.__meta__:findMethodInBases(clazz, name)
                            return m(instance, ...)
                        end
                else
                    return
                        function(...)
                            local m = clazz.__meta__:findMethodInBase(clazz, name, baseClass)
                            return m(instance, ...)
                        end
                end
            end

        -- [FIXME - Propagate "clazz" and "name" to makeBinder]
        clazz.__methods__[name] = metaClass:makeBinder(func, __super)
    end

--[[
    bloom.MetaClass is itself a very class, but a special one. Lookup for method is done
    - FIRST in table __methods__ (avoiding endless loop when a class requires a metaclass method), and if not found
    - then using the regular lookup mechanism (allowing MetaClass inspection) through class Class.
--]]
setmetatable(
    MetaClass,
    {
        __index =
            function(t, k)
                local method = t.__methods__[k]
                if method == nil then
                    method = Class[k]
                end
                return method
            end
    })
    
Object = MetaClass:makeClass("Object", {},
    {
        __init__ = 
            function (self)
            end,

        getClass =
            function (self)
                return self.__class__
            end
    })

Class = MetaClass:makeClass("Class", {Object},
    {
        getName =
            function(self)
                return self.__name__
            end,

        getLocalMethods =
            function(self)
                return self.__methods__
            end,

        getMethods =
            function(self)
                local m = {}
                
                for _, v in pairs(self:getSuperClasses()) do
                    local superClassName = v:getName()
                    local mt = v:getMethods()
                    for methodName, method in pairs(mt) do
                        m[methodName] = method
                    end
                end
                
                for methodName, method in pairs(self:getLocalMethods()) do
                    m[self:getName() .. "." .. methodName] = method
                end
                
                return m
            end,

        getSuperClasses =
            function(self)
                return self.__bases__
            end,

        instanciate = 
            function(self, ...)
                local object = {
                    __class__ = self,
                    super = 42 -- force creation of field "super" to avoid misses (see makeBinder())
                }
                
                setmetatable(
                    object,
                    {
                        __index =
                            function(t, k)
                                method = t.__class__.__meta__:findMethodInClass(t.__class__, k)
                                if method ~= nil then
                                    return method
                                end
                                
                                return t.__class__.__meta__:findMethodInBases(t.__class__, k)
                            end
                    })

                object:__init__(...)

                -- Creation of new fields outside initialization phase is forbidden
                -- 
                local metatable = getmetatable(object)
                metatable.__newindex = 
                    function(t, k, v)
                        error("Not allowed to created new field [" .. k .. "]")
                    end
                
                return object
            end
    })

-- When class definitions pointed by Object and Class are built, Class is set to nil.
-- We have to finialize by hand the setup of these classes.
-- 
Object.__class__ = Class
Class.__class__ = Class

ClassLoader = MetaClass:makeClass("ClassLoader", {bloom.Object},
    {
        __init__ =
            function(self)
                self.separator = "/"
                self.path = {"." .. self.separator} -- Looks in the working directory first [FIXME - VERY dangerous]
            end,

        setSeparator =
            function(self, separator)
                self.separator = separator
            end,
            
        addLookupPath =
            function(self, path)
                if string.sub(path, -1) ~= self.separator then
                    path = path .. self.separator
                end
                table.insert(self.path, path)
            end,
            
        loadClass = 
            --[[
            params:
                - className (bloom.String) : name of the class to load in the dotted form (com.lua.Class)
            
            return
                - the class
            --]]
            function(self, className)
                local filename = className:replace("%.", "/")
                local filenameInNativeFormat = filename:get() .. ".lua"
                for _, v in pairs(self.path) do
                    log("loading file : " .. v .. filenameInNativeFormat)
                    local chunk, err = loadfile(v .. filenameInNativeFormat)
                    if chunk ~= nil then
                        local desc = chunk()
                        local c = bloom.MetaClass:makeClass(desc[1], desc[2], desc[3])
                        return c -- <== 
                    end
                    
                    log("Failed to load file \"" .. filenameInNativeFormat .. "\" : " .. err)
                end
                
                log("File \"" .. filenameInNativeFormat .. "\" : not found")
                return nil, "failed to load file : "
            end
    })

String = bloom.MetaClass:makeClass("String", {bloom.Object},
    {
        __init__ =
            function(self, text)
                if text == nil then
                    text = ""
                end
                
                self.text = text
            end,

        get =
            function(self)
                return self.text
            end,

        split = 
            function(self, pattern)
                local res = {}
                local base = 1
                for pos, cap in string.gmatch(self.text, "()(" .. pattern .. ")") do
                    table.insert(res, String:instanciate(string.sub(self.text, base, pos-1)))
                    base = pos+string.len(cap)
                end
                table.insert(res, String:instanciate(string.sub(self.text, base)))
                
                return res
            end,
            
        replace =
            function(self, pattern, repl)
                return String:instanciate(string.gsub(self.text, pattern, repl))
            end
    })

defaultClassLoader = ClassLoader:instanciate()

local bindString =
    function(what, pathStr)
        log("binding string " .. pathStr:get())
        local splitName = pathStr:split("%.")
        local classNameIdx = #splitName
        
        local currNs = _G
        for iter = 1, classNameIdx-1, 1 do
            local rootNsName = splitName[iter]:get()
            local rootNs = currNs[rootNsName]
            if rootNs == nil then
                local newNs = {}
                currNs[rootNsName] = newNs
                log("binding " .. rootNsName)
                currNs = newNs
            else
                currNs = rootNs
            end
        end

        currNs[splitName[classNameIdx]:get()] = what
        log("binding " .. splitName[classNameIdx]:get())
    end

loadClass =
        function(className, nobind)
            local classString = bloom.String:instanciate(className)
            
            local splitName = classString:split("%.")
            -- REFAIRE cette boucle de manière simple, et pas en copier/coller tout pourri
            local currNs = _G
            for _, name in pairs(splitName) do
                log("looking for " .. name:get())
                local rootNsName = name:get()
                local rootNs = currNs[rootNsName]
                currNs = rootNs -- we must "export" the value of rootNS outside the loop !
                if rootNs == nil then
                    log("looking for " .. name:get() .. " not found !")
                    break; -- <== 
                end
            end

            if currNs ~= nil then
                assert(currNs:getClass() == bloom.Class)
                return currNs
            end

            local class, err = defaultClassLoader:loadClass(classString)
            if class == nil then
                return nil, err -- <== 
            end
            
            if not nobind then
                bindString(class, classString)
            end

            return class
        end

bind =
    function(what, fqn) 
        local classString = bloom.String:instanciate(fqn)
        bindString(what, classString)
    end

addLookupPath = 
    function (path)
        return defaultClassLoader:addLookupPath(path)
    end
    
MetaClass.__class__ = MetaClass
MetaClass.__bases__ = {Object}

setLogger =
    function(fn)
        logger = fn
    end

-- Ajouter une fonction pour positionner des paramètres de la toolkit : bloom.setOption(name, value) / bloom.setOptions(table)
-- Ajouter Class:getMetaclass() : A = B:getMetaclass():makeClass("A", {B}, ...)
-- Ajouter les attributs de classe : __static__ = function (selfClass) selfClass.staticInt = 2 ... end
-- Ajouter le contrôle de l'invocation dans la MetaClass : MetaClass.invoke, au lieu de l'appel direct à la méthode
-- Class.getMethods doit retourner une table d'objet de type Method (comme en java) et pas directement les fonctions
