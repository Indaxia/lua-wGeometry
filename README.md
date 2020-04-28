# lua wGeometry
Geometry library implemented on Lua in OOP format.
From tasty:

- **Functions** - auxiliary functions such as cropping and calculating different types of interpolations
- **Vector3** - 3D vector class with overloaded math operators, support for 3D conversion from game structures and vice versa, interpolations, applications of spherical offsets, checks for being in a sphere and a box, matrix transformations and more
- **Matrix3** - a 3x3 matrix class with many different constructors such as rotation axes and a multiplication operator
- **Matrix4** is a 4x4 matrix class, it is the simplest one - with comparison and multiplication operators
- **Box** - a class for working with cuboids, containing methods for obtaining volume, expansion, inclusion, intersection with other shapes, etc.
- **Sphere** - a class for working with spheres, containing methods for obtaining volume, inclusion, intersection with other figures, etc.
- **Ray** - a class for working with rays and getting intersection points with objects
- **Camera** - a class for storing data about the camera and the ability to convert window coordinates and scene coordinates between themselves

+ **toGrid** methods for building shapes from a vertex grid
It can work in the mode of a normal object or in the WLPM mode of a module (it is determined automatically).

### Copy code from [/src](/src) and use wGeometry global

### *OR* use [WLPM](https://github.com/Indaxia/wc3-wlpm-module-manager) and import("wGeometry")
```
wlpm install https://github.com/Indaxia/lua-wGeometry
```

## Usage

```lua
  local Vector3 = wGeometry.Vector3
  local Matrix3 = wGeometry.Matrix3
  local Matrix4 = wGeometry.Matrix4
  local Box = wGeometry.Box 
  local Sphere = wGeometry.Sphere 
  local Ray = wGeometry.Ray
  local Camera = wGeometry.Camera
  
  local a = Vector3:new(1, -1, 1.1)
  local b = Vector3:new(-1, 1, -1.1)
  print(a + b)
  
  local c = Vector3:copyFromUnit(udg_unit1)
  local d = Vector3:copyFromUnit(udg_unit1)
  
  c:hermite(d, 0.5):applyToUnit(udg_unit1)
  
  
  local m1 = Matrix3:new(
    0.5, 1., 0.5, 
    0.8, 0.2, 0.7, 
    0.9, 1., 0.
  )
  local m2 = Matrix3:newIdentity()
  print(m1 * m2)
  
  
  local m3 = Matrix4:new(
    0.5, 1., 0.5, 
    0.8, 0.2, 0.7, 
    0.9, 1., 0.
  )
  print(m4)

  local b = Box:new(
    Vector3:new(2,2,2),
    Vector3:new(4,6,3)
  )
  print b.containsVector(a)
  
  local s = Sphere:new(Vector3:new(2,2,2), 100)
  local r = Ray:new(Vector3:new(2,2,2), Vector3:new(0.3,0.3,0.4))
  print (r.intersectsSphere(s))
  
  local cam = Camera:new()
  local win = Vector3:new(0.5, 0.5, 1)
  local world = cam:windowToWorld(win)
  local win2 = cam:worldToWindow(world)
  cam:applyCameraToPlayer(Player(0))
```

See the [source file](/src/wGeometry.lua) for full functions documentation.

[See on XGM/Russian](https://xgm.guru/p/wc3/lua-wgeometry)
