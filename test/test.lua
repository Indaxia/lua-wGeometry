
wGeometryTest = Imp.export("wGeometryTest", function()
  local wGeometry = Imp.import(wGeometry)
  local Vector3 = wGeometry.Vector3
  local Matrix3 = wGeometry.Matrix3
  local Matrix4 = wGeometry.Matrix4
  local Camera = wGeometry.Camera
  
  print("Vector 3 Test")
  local a = Vector3:new(1., -1., 1.1)
  local b = Vector3:new(-1., 1., -1.1)
  print("Let a =", a)
  print("Let b =", b)
  print("Let c =", c)
  print("a == b =", a == b)
  print("a + b =", a + b)
  print("a - b =", a - b)
  print("-a =", -a)
  print("a x b =", a * b)
  print("a . b =", a:dotProduct(b))
  print("a / 2 =", a / 2)
  print("a length =", a:length())
  print("a squared length =", a:lengthSquared())
  print("a normalize =", a:normalize())
  print("a scale 2 =", a:scale(2))
  print("a lerp b 0.5 =", a:lerp(b, 0.5))
  print("a hermite b 0.5 =", a:hermite(b, 0.5))
  print("a bezier (b,a) 0.5 =", a:bezier(b, a, 0.5))  
  -- print("from unit u = ", Vector3:copyFromUnit(udg_u))
  
  
  print("=============\n")
  print("Matrix 3 Test")
  a = Matrix3:new(
    0.5, 1., 0.5, 
    0.8, 0.2, 0.7, 
    0.9, 1., 0.
  )
  b = Matrix3:newIdentity()
  print("Let a =", a)
  print("Let b =", b)
  print("a * b =", a * b)
  
  
  print("=============\n")
  print("Matrix 4 Test")
  a = Matrix4:new(
    0.5, 1., 0.5, 
    0.8, 0.2, 0.7, 
    0.9, 1., 0.
  )
  b = Matrix4:newIdentity()
  print("Let a =", a)
  print("Let b =", b)
  print("a * b =", a * b)
  
  
  print("=============\n")
  print("Camera Test")
  local cam = Camera:new()
  local win = Vector3:new(0.5, 0.5, 1)
  print("Let window = ", win)
  local world = cam:windowToWorld(win)
  print("then world = ", world)
  print("to window again = ", cam:worldToWindow(world))

  return {}
end)
