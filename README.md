# BLOOM

BLOOM (for Basic Lua Object Oriented Model) is a simple OOP for Lua language.

<img src="https://github.com/downloads/nmichel/bloom/bloom-banner.png" alt="BLOOM logo" align="right" width="180" />

## Warning

Although already usable, this is work in progress, thus very likely to change, even in core features.
A LOT of things need to be done or refined.

## Motivation

_bloom_ is used to write routing algorithms for a softswitch VoIP Class 5.
Although we can do without _bloom_, it greatly helps scripters can manipulate classes and objects that represent business concepts in a classic OOP manner, as
<pre><code>object = MyClass:instanciate(initParams)
results = object:method(parameters)</tt>
</code></pre>
By providing a decent inheritance mechanism, _bloom_ also speeds up routing specialization by reducing it to inheritances and method overloading.

_bloom_ is a lot of FUN, in writing it, in playing with it ... in applying it to real world telecommunication software.
I hope you will enjoy it.

## Running examples

The sample scripts must be executed from the directory _examples/_.

    $ lua [-i] <example.lua> [args]

Use -i option to enter interactive mode after script has been processed.


## Usage

_bloom_ is a pure Lua module.
As such, all you need is to ensure <tt>bloom.lua</tt> is in your _package.path_,

    package.path = package.path .. ";/where/bloom/resides/?.lua"

then add _require(bloom)_  in your own script files.

    require("bloom")

    bloom.loadClass("birds.Parrot")


## Class lookup

The default behaviour of _bloom_ is to look for classes in the current  working directory.
If we consider the preceding code snippet, saying we are in directory _/home/nmichel/private/bloom/_ (*not* in _examples_), bloom wont't be able to load class _"birds.Parrot"_.

In such cases (as to use shared class libraries, ...) you have to add lookup paths.

    package.path = package.path .. ";/where/bloom/resides/?.lua"
    require("bloom")

    bloom.addLookupPath("/usr/nmichel/private/bloom/examples")

    bloom.loadClass("birds.Parrot")

## Class definition

### Explicit declaration

<pre><code>local HelloWorld = bloom.MetaClass:makeClass("HelloWorld", {bloom.Object},
{
    __init__ =
        function(self, who)
            self.who = who
        end,

     salute =
        function(self)
            return tostring(self.who) .. " says \"Hello world!\""
        end
})
        
local helloWorld = HelloWorld:instanciate("Donald")
local salute = helloWorld:salute()
print(salute)
</code></pre>

### Class Loading

Create a file <tt>HelloWorld.lua</tt> returning the definition of the _HelloWorld_ class. Class name and file name must match. 

<pre><code>return {
    "HelloWorld",
    {bloom.Object},
    {
        __init__ =
            function(self, who)
                self.who = who
            end,

        salute =
            function(self)
                return tostring(self.who) .. " says \"Hello world!\""
            end
    }
}
</code></pre>

Then use the classloading mecanism to load the _HelloWorld_ class.

<pre><code>require(bloom)
bloom.loadClass("HelloWorld")

local helloWorld = HelloWorld:instanciate("Donald")
local salute = helloWorld:salute()
print(salute)
</code></pre>

## Inheritance

A class can inherit another (or several). The former is called "derived class", while the latter 
is said to be the "base class". A derived class can redefine (or override) some methods of base classes. When a method is called on an object, the version of the method called depends on real type of the object. A overridden method can call a base class's version, with _self:super()()_.

### Simple example

Lets have a base class called ... Base, defined in inherit/simple/Base.lua
<pre><code>return {
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
</code></pre>

The method _says()_ uses method _myType()_ (amongst other details) to build a string passed to a
function (if  provided) or printed out. Note that _myType()_ doesn't use base class _Object_ to
 retrieve class name (as in _self:getClass():getName()_). This is because code is evaluated at runtime, so _self:getClass()_ will return the real class, not _Base_ as one might expect at first sight.

We define a class called _Derived_ inheriting _Base_, in file inherit/simple/Derived.lua

<pre><code>return {
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
</code></pre>

Class _Derived_ overrides method _myType()_, and uses _self:super()()_ to call _Base_'s version.

Now we can write a script which uses both classes, and calls _says()_ on a instance of each of both.

<pre><code>bloom.loadClass("inherit.simple.Base")
bloom.loadClass("inherit.simple.Derived")

local b = inherit.simple.Base:instanciate("b")
local d = inherit.simple.Derived:instanciate("d")

local function says(who, what)
    who:says(what)
end

says(b, "Hello world!")
says(d, "Hello world!")
</code></pre>

### Advanced example

Lets modify class _Derived_, to simply overrides _myType()_ and add method _foo()_.
<pre><code>        // ...
        myType = 
            function (self)
                return "Derived"
            end,

        foo = 
            function (self)
                return "foo"
            end
</code></pre>

We define class _OtherDerived_ also inheriting _Base_. _OtherDerived_ is nearly identical to _Derived_.

<pre><code>        // ...
        myType = 
            function (self)
                return "OtherDerived"
            end,

        bar = 
            function (self)
                return "bar"
            end
</code></pre>

Note that both _Derived_ and _OtherDerived_ redefine _myType()_.

Now we define class _MultiDerived_ inheriting _Derived_ and _OtherDerived_.
<pre><code>return {
    "MultiDerived",
    {inherit.advanced.Derived, inherit.advanced.OtherDerived}, -- Multiple inheritance
    {
        __init__ =
            function(self, ...)
            end,

        myType = 
            function (self)
                local res = ""
                for _, v in pairs(self:getClass():getSuperClasses()) do
                    res = res .. " " .. self:super(v)() -- Calling myType() of each base class
                end
                return "MultiDerived (" .. res .. " )"
            end
    }
}
</code></pre>

Simple isn't it ? The interesting point is how _myType()_ is redefined in _MultiDerived_. It illustrates the way you can select a base class version of an overridden method, with _self:super(<BaseClass>)(...)_.

Here follows a client script, which uses all these classes.

<pre><code>bloom.loadClass("inherit.advanced.Base")
bloom.loadClass("inherit.advanced.Derived")
bloom.loadClass("inherit.advanced.OtherDerived")
bloom.loadClass("inherit.advanced.MultiDerived")

local d = inherit.advanced.Derived:instanciate("d")
local od = inherit.advanced.OtherDerived:instanciate("od")
local md = inherit.advanced.MultiDerived:instanciate("md")

print("d:foo()", pcall(d.foo, d))
print("od:foo()", pcall(od.foo, od)) -- Fail

print("d:bar()", pcall(d.bar, d)) -- Fail
print("od:bar()", pcall(od.bar, od))

print("md:bar()", pcall(md.foo, md))
print("md:foo()", pcall(md.bar, md))

local function says(who, what)
    who:says(what)
end

says(d, "Hello world!")
says(od, "Hello world!")
says(md, "Hello world!")
</code></pre>

## To Be Continued ...
* Class definition
* Inspection
* MetaClass and MetaClass specialization
* More examples
