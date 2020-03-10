if(_G["WM"] == nil) then WM = (function(m,h) h(nil,(function() end), (function(e) _G[m] = e end)) end) end -- WLPM MM fallback

-- Warcraft 3 Geometry module by ScorpioT1000 / 2020
-- Thanks to DGUI by Ashujon / 2009
WM("wGeometry", function(import, export, exportDefault) 
  local Functions = nil
  local Vector3 = nil
  local Matrix3 = nil
  local Matrix4 = nil
  local Camera = nil
  local zTesterLocation = Location(0,0)
  
  local getTerrainZ = function(x,y)
    MoveLocation(zTesterLocation, x, y)
    return GetLocationZ(zTesterLocation)
  end
  
  local _GetUnitZ = function(u)
    return GetUnitFlyHeight(u) + getTerrainZ(GetUnitX(u), GetUnitY(u))
  end

  local _SetUnitZ = function(u, z)
    SetUnitFlyHeight(u, z - getTerrainZ(GetUnitX(u), GetUnitY(u)), 0)
  end
  
  local _GetItemZ = function(i)
    return getTerrainZ(GetItemX(u), GetItemY(u))
  end
  
  local _GetDestructableZ = function(d)
    return getTerrainZ(GetDestructableX(d), GetDestructableY(d))
  end
  
  -- Must be called for each non-air unit before manipulating Z coordinate
  -- @param u Unit
  local unlockUnitZ = function(u)
    UnitAddAbility(u , 'Aave')
    UnitRemoveAbility(u , 'Aave')
  end
  
  
  -- Math functions
  Functions = {
    -- 1D clamp
    clamp = function(value, _min, _max)
      if value > _max then
        value = _max
      end
      if value < _min then
        value = _min
      end
      return value
    end,
    
    -- 1D distance
    distance = function(value1, value2)
      return math.abs(value1 - value2)
    end,
    
    -- 1D linear spline interpolation between 2 points
    lerp = function(value1, value2, amount)
      return value1 + (value2 - value1) * amount
    end,
    
    -- 1D hermite spline interpolation between 2 points
    hermite = function(value1, tangent1, value2, tangent2, amount)
      local v1 = value1
      local v2 = value2
      local t1 = tangent1
      local t2 = tangent2
      local s = amount
      local result = 0.
      local sCubed = s * s * s
      local sSquared = s * s

      if (amount == 0.) then
          result = value1
      elseif (amount == 1.) then
          result = value2
      else
          result = (2 * v1 - 2 * v2 + t2 + t1) * sCubed +
              (3 * v2 - 3 * v1 - 2 * t1 - t2) * sSquared +
              t1 * s +
              v1
      end
      return result
    end,
    
    -- 1D bezier spline interpolation between 3 points
    bezier = function(p0, p1, p2, amount)
      local amountInv = 1-amount
      return amountInv*amountInv*p0 
        + 2*amount*amountInv*p1 
        + amount*amount*p2
    end
  }
  
  

  -- 3D Vector ====================
  Vector3 = {
    -- x, y, z
    
    -- Create a new vector from coords. Skip the coords to create a zero vector
    new = function(self, x, y, z)
      local o = {}
      setmetatable(o,self)
      o.x = x or 0.
      o.y = y or 0.
      o.z = z or 0.
      return o
    end,
    
    -- Copy vector from another
    copyFrom = function(self, that)
      local o = {}
      setmetatable(o,self)
      o.x = that.x
      o.y = that.y
      o.z = that.z
      return o
    end,
    
    -- Copy vector from Unit X/Y/Z
    -- @param u Unit
    copyFromUnit = function(self, u)
      local o = {}
      setmetatable(o,self)
      o.x = GetUnitX(u)
      o.y = GetUnitY(u)
      o.z = _GetUnitZ(u)
      return o
    end,
    
    -- Copy vector from Location X/Y/Z
    -- @param loc Location
    copyFromLocation = function(self, loc)
      local o = {}
      setmetatable(o,self)
      o.x = GetLocationX(loc)
      o.y = GetLocationY(loc)
      o.z = GetLocationZ(loc)
      return o
    end,
    
    -- Copy vector from Item X/Y/Z
    -- @param i Item
    copyFromItem = function(self, i)
      local o = {}
      setmetatable(o,self)
      o.x = GetItemX(i)
      o.y = GetItemY(i)
      o.z = _GetItemZ(i)
      return o
    end,
    
    -- Copy vector from Destructable X/Y/Z
    -- @param d Destructable
    copyFromDestructable = function(self, d)
      local o = {}
      setmetatable(o,self)
      o.x = GetDestructableX(d)
      o.y = GetDestructableY(d)
      o.z = _GetDestructableZ(d)
      return o
    end,
    
    -- Create a new X-oriented unit vector
    newRight = function(self)
      return Vector3:new(1.,0.,0.)
    end,
    
    -- Create a new Y-oriented unit vector
    newForward = function(self)
      return Vector3:new(0.,1.,0.)
    end,
    
    -- Create a new Z-oriented unit vector
    newUp = function(self)
      return Vector3:new(0.,0.,1.)
    end,
    
    length = function(self)
      return math.sqrt(self.x*self.x+self.y*self.y+self.z*self.z)
    end,
    
    lengthSquared = function(self)
      return self.x*self.x+self.y*self.y+self.z*self.z
    end,
    
    length2d = function(self)
      return math.sqrt(self.x*self.x+self.y*self.y)
    end,
    
    normalize = function(self)
      local len = math.sqrt(self.x*self.x+self.y*self.y+self.z*self.z)
      return Vector3:new(self.x/len, self.y/len, self.z/len)
    end,
    
    distance = function(self, that)
      return math.sqrt(
        (self.x-that.x)*(self.x-that.x) +
        (self.y-that.y)*(self.y-that.y) +
        (self.z-that.z)*(self.z-that.z)
      )
    end,
    
    distanceSquared = function(self, that)
      return 
        (self.x-that.x)*(self.x-that.x) +
        (self.y-that.y)*(self.y-that.y) +
        (self.z-that.z)*(self.z-that.z)
    end,
    
    __eq = function(self, that)
      return self.x == that.x and self.y == that.y and self.z == that.z
    end,
    
    __add = function(self, that)
      return Vector3:new(
        self.x + that.x,
        self.y + that.y,
        self.z + that.z
      )
    end,
    
    __sub = function(self, that)
      return Vector3:new(
        self.x - that.x,
        self.y - that.y,
        self.z - that.z
      )
    end,
    
    __unm = function(self, that)
      return Vector3:new(
        -self.x,
        -self.y,
        -self.z
      )
    end,
    
    -- Uses cross product (!)
    -- @see https://en.wikipedia.org/wiki/Cross_product
    __mul = function(self, that)
      return self:crossProduct(that)
    end,
    
    -- Division by a number (!)
    __div = function(self, aNumber)
      return Vector3:new(
        self.x / aNumber,
        self.y / aNumber,
        self.z / aNumber
      )
    end,
    
    -- @param that Vector3
    -- @return number
    -- @see https://en.wikipedia.org/wiki/Dot_product
    dotProduct = function(self, that)
      return self.x*that.x + self.y*that.y + self.z*that.z
    end,
    
    -- @param that Vector3
    -- @return Vector3
    -- @see https://en.wikipedia.org/wiki/Cross_product
    crossProduct = function(self, that)
      return Vector3:new(
        self.y * that.z - self.z * that.y,
        self.z * that.x - self.x * that.z,
        self.x * that.y - self.y * that.x
      )
    end,
    
    scale = function(self, aNumber)
      return Vector3:new(
        self.x * aNumber,
        self.y * aNumber,
        self.z * aNumber
      )
    end,
    
    -- Spheric coordinates offset
    -- @param distance number in game units
    -- @param yaw number (angle in radians)
    -- @param pitch number (angle in radians)
    -- @return Vector3 result point
    -- @see https://en.wikipedia.org/wiki/Aircraft_principal_axes
    yawPitchOffset = function(self, distance, yaw, pitch)
      return Vector3:new(
        distance * math.cos(yaw) * math.sin(pitch),
        distance * math.sin(yaw) * math.sin(pitch),
        distance * math.cos(pitch)
      )
    end,
    
    -- Transforms the vector by 3x3 matrix transformation components
    -- @param Matrix3 m
    -- @return Vector3
    -- @see https://en.wikipedia.org/wiki/Transformation_matrix
    transform3 = function(self, m)
      return Vector3:new(
        self.x*m.m11+self.y*m.m21+self.z*m.m31,
        self.x*m.m12+self.y*m.m22+self.z*m.m32,
        self.x*m.m13+self.y*m.m23+self.z*m.m33
      )
    end,
    
    -- Transforms the vector by 4x4 matrix transformation components
    -- @param Matrix4 m
    -- @return Vector3
    -- @see https://en.wikipedia.org/wiki/Transformation_matrix
    transform4 = function(self, m)
      local w = self.x*m.m14+self.y*m.m24+self.z*m.m34+m.m44
      return Vector3:new(
        (self.x*m.m11+self.y*m.m21+self.z*m.m31+m.m41)/w,
        (self.x*m.m12+self.y*m.m22+self.z*m.m32+m.m42)/w,
        (self.x*m.m13+self.y*m.m23+self.z*m.m33+m.m43)/w
      )
    end,
    
    -- Applies linear interpolation
    -- @param that Vector3
    -- @param amount current animation state, number between 0 and 1
    -- @return Vector3 result
    lerp = function(self, that, amount)
      return Vector3:new(
        Functions.lerp(self.x, that.x, amount),
        Functions.lerp(self.y, that.y, amount),
        Functions.lerp(self.z, that.z, amount)
      )
    end,
    
    -- Applies hermite spline interpolation
    -- @param that Vector3
    -- @param amount current animation state, number between 0 and 1  
    -- @param tangent1 (optional) 
    -- @param tangent2 (optional)
    -- @return Vector3 result
    hermite = function(self, that, amount, tangent1, tangent2)
      if(tangent1 == nil) then
        tangent1 = 0.
      end
      if(tangent2 == nil) then
        tangent2 = 0.
      end
      return Vector3:new(
        Functions.hermite(self.x, tangent1, that.x, tangent2, amount),
        Functions.hermite(self.y, tangent1, that.y, tangent2, amount),
        Functions.hermite(self.z, tangent1, that.z, tangent2, amount)
      )
    end,
    
    -- Applies bezier spline interpolation
    -- @param p2 Vector3 point 2
    -- @param p3 Vector3 point 3
    -- @param amount current animation state, number between 0 and 1
    -- @return Vector3 result
    bezier = function(self, p2, p3, amount)
      return Vector3:new(
        Functions.bezier(self.x, p2.x, p3.x, amount),
        Functions.bezier(self.y, p2.y, p3.y, amount),
        Functions.bezier(self.z, p2.z, p3.z, amount)
      )
    end,
    
    -- Checks if the point is in a sphere
    -- @param c Vector3 sphere center
    -- @param r number sphere radius
    -- @return boolean
    isInSphere = function(self, c, r)
      return self:distanceSquared(c) < (r*r)
    end,
    
    -- Checks if the point is inside axis-aligned bounding box (AABB)
    -- @param vMin
    -- @param vMax
    -- @return boolean
    isInAABB = function(self, vMin, vMax)
      return (self.x >= vMin.x and self.x <= vMax.x) and
             (self.y >= vMin.y and self.y <= vMax.y) and
             (self.z >= vMin.z and self.z <= vMax.z)
    end,
    
    applyToLocation = function(self, loc)
      MoveLocation(loc, self.x, self.y)
    end,
    
    applyToUnit = function(self, u)
      SetUnitX(u, self,x)
      SetUnitY(u, self.y)
      _SetUnitZ(u, self.z)
    end,
    
    __tostring = function(self)
      return "{ " .. tostring(self.x) .. ", " .. tostring(self.y) .. ", " .. tostring(self.z) .. " }"
    end,
  }
  Vector3.__index = Vector3
  
  
  
  
  -- 3x3 Matrix ====================
  Matrix3 = {
    -- m11, m12, m13
    -- m21, m22, m23
    -- m31, m32, m33
    
    -- Create a new matrix from coords. Skip coords to create a zero matrix
    -- @return Matrix3
    new = function(self, m11, m12, m13, m21, m22, m23, m31, m32, m33)
      local o = {}
      setmetatable(o,self)
      o.m11 = m11 or 0.
      o.m12 = m12 or 0.
      o.m13 = m13 or 0.
      o.m21 = m21 or 0.
      o.m22 = m22 or 0.
      o.m23 = m23 or 0.
      o.m31 = m31 or 0.
      o.m32 = m32 or 0.
      o.m33 = m33 or 0.
      return o
    end,
    
    -- Copy matrix from another
    -- @return Matrix3
    copyFrom = function(self, that)
      local o = {}
      setmetatable(o,self)
      o.m11 = that.m11
      o.m12 = that.m12
      o.m13 = that.m13
      o.m21 = that.m21
      o.m22 = that.m22
      o.m23 = that.m23
      o.m31 = that.m31
      o.m32 = that.m32
      o.m33 = that.m33
      return o
    end,
    
    -- Create a new identity matrix
    -- @return Matrix3
    newIdentity = function(self)
      local o = {}
      setmetatable(o,self)
      o.m11 = 1.
      o.m12 = 0.
      o.m13 = 0.
      o.m21 = 0.
      o.m22 = 1.
      o.m23 = 0.
      o.m31 = 0.
      o.m32 = 0.
      o.m33 = 1.
      return o
    end,
    
    -- Create a new scaling matrix
    -- @return Matrix3
    newScaling = function(self, scaleX, scaleY, scaleZ)
      local o = {}
      setmetatable(o,self)
      o.m11 = scaleX or 1.
      o.m12 = 0.
      o.m13 = 0.
      o.m21 = 0.
      o.m22 = scaleY or 1.
      o.m23 = 0.
      o.m31 = 0.
      o.m32 = 0.
      o.m33 = scaleZ or 1.
      return o
    end,
    
    -- Create a new scaling matrix
    -- @return Matrix3
    -- @see https://en.wikipedia.org/wiki/Scaling_(geometry)
    newScaling = function(self, scaleX, scaleY, scaleZ)
      return Matrix3:new(
        scaleX or 1., 0., 0.,
        0., scaleY or 1., 0.,
        0., 0., scaleZ or 1.
      )
    end,
    
    -- Create a new rotation X matrix from the angle (in radians)
    -- @return Matrix3
    -- @see https://en.wikipedia.org/wiki/Rotation_matrix
    newRotationX = function(self, a)
      return Matrix3:new(
        1., 0., 0.,
        0., math.cos(a), -math.sin(a),
        0., math.sin(a), math.cos(a)
      )
    end,
    
    -- Create a new rotation Y matrix from the angle (in radians)
    -- @return Matrix3
    -- @see https://en.wikipedia.org/wiki/Rotation_matrix
    newRotationY = function(self, a)
      return Matrix3:new(
        math.cos(a), 0., math.sin(a),
        0., 1., 0.,
        -math.sin(a), 0., math.cos(a)
      )
    end,
    
    -- Create a new rotation Z matrix from the angle (in radians)
    -- @return Matrix3
    -- @see https://en.wikipedia.org/wiki/Rotation_matrix
    newRotationZ = function(self, a)
      return Matrix3:new(
        math.cos(a), -math.sin(a), 0.,
        math.sin(a), math.cos(a), 0.,
        0., 0., 1.
      )
    end,
    
    -- Create a new axis rotation matrix from the vector and angle (in radians)
    -- @param v Vector3
    -- @param a number
    -- @return Matrix3
    -- @see https://en.wikipedia.org/wiki/Axis%E2%80%93angle_representation
    newRotationAxis = function(self, v, a)
      local cosa = math.cos(a)
      local sina = math.sin(a)
      return Matrix3:new(
        cosa+(1.-cosa)*v.x*v.x,
        (1.-cosa)*v.x*v.y-sina*v.z,
        (1.-cosa)*v.x*v.z+sina*v.y,
        
        (1.-cosa)*v.y*v.x+sina*v.z,
        cosa+(1.-cosa)*v.y*v.y,
        (1.-cosa)*v.y*v.z-sina*v.x,
        
        (1.-cosa)*v.z*v.x-sina*v.y,
        (1.-cosa)*v.z*v.y+sina*v.x,
        cosa+(1.-cosa)*v.z*v.z
      )
    end,
    
    -- Create a new rotation matrix from the yaw-pitch-roll vector
    -- @param v Vector3 where x = yaw, y = pitch, z = roll
    -- @return Matrix3
    -- @see https://en.wikipedia.org/wiki/Aircraft_principal_axes
    newRotationYawPitchRoll = function(self, v)
      local cosa = math.cos(v.x)
      local sina = math.sin(v.x)
      local cosb = math.cos(v.y)
      local sinb = math.sin(v.y)
      local cosy = math.cos(v.z)
      local siny = math.sin(v.z)
      return Matrix3:new(
        cosa*cosb,
        cosa*sinb*siny-sina*cosy,
        cosa*sinb*cosy+sina*siny,
        
        sina*cosb,
        sina*sinb*siny+cosa*cosy,
        sina*sinb*cosy-cosa*siny,
        
        -sinb,
        cosb*siny,
        cosb*cosy
      )
    end,
    
    __eq = function(self, that)
      return self.m11 == that.m11 and self.m12 == that.m12 and self.m13 == that.m13
         and self.m21 == that.m21 and self.m22 == that.m22 and self.m23 == that.m23
         and self.m31 == that.m31 and self.m32 == that.m32 and self.m33 == that.m33
    end,
    
    -- Matrix multiplication
    __mul = function(self, that)
      return Matrix3:new(
        self.m11*that.m11+self.m21*that.m12+self.m31*that.m13,
        self.m12*that.m11+self.m22*that.m12+self.m32*that.m13,
        self.m13*that.m11+self.m23*that.m12+self.m33*that.m13,
        
        self.m11*that.m21+self.m21*that.m22+self.m31*that.m23,
        self.m12*that.m21+self.m22*that.m22+self.m32*that.m23,
        self.m13*that.m21+self.m23*that.m22+self.m33*that.m23,
        
        self.m11*that.m31+self.m21*that.m32+self.m31*that.m33,
        self.m12*that.m31+self.m22*that.m32+self.m32*that.m33,
        self.m13*that.m31+self.m23*that.m32+self.m33*that.m33
      )
    end,
    
    __tostring = function(self)
      return "{ \n  " .. tostring(self.m11) .. ", " .. tostring(self.m12) .. ", " .. tostring(self.m13) .. "\n"
        .. "  " .. tostring(self.m21) .. ", " .. tostring(self.m22) .. ", " .. tostring(self.m23) .. "\n" 
        .. "  " .. tostring(self.m31) .. ", " .. tostring(self.m32) .. ", " .. tostring(self.m33) .. "\n}"
    end,
  }
  Matrix3.__index = Matrix3
  
  
  
  
  -- 4x4 Matrix ====================
  Matrix4 = {
    -- m11, m12, m13, m14
    -- m21, m22, m23, m24
    -- m31, m32, m33, m34
    -- m41, m42, m43, m44
    
    -- Create a new matrix from coords. Skip coords to create a zero matrix
    -- @return Matrix4
    new = function(self, 
      m11, m12, m13, m14, 
      m21, m22, m23, m24, 
      m31, m32, m33, m34, 
      m41, m42, m43, m44
    )
      local o = {}
      setmetatable(o,self)
      o.m11 = m11 or 0.
      o.m12 = m12 or 0.
      o.m13 = m13 or 0.
      o.m14 = m14 or 0.
      o.m21 = m21 or 0.
      o.m22 = m22 or 0.
      o.m23 = m23 or 0.
      o.m24 = m24 or 0.
      o.m31 = m31 or 0.
      o.m32 = m32 or 0.
      o.m33 = m33 or 0.
      o.m34 = m34 or 0.
      o.m41 = m41 or 0.
      o.m42 = m42 or 0.
      o.m43 = m43 or 0.
      o.m44 = m44 or 0.
      return o
    end,
    
    -- Copy matrix from another 4x4 matrix
    -- @param Matrix4 that
    -- @return Matrix4
    copyFrom = function(self, that)
      local o = {}
      setmetatable(o,self)
      o.m11 = that.m11
      o.m12 = that.m12
      o.m13 = that.m13
      o.m14 = that.m14
      o.m21 = that.m21
      o.m22 = that.m22
      o.m23 = that.m23
      o.m24 = that.m24
      o.m31 = that.m31
      o.m32 = that.m32
      o.m33 = that.m33
      o.m34 = that.m34
      o.m41 = that.m41
      o.m42 = that.m42
      o.m43 = that.m43
      o.m44 = that.m44
      return o
    end,
    
    -- Creates a 4x4 matrix from 3x3 matrix
    -- @param Matrix3 that
    -- @return Matrix4
    copyFrom3 = function(self, that)
      local o = {}
      setmetatable(o,self)
      o.m11 = that.m11
      o.m12 = that.m12
      o.m13 = that.m13
      o.m14 = 0.
      o.m21 = that.m21
      o.m22 = that.m22
      o.m23 = that.m23
      o.m24 = 0.
      o.m31 = that.m31
      o.m32 = that.m32
      o.m33 = that.m33
      o.m34 = 0.
      o.m41 = 0.
      o.m42 = 0.
      o.m43 = 0.
      o.m44 = 1.
      return o
    end,
    
    -- Create a new identity matrix
    -- @return Matrix4
    newIdentity = function(self)
      local o = {}
      setmetatable(o,self)
      o.m11 = 1.
      o.m12 = 0.
      o.m13 = 0.
      o.m14 = 0.
      o.m21 = 0.
      o.m22 = 1.
      o.m23 = 0.
      o.m24 = 0.
      o.m31 = 0.
      o.m32 = 0.
      o.m33 = 1.
      o.m34 = 0.
      o.m41 = 0.
      o.m42 = 0.
      o.m43 = 0.
      o.m44 = 1.
      return o
    end,
    
    
    __eq = function(self, that)
      return self.m11 == that.m11 and self.m12 == that.m12 and self.m13 == that.m13 and self.m14 == that.m14
         and self.m21 == that.m21 and self.m22 == that.m22 and self.m23 == that.m23 and self.m24 == that.m24
         and self.m31 == that.m31 and self.m32 == that.m32 and self.m33 == that.m33 and self.m34 == that.m34
         and self.m41 == that.m41 and self.m42 == that.m42 and self.m43 == that.m43 and self.m44 == that.m44
    end,
    
    -- Matrix multiplication
    __mul = function(self, that)
      return Matrix4:new(
        self.m11*that.m11+self.m21*that.m12+self.m31*that.m13+self.m41*that.m14,
        self.m12*that.m11+self.m22*that.m12+self.m32*that.m13+self.m42*that.m14,
        self.m13*that.m11+self.m23*that.m12+self.m33*that.m13+self.m43*that.m14,
        self.m14*that.m11+self.m24*that.m12+self.m34*that.m13+self.m44*that.m14,
        
        self.m11*that.m21+self.m21*that.m22+self.m31*that.m23+self.m41*that.m24,
        self.m12*that.m21+self.m22*that.m22+self.m32*that.m23+self.m42*that.m24,
        self.m13*that.m21+self.m23*that.m22+self.m33*that.m23+self.m43*that.m24,
        self.m14*that.m21+self.m24*that.m22+self.m34*that.m23+self.m44*that.m24,
        
        self.m11*that.m31+self.m21*that.m32+self.m31*that.m33+self.m41*that.m34,
        self.m12*that.m31+self.m22*that.m32+self.m32*that.m33+self.m42*that.m34,
        self.m13*that.m31+self.m23*that.m32+self.m33*that.m33+self.m43*that.m34,
        self.m14*that.m31+self.m24*that.m32+self.m34*that.m33+self.m44*that.m34,
        
        self.m11*that.m41+self.m21*that.m42+self.m31*that.m43+self.m41*that.m44,
        self.m12*that.m41+self.m22*that.m42+self.m32*that.m43+self.m42*that.m44,
        self.m13*that.m41+self.m23*that.m42+self.m33*that.m43+self.m43*that.m44,
        self.m14*that.m41+self.m24*that.m42+self.m34*that.m43+self.m44*that.m44
      )
    end,
    
    __tostring = function(self)
      return "{ \n  "..tostring(self.m11)..", "..tostring(self.m12)..", "..tostring(self.m13)..", "..tostring(self.m14).."\n"
        .."  "..tostring(self.m21)..", "..tostring(self.m22)..", "..tostring(self.m23)..", "..tostring(self.m24).."\n"
        .."  "..tostring(self.m31)..", "..tostring(self.m32)..", "..tostring(self.m33)..", "..tostring(self.m34).."\n"
        .."  "..tostring(self.m41)..", "..tostring(self.m42)..", "..tostring(self.m43)..", "..tostring(self.m44).."\n}"
    end,
  }
  Matrix4.__index = Matrix4
  
  
  
  
  -- Projections ====================
  -- Screen aspect ratio
  local screenWidth = 0.544
  local screenHeight = 0.302
  local radToDeg = 180.0 / math.pi
  local degToRad = math.pi / 180.0
  
  -- Builds a perspective projection matrix based on a field of view.
  -- @return Matrix4
  -- @see https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dxmatrixperspectivefovlh
  local matrix4perspective1 = function(fovy, Aspect, zn, zf)
    return Matrix4:new(2*zn/fovy,0,0,0,0,2*zn/Aspect,0,0,0,0,zf/(zf-zn),1,0,0,zn*zf/(zn-zf),0)
  end
  
  -- Builds a customized perspective projection matrix
  -- @return Matrix4
  -- @see https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dxmatrixperspectiveoffcenterlh
  local matrix4Perspective2 = function(n, f, r, l, t, b)
    return Matrix4:new(2*n/(r-l), 0, (r+l)/(r-l), 0, 0, 2*n/(t-b), (t+b)/(t-b), 0, 0, 0, -(f+n)/(f-n), -2*f*n/(f-n), 0, 0, -1, 0)
  end
  
  -- Builds a look-at matrix
  -- @param PosCamera Vector3 
  -- @param AxisX Vector3
  -- @param AxisY Vector3
  -- @param AxisZ Vector3
  -- @return Matrix4
  -- @see https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dxmatrixlookatlh
  local matrix4Look = function(PosCamera, AxisX, AxisY, AxisZ)
    return Matrix4:new(AxisX.x,AxisY.x,AxisZ.x,0,AxisX.y,AxisY.y,AxisZ.y,0,AxisX.z,AxisY.z,AxisZ.z,0,-AxisX:dotProduct(PosCamera),-AxisY:dotProduct(PosCamera),-AxisZ:dotProduct(PosCamera),1)
  end
  
  
  
  -- Camera ====================
  -- Game camera projection state with eye and target
  -- @see https://knowledge.autodesk.com/support/3ds-max/learn-explore/caas/CloudHelp/cloudhelp/2017/ENU/3DSMax/files/GUID-B1F4F126-65AC-4CB6-BDC3-02799A0BAEF3-htm.html
  Camera = {
    
    -- Creates a new camera
    -- @param initialZ initial z-offset (optional), can be retrieved from GetCameraTargetPositionZ()
    new = function(self, initialZ)
      local o = {}
      setmetatable(o,self)
      o.changed = false
      o.initialZ = initialZ or 0.
      o.eye = Vector3:new(0.0, -922.668, o.initialZ+1367.912)
      o.target = Vector3:new(0, 0, o.initialZ)
      o.distance = 0.
      o.yaw = 0.
      o.pitch = 0.
      o.roll = 0.
      o.axisX = Vector3:new()
      o.axisY = Vector3:new()
      o.axisZ = Vector3:new()
      o.view = Matrix4:new()
      o.projection = matrix4Perspective2(0.5, 10000, -screenWidth/2, screenWidth/2, -screenHeight/2, screenHeight/2)
      o:_updateDistanceYawPitch()
      o:_updateAxisMatrix()
      
      return o
    end,
    
    -- Converts window coordinate to world coordinate
    -- @param v Vector3 where x and y - window coords and z - overlay range
    -- @return Vector3
    windowToWorld = function(self, v)
      return Vector3:new(
        self.eye.x+self.axisZ.x*v.z+v.x*self.axisX.x*screenWidth*v.z+v.y*self.axisY.x*screenHeight*v.z,
        self.eye.y+self.axisZ.y*v.z+v.x*self.axisX.y*screenWidth*v.z+v.y*self.axisY.y*screenHeight*v.z,
        self.eye.z+self.axisZ.z*v.z+v.x*self.axisX.z*screenWidth*v.z+v.y*self.axisY.z*screenHeight*v.z
      )
    end,
    
    -- Converts world coordinate to window coordinate
    -- @param v Vector3
    -- @return Vector3
    worldToWindow = function(self, v)
      v = v:transform4(self.view):transform4(self.projection)
      v.z = math.abs(v.z)
      return v
    end,
    
    -- @param v Vector3
    setPosition = function(self, v)
      self.eye = self.eye + (v - self.target)
      self.target = Vector3:newFrom(v)
      self.changed = true
    end,
    
    -- @param eye Vector3
    -- @param target Vector3
    setEyeAndTarget = function(self, eye, target)
      self.eye = Vector3:newFrom(eye)
      self.target = Vector3:newFrom(target)
      self:_updateDistanceYawPitch()
      self:_updateAxisMatrix()
      self.changed = true
    end,
    
    -- @param v Vector3 where x = yaw, y = pitch, z = roll
    -- @param eyeLock boolean - move target instead of eye
    setYawPitchRoll = function(self, v, eyeLock)
      local XY = self.distance*math.cos(v.y)
      local modifier = Vector3:new(
        XY*math.cos(v.x),
        XY*math.sin(v.x),
        self.distance*math.sin(v.y)
      )
      self.yaw = v.x
      self.pitch = v.y
      self.roll = v.z
      if(eyeLock) then
        self.target = self.eye + modifier
      else
        self.eye = self.target - modifier
      end
      self:_updateAxisMatrix()
      self.changed = true
    end,
    
    -- uses warcraft native functions
    -- @param thePlayer Player
    -- @param skipChangedFlag boolean. Set to true to deny .changed flag unsetting
    applyCameraToPlayer = function(self, thePlayer, skipChangedFlag)
        if(GetLocalPlayer() == thePlayer) then
            SetCameraField(CAMERA_FIELD_ROTATION, self.yaw*radToDeg, 0)
            SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, self.pitch*radToDeg, 0)
            SetCameraField(CAMERA_FIELD_ROLL, self.roll*radToDeg, 0)
            SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, self.distance, 0)
            -- call SetCameraTargetController(AtUnit, self.target.x, self.target.y, false)
            SetCameraField(CAMERA_FIELD_ZOFFSET, self.target.z-self.initialZ, 0)
        end
        if(not skipChangedFlag) then
          self.changed = false
        end
    end,
    
    -- internal use methods
    _updateDistanceYawPitch = function(self)
      local delta = (self.target - self.eye)
      self.distance = delta:length()
      self.yaw = Atan2(delta.y, delta.x)
      self.pitch = Atan2(delta.z, delta:length2d())
    end,
    
    _updateAxisMatrix = function(self)
      self.axisZ = (self.target - self.eye):normalize()
      local mRotation = Matrix3:newRotationAxis(self.axisZ, -self.roll)
      self.axisX = self.axisZ:crossProduct(Vector3:newUp()):normalize()
      self.axisY = self.axisX:crossProduct(self.axisZ):transform3(mRotation)
      self.axisX = self.axisX:transform3(mRotation)
      self.view = matrix4Look(self.eye, self.axisX, self.axisY, self.axisZ)
    end
  }
  Camera.__index = Camera
  
  local wGeometry = {
    Functions = Functions,
    Vector3 = Vector3,
    Matrix3 = Matrix3,
    Matrix4 = Matrix4,
    matrix4perspective1 = matrix4perspective1,
    matrix4Perspective2 = matrix4Perspective2,
    matrix4Look = matrix4Look,
    Camera = Camera,
    unlockUnitZ = unlockUnitZ
  }
  exportDefault(wGeometry)
  export(wGeometry)
end)
