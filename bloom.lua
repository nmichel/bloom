module("bloom", package.seeall)

Object = {}
Class = {}

MetaClass = {
	__name__ = "MetaClass",
	__bases__ = {},
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
		c.__class__ = c
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
								v.__methods__.__init__(self, unpack(arg))
							end
							local i = func
							func(self, unpack(arg))
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

MetaClass.__methods__.findMethodInBase =
	function (metaClass, clazz, name, baseClass)
		for _, v in pairs(clazz.__bases__) do
			if v == baseClass then
				local m

				m = v.__meta__:findMethodInClass(v, name)
				if m ~= nil then
					return m
				end
				m = v.__meta__:findMethodInBases(v, name) 
				if m ~= nil then
					return m
				end
			end
		end

		return nil
	end

MetaClass.__methods__.findMethodInBases =
	function (metaClass, clazz, name)
		for _, v in pairs(clazz.__bases__) do
			local m

			m = v.__meta__:findMethodInClass(v, name)
			if m ~= nil then
				return m
			end
			m = v.__meta__:findMethodInBases(v, name) 
			if m ~= nil then
				return m
			end
		end

		return nil
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
				local pack = {func(self, unpack(arg, 1, arg.n))}
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
			function (instance, baseClass)
				if baseClass == nil then
					return
						function(...)
							local m = clazz.__meta__:findMethodInBases(clazz, name)
							return m(instance, unpack(arg))
						end
				else
					return
						function(...)
							local m = clazz.__meta__:findMethodInBase(clazz, name, baseClass)
							return m(instance, unpack(arg))
						end
				end
			end

        -- [FIXME - Propagate "clazz" and "name" to makeBinder]
		clazz.__methods__[name] = metaClass:makeBinder(func, __super)
	end

MetaClass.__methods__.getName =
	function(self)
		return self.__name__
	end

MetaClass.__methods__.getMethods =
	function(self)
		local m = {}
		for methodName, method in pairs(self.__methods__) do
			m[self:getName() .. "." .. methodName] = method
		end
		return m
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
			
		getClass =
			function(self)
				return Class
			end,
			
		instanciate = 
			function(self, ...)
				local object = {
					__class__ = self,
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

				object:__init__(unpack(arg))

				return object
			end
	})

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
                    print("loading file : " .. v .. filenameInNativeFormat)
                    local chunk, err = loadfile(v .. filenameInNativeFormat)
                    if chunk ~= nil then
                        local desc = chunk()
                        local c = bloom.MetaClass:makeClass(desc[1], desc[2], desc[3])
                        return c -- <== 
                    end
                end
                
                print("File \"" .. filenameInNativeFormat .. "\" : not found")
                return nil, "failed to load file"
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
		print("binding string " .. pathStr:get())
		local splitName = pathStr:split("%.")
		local classNameIdx = #splitName
		
		local currNs = _G
		for iter = 1, classNameIdx-1, 1 do
			local rootNsName = splitName[iter]:get()
			local rootNs = currNs[rootNsName]
			if rootNs == nil then
				local newNs = {}
				currNs[rootNsName] = newNs
				print("binding " .. rootNsName)
				currNs = newNs
			else
				currNs = rootNs
			end
		end

		currNs[splitName[classNameIdx]:get()] = what
		print("binding " .. splitName[classNameIdx]:get())
	end

loadClass =
		function(className, nobind)
			local classString = bloom.String:instanciate(className)
			
			local splitName = classString:split("%.")
			-- REFAIRE cette boucle de mani�re simple, et pas en copier/coller tout pourri
			local currNs = _G
			for _, name in pairs(splitName) do
				print("looking for " .. name:get())
				local rootNsName = name:get()
				local rootNs = currNs[rootNsName]
				currNs = rootNs -- we must "export" the value of rootNS outside the loop !
				if rootNs == nil then
					print("looking for " .. name:get() .. " not found !")
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

MetaClass.__class__ = MetaClass
MetaClass.__bases__ = {Object}

MetaClass.__methods__.getClass =
    function (self)
        return MetaClass.__class__
    end


-- Les logs doivent �tre optionnels
-- Ajouter une fonction pour positionner des param�tres de la toolkit : bloom.setOption(name, value) / bloom.setOptions(table)
-- Limiter la cr�ation des attributs � la m�thode __init()__
-- Ajouter Class:getMetaclass() : A = B:getMetaclass():makeClass("A", {B}, ...)
-- Ajouter les attributs de classe : __static__ = function (selfClass) selfClass.staticInt = 2 ... end
-- Ajouter le contr�le de l'invocation dans la MetaClass : MetaClass.invoke, au lieu de l'appel direct � la m�thode
-- Class.getMethods doit retourner une table d'objet de type Method (comme en java) et pas directement les fonctions
