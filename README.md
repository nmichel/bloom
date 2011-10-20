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

_bloom_ is lot of FUN, in writing it, in playing with it ... in applying it to real world telecommunication software.
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

<pre></code>require(bloom)
bloom.loadClass("HelloWorld")

local helloWorld = HelloWorld:instanciate("Donald")
local salute = helloWorld:salute()
print(salute)
</code></pre>

## To Be Continued ...
* Class definition
* Inheritance 
* Methods overriding and invoking base class method (with self:super()()) 
* Inspection
* MetaClass and MetaClass specialization
* More examples
