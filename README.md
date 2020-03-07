# lua-wGeometry
wGeometry - Warcraft 3 Geometry module

### Copy code from /src and use wGeometry global

### *OR* use [WLPM](https://github.com/Indaxia/wc3-wlpm-module-manager) and import("wGeometry")
```
wlpm install https://github.com/Indaxia/lua-wGeometry
```

## Usage

```lua
  local Vector3 = wGeometry.Vector3
  local Matrix3 = wGeometry.Matrix3
  local Matrix4 = wGeometry.Matrix4
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
  
  
  local m3 = a = Matrix4:new(
    0.5, 1., 0.5, 
    0.8, 0.2, 0.7, 
    0.9, 1., 0.
  )
  print(m4)
  
  
  local cam = Camera:new()
  local win = Vector3:new(0.5, 0.5, 1)
  local world = cam:windowToWorld(win)
  local win2 = cam:worldToWindow(world)
  cam:applyCameraToPlayer(Player(0))
```

See the [source file](/src/wGeometry.lua) for full functions documentation.
