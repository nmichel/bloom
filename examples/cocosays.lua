package.path = package.path .. ";../?.lua"

require("bloom")

bloom.loadClass("birds.Parrot")

coco = birds.Parrot:instanciate("Coco")
coco:says("hello world!")
coco:says("hello world!", function(what) print("I am told to repease that: " .. what) end)
