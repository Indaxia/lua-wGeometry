if(_G["WM"] == nil) then WM = (function(m,h) h(nil,(function() end), (function(e) _G[m] = e end)) end) end -- WLPM MM fallback

-- Warcraft 3 Geometry module by ScorpioT1000 / 2020
-- Thanks to DGUI by Ashujon / 2009
-- Thankes to The Mono.Xna Team / 2006
WM("wGeometry", function(import, export, exportDefault) 
  local Functions = nil
  local Vector3 = nil
  local Matrix3 = nil
  local Matrix4 = nil
  local Camera = nil
  local Box = nil
  local Sphere = nil
  local Ray = nil
  local zTesterLocation = Location(0,0)
  
  local radToDeg = 180.0 / math.pi
  local degToRad = math.pi / 180.0
  
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
  --- @param u Unit
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
    
    -- Create a vector from another
    clone = function(self, that)
      local o = {}
      setmetatable(o,self)
      o.x = that.x
      o.y = that.y
      o.z = that.z
      return o
    end,
    
    --- @deprecated use :clone()
    copyFrom = function(self,that) return Vector3:clone(that) end,
    
    -- Copy vector from Unit X/Y/Z
    --- @param u Unit
    copyFromUnit = function(self, u)
      local o = {}
      setmetatable(o,self)
      o.x = GetUnitX(u)
      o.y = GetUnitY(u)
      o.z = _GetUnitZ(u)
      return o
    end,
    
    -- Copy vector from Location X/Y/Z
    --- @param loc Location
    copyFromLocation = function(self, loc)
      local o = {}
      setmetatable(o,self)
      o.x = GetLocationX(loc)
      o.y = GetLocationY(loc)
      o.z = GetLocationZ(loc)
      return o
    end,
    
    -- Copy vector from Item X/Y/Z
    --- @param i Item
    copyFromItem = function(self, i)
      local o = {}
      setmetatable(o,self)
      o.x = GetItemX(i)
      o.y = GetItemY(i)
      o.z = _GetItemZ(i)
      return o
    end,
    
    -- Copy vector from Destructable X/Y/Z
    --- @param d Destructable
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
    
    --- @return Vector3 with zeroed Z coord
    to2D = function(self)
      return Vector3:new(self.x, self.y)
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
    --- @see https://en.wikipedia.org/wiki/Cross_product
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
    
    --- @param that Vector3
    --- @return number
    --- @see https://en.wikipedia.org/wiki/Dot_product
    dotProduct = function(self, that)
      return self.x*that.x + self.y*that.y + self.z*that.z
    end,
    
    --- @param that Vector3
    --- @return Vector3
    --- @see https://en.wikipedia.org/wiki/Cross_product
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
    
    -- Vector3 + Distance offset
    --- @param distance number in game units
    --- @param direction Vector3 normalized direction
    --- @return Vector3
    offset = function(self, distance, direction)
      return self + direction:scale(distance)
    end,
    
    -- Spheric coordinates offset
    --- @param distance number in game units
    --- @param yaw number (angle in radians)
    --- @param pitch number (angle in radians)
    --- @return Vector3 result point
    --- @see https://en.wikipedia.org/wiki/Aircraft_principal_axes
    yawPitchOffset = function(self, distance, yaw, pitch)
      return Vector3:new(
        distance * math.cos(yaw) * math.cos(pitch),
        distance * math.sin(yaw) * math.cos(pitch),
        distance * math.sin(pitch)
      )
    end,
    
    -- Spheric coordinates yaw angle
    --- @return float angle in radians
    getYaw = function(self)
      return Atan2(self.y, self.x)
    end,
    
    -- Spheric coordinates pitch angle
    --- @return float angle in radians
    getPitch = function(self)
      return Atan2(self.z, self:length2d())
    end,
    
    -- Transforms the vector by 3x3 matrix transformation components
    --- @param Matrix3 m
    --- @return Vector3
    --- @see https://en.wikipedia.org/wiki/Transformation_matrix
    transform3 = function(self, m)
      return Vector3:new(
        self.x*m.m11+self.y*m.m21+self.z*m.m31,
        self.x*m.m12+self.y*m.m22+self.z*m.m32,
        self.x*m.m13+self.y*m.m23+self.z*m.m33
      )
    end,
    
    -- Transforms the vector by 4x4 matrix transformation components
    --- @param Matrix4 m
    --- @return Vector3
    --- @see https://en.wikipedia.org/wiki/Transformation_matrix
    transform4 = function(self, m)
      local w = self.x*m.m14+self.y*m.m24+self.z*m.m34+m.m44
      return Vector3:new(
        (self.x*m.m11+self.y*m.m21+self.z*m.m31+m.m41)/w,
        (self.x*m.m12+self.y*m.m22+self.z*m.m32+m.m42)/w,
        (self.x*m.m13+self.y*m.m23+self.z*m.m33+m.m43)/w
      )
    end,
    
    -- Applies linear interpolation
    --- @param that Vector3
    --- @param amount current animation state, number between 0 and 1
    --- @return Vector3 result
    lerp = function(self, that, amount)
      return Vector3:new(
        Functions.lerp(self.x, that.x, amount),
        Functions.lerp(self.y, that.y, amount),
        Functions.lerp(self.z, that.z, amount)
      )
    end,
    
    -- Applies hermite spline interpolation
    --- @param that Vector3
    --- @param amount current animation state, number between 0 and 1  
    --- @param tangent1 (optional) 
    --- @param tangent2 (optional)
    --- @return Vector3 result
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
    --- @param p2 Vector3 point 2
    --- @param p3 Vector3 point 3
    --- @param amount current animation state, number between 0 and 1
    --- @return Vector3 result
    bezier = function(self, p2, p3, amount)
      return Vector3:new(
        Functions.bezier(self.x, p2.x, p3.x, amount),
        Functions.bezier(self.y, p2.y, p3.y, amount),
        Functions.bezier(self.z, p2.z, p3.z, amount)
      )
    end,
    
    -- Checks if the point is in a sphere
    --- @param c Vector3 sphere center
    --- @param r number sphere radius
    --- @return boolean
    --- @deprecated use Sphere:containsVector()
    isInSphere = function(self, c, r)
      return self:distanceSquared(c) < (r*r)
    end,
    
    -- Checks if the point is inside axis-aligned bounding box (AABB)
    --- @param vMin
    --- @param vMax
    --- @return boolean
    --- @deprecated use Box:containsVector()
    isInAABB = function(self, vMin, vMax)
      return (self.x >= vMin.x and self.x <= vMax.x) and
             (self.y >= vMin.y and self.y <= vMax.y) and
             (self.z >= vMin.z and self.z <= vMax.z)
    end,
    
    -- Checks if the vector is a zero-vector {0,0,0}
    --- @return boolean
    isZero = function(self)
      return self.x == 0. and self.y == 0. and self.z == 0.
    end,
    
    -- Applies coords to a location
    --- @param loc Location
    --- @return Vector3 self
    applyToLocation = function(self, loc)
      MoveLocation(loc, self.x, self.y)
      return self
    end,
    
    -- Adds coords to a location
    --- @param loc Location
    --- @return Vector3 self
    addToLocation = function(self, loc)
      MoveLocation(loc, GetLocationX(loc) + self.x, GetLocationY(loc) + self.y)
      return self
    end,
    
    -- Applies coords to a unit
    --- @param u Unit
    --- @return Vector3 self
    applyToUnit = function(self, u)
      SetUnitX(u, self.x)
      SetUnitY(u, self.y)
      _SetUnitZ(u, self.z)
      return self
    end,
    
    -- Applies to unit's yaw angle as direction vector
    --- @param u Unit
    --- @return Vector3 self
    applyToUnitFacing = function(self, u)
      if(self.x ~= 0. or self.y ~= 0.) then
        BlzSetUnitFacingEx(u, self:getYaw() * radToDeg)
      end
      return self
    end,
    
    -- Applies to unit's yaw angle as direction vector
    --- @param u Unit
    --- @param duration time in seconds
    --- @return Vector3 self
    applyToUnitFacingAnimated = function(self, u)
      if(self.x ~= 0. or self.y ~= 0.) then
        SetUnitFacing(u, self:getYaw() * radToDeg)
      end
      return self
    end,
    
    -- Adds coords to a unit
    --- @param u Unit
    --- @return Vector3 self
    addToUnit = function(self, u)
      SetUnitX(u, GetUnitX(u) + self.x)
      SetUnitY(u, GetUnitY(u) + self.y)
      if(self.z ~= 0) then -- performance improvement
        _SetUnitZ(u, _GetUnitZ(u) + self.z)
      end
      return self
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
    --- @return Matrix3
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
    
    -- Create a matrix from another
    --- @return Matrix3
    clone = function(self, that)
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
    
    --- @deprecated use :clone()
    copyFrom = function(self,that) return Matrix3:clone(that) end,
    
    -- Create a new identity matrix
    --- @return Matrix3
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
    --- @return Matrix3
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
    --- @return Matrix3
    --- @see https://en.wikipedia.org/wiki/Scaling_(geometry)
    newScaling = function(self, scaleX, scaleY, scaleZ)
      return Matrix3:new(
        scaleX or 1., 0., 0.,
        0., scaleY or 1., 0.,
        0., 0., scaleZ or 1.
      )
    end,
    
    -- Create a new rotation X matrix from the angle (in radians)
    --- @return Matrix3
    --- @see https://en.wikipedia.org/wiki/Rotation_matrix
    newRotationX = function(self, a)
      return Matrix3:new(
        1., 0., 0.,
        0., math.cos(a), -math.sin(a),
        0., math.sin(a), math.cos(a)
      )
    end,
    
    -- Create a new rotation Y matrix from the angle (in radians)
    --- @return Matrix3
    --- @see https://en.wikipedia.org/wiki/Rotation_matrix
    newRotationY = function(self, a)
      return Matrix3:new(
        math.cos(a), 0., math.sin(a),
        0., 1., 0.,
        -math.sin(a), 0., math.cos(a)
      )
    end,
    
    -- Create a new rotation Z matrix from the angle (in radians)
    --- @return Matrix3
    --- @see https://en.wikipedia.org/wiki/Rotation_matrix
    newRotationZ = function(self, a)
      return Matrix3:new(
        math.cos(a), -math.sin(a), 0.,
        math.sin(a), math.cos(a), 0.,
        0., 0., 1.
      )
    end,
    
    -- Create a new axis rotation matrix from the vector and angle (in radians)
    --- @param v Vector3
    --- @param a number
    --- @return Matrix3
    --- @see https://en.wikipedia.org/wiki/Axis%E2%80%93angle_representation
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
    --- @param v Vector3 where x = yaw, y = pitch, z = roll
    --- @return Matrix3
    --- @see https://en.wikipedia.org/wiki/Aircraft_principal_axes
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
    --- @return Matrix4
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
    
    -- Create a matrix from another 4x4 matrix
    --- @param Matrix4 that
    --- @return Matrix4
    clone = function(self, that)
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
    
    --- @deprecated use :clone()
    copyFrom = function(self,that) return Matrix4:clone(that) end,
    
    -- Creates a 4x4 matrix from 3x3 matrix
    --- @param Matrix3 that
    --- @return Matrix4
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
    --- @return Matrix4
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
  
  
  
  
  -- Bounding Box ====================
  -- Axis-aligned bounding box (AABB)
  Box = {
    -- Vector3 min
    -- Vector3 max
  
    -- Creates a new box
    --- @param minVector Vector3 (optional)
    --- @param maxVector Vector3 (optional)
    new = function(self, minVector, maxVector)
      local o = {}
      setmetatable(o,self)
      
      o.min = minVector or Vector3:new()
      o.max = maxVector or Vector3:new()
      
      return o
    end,
    
    -- Creates a new box from another box
    --- @param that Box
    clone = function(self, that)
      local o = {}
      setmetatable(o,self)
      
      o.min = Vector3:clone(that.min)
      o.max = Vector3:clone(that.max)
      
      return o
    end,
    
    -- Creates a new box from a sphere
    --- @param sphere Sphere
    newFromSphere = function(self, sphere)
      local o = {}
      setmetatable(o,self)
      local corner = Vector3:new(sphere.radius, sphere.radius, sphere.radius)
      
      o.min = sphere.center - corner
      o.max = sphere.center + corner
      
      return o
    end,
    
    -- Checks if the box contains a Vector3
    --- @param v Vector3
    containsVector = function(self, v)
      return     self.min.x <= v.x and self.max.x >= v.x
             and self.min.y <= v.y and self.max.y >= v.y
             and self.min.z <= v.z and self.max.z >= v.z
    end,
    
    -- Checks if the box contains a Box
    --- @param that Box
    containsBox = function(self, that)
      return     self.min.x <= that.min.x and self.max.x >= that.max.x
             and self.min.y <= that.min.y and self.max.y >= that.max.y
             and self.min.z <= that.min.z and self.max.z >= that.max.z
    end,
    
    -- Checks if the box contains a Sphere
    --- @param sphere Sphere
    containsSphere = function(self, sphere)
      return  sphere.center.x - self.min.x >= sphere.radius
          and sphere.center.y - self.min.y >= sphere.radius
          and sphere.center.z - self.min.z >= sphere.radius
          and self.max.x - sphere.center.x >= sphere.radius
          and self.max.y - sphere.center.y >= sphere.radius
          and self.max.z - sphere.center.z >= sphere.radius
    end,
    
    -- Checks if the box intersects a Box
    --- @param that Box
    --- @return boolean
    intersectsBox = function(self, that)
      if((self.max.x >= box.min.x) and (self.min.x <= box.max.x)) then
          if((self.max.y < box.min.y) or (self.min.y > box.max.y)) then
              return false
          end
          return (self.max.z >= box.min.z) and (self.min.z <= box.max.z)
      end
      return false
    end,
    
    -- Checks if the box intersects a Sphere
    --- @param sphere Sphere
    --- @return boolean
    intersectsSphere = function(self, sphere)
      if (sphere.center.x - self.min.x > sphere.radius
          and sphere.center.y - self.min.y > sphere.radius
          and sphere.center.z - self.min.z > sphere.radius
          and self.max.x - sphere.center.x > sphere.radius
          and self.max.y - sphere.center.y > sphere.radius
          and self.max.z - sphere.center.z > sphere.radius) then
        return true
      end

      local dmin = 0.

      if(sphere.center.x - self.min.x <= sphere.radius) then
        dmin = dmin + (sphere.center.x - self.min.x) * (sphere.center.x - self.min.x)
      elseif(self.max.x - sphere.center.x <= sphere.radius) then
        dmin = dmin + (sphere.center.x - self.max.x) * (sphere.center.x - self.max.x)
      end

      if(sphere.center.y - self.min.y <= sphere.radius) then
        dmin = dmin + (sphere.center.y - self.min.y) * (sphere.center.y - self.min.y)
      elseif(self.max.y - sphere.center.y <= sphere.radius) then
        dmin = dmin + (sphere.center.y - self.max.y) * (sphere.center.y - self.max.y)
      end

      if(sphere.center.z - self.min.z <= sphere.radius) then
        dmin = dmin + (sphere.center.z - self.min.z) * (sphere.center.z - self.min.z)
      elseif(self.max.z - sphere.center.z <= sphere.radius) then
        dmin = dmin + (sphere.center.z - self.max.z) * (sphere.center.z - self.max.z)
      end

      return (dmin <= sphere.radius * sphere.radius)
    end,
    
    --- @return table[] corners indexed array (8 elements)
    getCorners = function(self)
      return {
        Vector3:new(self.min.x, self.max.y, self.max.z), 
        Vector3:new(self.max.x, self.max.y, self.max.z),
        Vector3:new(self.max.x, self.min.y, self.max.z), 
        Vector3:new(self.min.x, self.min.y, self.max.z), 
        Vector3:new(self.min.x, self.max.y, self.min.z),
        Vector3:new(self.max.x, self.max.y, self.min.z),
        Vector3:new(self.max.x, self.min.y, self.min.z),
        Vector3:new(self.min.x, self.min.y, self.min.z)
      }
    end,
    
    -- Converts the box to a vertex grid
    --- @param edgeCount number divides planes into this number of edges
    --- @return table Vector3 vertex array
    toGrid = function(self, edgeCount)
      local grid = {}
      local length3d = self.max - self.min
      local vertexCount = edgeCount + 1 -- add extreme edges
      local chunkDistance3d = length3d / vertexCount
      local i = 1
      for ix = 0, vertexCount do
        for iy = 0, vertexCount do
          for iz = 0, vertexCount do
            grid[i] = Vector3:new(
              self.min.x + chunkDistance3d.x * ix,
              self.min.y + chunkDistance3d.y * iy,
              self.min.z + chunkDistance3d.z * iz
            )
            i = i + 1
          end
        end
      end
      return grid
    end,
    
    --- @return number box volume
    getVolume = function(self)
      return (self.max.x - self.min.x) * (self.max.y - self.min.y) * (self.max.z - self.min.z)
    end,
    
    -- Merges two boxes into one by their min/max sides
    --- @param that Box
    __add = function(self, that)
      return Box:new(
        Vector3:new(
          math.min(self.min.x, that.min.x),
          math.min(self.min.y, that.min.y),
          math.min(self.min.z, that.min.z)
        ),
        Vector3:new(
          math.min(self.max.x, that.max.x),
          math.min(self.max.y, that.max.y),
          math.min(self.max.z, that.max.z)
        )
      )
    end,
    
    __eq = function(self, that)
      return self.min == that.min and self.max == that.max
    end,
    
    -- Compares volumes
    __lt = function(self, that)
      return self:getVolume() < that:getVolume()
    end,
    
    -- Compares volumes
    __le = function(self, that)
      return self:getVolume() <= that:getVolume()
    end,
    
    __tostring = function(self)
      return "{\n  " .. tostring(self.min) .. ",\n  " .. tostring(self.max) .. "\n}"
    end,
  }
  Box.__index = Box
  
  
  
  
  -- Bounding sphere ====================
  Sphere = {
    -- Vector3 center
    -- number radius
  
    new = function(self, center, radius)
      local o = {}
      setmetatable(o,self)
      
      o.center = center or Vector3:new()
      o.radius = radius or 0.
    
      return o
    end,
    
    -- Creates a new sphere from another sphere
    --- @param that Sphere
    clone = function(self, that)
      local o = {}
      setmetatable(o,self)
      
      o.center = Vector3:clone(that.center)
      o.radius = that.radius
      
      return o
    end,
    
    -- Creates a new sphere from a box
    --- @param box Box
    newFromBox = function(self, box)
      local o = {}
      setmetatable(o,self)
      
      o.center = Vector3:new((box.min.X + box.max.X) / 2.,
                             (box.min.Y + box.max.Y) / 2.,
                             (box.min.Z + box.max.Z) / 2.)
      o.radius = o.center:distance(box.max)
    
      return o
    end,
    
    --- @return number sphere volume
    getVolume = function(self)
      return 4 / 3 * math.pi * self.radius * self.radius * self.radius
    end,
    
    -- Checks if the sphere contains a Vector3
    --- @param v Vector3
    containsVector = function(self, v)
      return v:distance(self.center) <= self.radius
    end,
    
    -- Checks if the sphere contains a Box
    --- @param box Box
    containsBox = function(self, box)
      local corners = box:getCorners()
      for i = 1, #corners do
        if(not self:containsVector(corners[i])) then
          return false
        end
      end
      return true
    end,
    
    -- Checks if the sphere contains a Sphere
    --- @param that Sphere
    containsSphere = function(self, that)
      return self.center:distance(that.center) <= (self.radius - that.radius)
    end,
    
    -- Checks if the sphere intersects a Box
    --- @param box Box
    --- @return boolean
    intersectsBox = function(self, box)
      return box.intersectsSphere(self)
    end,
    
    -- Checks if the sphere intersects a Sphere
    --- @param that Sphere
    --- @return boolean
    intersectsSphere = function(self, that)
			return that.center:distance(self.center) <= that.radius + self.radius
    end,
    
    -- Converts the sphere to a vertex grid (UV sphere)
    --- @param resolution number of latitude lines (vertices on the y axis)
    --- @return table Vector3 vertex array
    toGrid = function(self, resolution)
      local vSize = 4 * resolution
      local uSize = vSize * 2
      local grid = {}
      
      local i = 1
      local v = 0
      local u = 0
      local theta = 0.
      local phi = 0.
      
      while v < vSize do
        u = 0
        while u < uSize do
          theta = 2. * math.pi * u/uSize + math.pi
					phi = math.pi * v/vSize

          local v = Vector3:new(
            math.cos(theta) * math.sin(phi) * self.radius,
            -math.cos(phi) * self.radius,
            math.sin(theta) * math.sin(phi) * self.radius
          )
          if(v ~= grid[i-1]) then
            grid[i] = v
            i = i + 1
          end
          
          u = u + 1
        end
        v = v + 1
      end
      
      return grid
    end,
    
    -- Merges two spheres into one 
    --- @param that Sphere
    __add = function(self, that)
      local centerDelta = that.center - self.center
      local centerDistance = centerDelta:length()
      
      if(centerDistance <= self.radius + that.radius) then -- intersect
        if (centerDistance <= self.radius - that.radius) then
          return Sphere:clone(self) -- self contains that
        end
        if (centerDistance <= that.radius - self.radius) then
          return Sphere:clone(that) -- that contains self
        end
      end

      -- else find center of new sphere and radius
      local leftRadius = math.max(self.radius - centerDistance, that.radius)
      local rightRadius = math.max(self.radius + centerDistance, that.radius)
      local scale = (leftRadius - rightRadius) / (2. * distance)
      centerDelta = centerDelta + centerDelta:scale(scale)
      
      return Sphere:new(
        self.center + centerDelta,
        (leftRadius + rightRadius) / 2.
      )
    end,
    
    __eq = function(self, that)
      return self.center == that.center and self.radius == that.radius
    end,
    
    __lt = function(self, that)
      return self.radius < that.radius
    end,
    
    __le = function(self, that)
      return self.radius <= that.radius
    end,
    
    __tostring = function(self)
      return "{\n  " .. tostring(self.min) .. ",\n  " .. tostring(self.radius) .. "\n}"
    end,
  }
  Sphere.__index = Sphere
  
  
  
  
  -- Ray ====================
  Ray = {
    -- Vector3 position
    -- Vector3 direction
  
    new = function(self, position, direction)
      local o = {}
      setmetatable(o,self)
      
      o.position = position or Vector3:new()
      o.direction = direction or Vector3:new()
    
      return o
    end,
    
    -- Creates a new ray from another ray
    --- @param that Ray
    clone = function(self, that)
      local o = {}
      setmetatable(o,self)
      
      o.position = Vector3:clone(that.position)
      o.direction = Vector3:clone(that.direction)
      
      return o
    end,
        
    -- Checks if the ray intersects a Box
    --- @param box Box
    --- @return number|nil If returned the number then it's the distance from .position at which it intersects the object
    --                    Otherwise it returns nil (no intersection)
    intersectsBox = function(self, box)
      -- first test if start in box
      if (self.position.x >= box.min.x
        and self.position.x <= box.max.x
        and self.position.y >= box.min.y
        and self.position.y <= box.max.y
        and self.position.z >= box.min.z
        and self.position.z <= box.max.z) then
        return 0. -- here we concidere cube is full and origine is in cube so intersect at origine
      end

        -- Second we check each face
        local maxT = Vector3:new(-1., -1., -1.)
        -- calcul intersection with each faces
        if (self.position.x < box.min.x and self.direction.x ~= 0.) then
          maxT.x = (box.min.x - self.position.x) / self.direction.x
        elseif(self.position.x > box.max.x and self.direction.x ~= 0.) then
          maxT.x = (box.max.x - self.position.x) / self.direction.x
        end
        if(self.position.y < box.min.y and self.direction.y ~= 0.) then
          maxT.y = (box.min.y - self.position.y) / self.direction.y
        elseif(self.position.y > box.max.y and self.direction.y ~= 0.) then
          maxT.y = (box.max.y - self.position.y) / self.direction.y
        end
        if(self.position.z < box.min.z and self.direction.z ~= 0.) then
          maxT.z = (box.min.z - self.position.z) / self.direction.z
        elseif(self.position.z > box.max.z and self.direction.z ~= 0.) then
          maxT.z = (box.max.z - self.position.z) / self.direction.z
        end

        -- get the maximum maxT
        if (maxT.x > maxT.y and maxT.x > maxT.z) then
          if(maxT.x < 0.) then
            return nil -- ray go on opposite of face
          end
          -- coordonate of hit point of face of cube
          local coord = self.position.z + maxT.x * self.direction.z
          -- if hit point coord ( intersect face with ray) is out of other plane coord it miss 
          if(coord < box.min.z or coord > box.max.z) then
            return nil
          end
          coord = self.position.y + maxT.x * self.direction.y
          if(coord < box.min.y or coord > box.max.y) then
            return nil
          end
          return maxT.x
        end
        if(maxT.y > maxT.x and maxT.y > maxT.z) then
          if (maxT.y < 0.) then
            return nil -- ray go on opposite of face
          end
          -- coordonate of hit point of face of cube
          local coord = self.position.z + maxT.y * self.direction.z
          -- if hit point coord ( intersect face with ray) is out of other plane coord it miss 
          if(coord < box.min.z or coord > box.max.z) then
            return nil
          end
          coord = self.position.x + maxT.y * self.direction.x
          if(coord < box.min.x or coord > box.max.x) then
            return nil
          end
          return maxT.y
        else -- Z
          if(maxT.z < 0.) then
            return nil -- ray go on opposite of face
          end
          -- coordonate of hit point of face of cube
          local coord = self.position.x + maxT.z * self.direction.x
          -- if hit point coord ( intersect face with ray) is out of other plane coord it miss 
          if(coord < box.min.x or coord > box.max.x) then
            return nil
          end
          coord = self.position.y + maxT.z * self.direction.y
          if(coord < box.min.y or coord > box.max.y) then
            return nil
          end
          return maxT.z
        end
    end,
    
    -- Checks if the ray intersects a Sphere
    --- @param sphere Sphere
    --- @return number|nil If returned the number then it's the distance from .position at which it intersects the object
    --                    Otherwise it returns nil (no intersection)
    intersectsSphere = function(self, sphere)
      -- Find the vector between where the ray starts the the sphere's centre
      local difference = sphere.center - self.position
      local differenceLengthSquared = difference:lengthSquared()
      local sphereRadiusSquared = sphere.radius * sphere.radius

      -- If the distance between the ray start and the sphere's centre is less than
      -- the radius of the sphere, it means we've intersected. N.B. checking the LengthSquared is faster.
      if(differenceLengthSquared < sphereRadiusSquared) then
        return 0.
      end

      local distanceAlongRay = self.direction:dotProduct(difference)

      -- If the ray is pointing away from the sphere then we don't ever intersect
      if(distanceAlongRay < 0.) then
        return nil
      end

      -- Next we kinda use Pythagoras to check if we are within the bounds of the sphere
      -- if x = radius of sphere
      -- if y = distance between ray position and sphere centre
      -- if z = the distance we've travelled along the ray
      -- if x^2 + z^2 - y^2 < 0, we do not intersect
      local dist = sphereRadiusSquared + distanceAlongRay * distanceAlongRay - differenceLengthSquared;

      if(dist < 0.) then
        return nil
      end
      return distanceAlongRay - math.sqrt(dist);
    end,
    
    -- Converts ray to a vertex line
    --- @param length number line limit
    --- @param vertexCount number number of additional vertices in a line
    --- @return table Vector3 vertex array 
    toGrid = function(self, length, vertexCount)
      local grid = {}
      local chunkDistance = length / vertexCount
      for i = 0, vertexCount do
        grid[i+1] = self.position:offset(chunkDistance * i, self.direction)
      end
      return grid
    end,
    
    __eq = function(self, that)
      return self.position == that.position and self.direction == that.direction
    end,
    
    __tostring = function(self)
      return "{\n  " .. tostring(self.position) .. ",\n  " .. tostring(self.direction) .. "\n}"
    end,
  }
  Ray.__index = Ray
  
  
  
  
  -- Projections ====================
  -- Screen aspect ratio
  local screenWidth = 0.544
  local screenHeight = 0.302
  
  -- Builds a perspective projection matrix based on a field of view.
  --- @return Matrix4
  --- @see https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dxmatrixperspectivefovlh
  local matrix4perspective1 = function(fovy, Aspect, zn, zf)
    return Matrix4:new(2*zn/fovy,0,0,0,0,2*zn/Aspect,0,0,0,0,zf/(zf-zn),1,0,0,zn*zf/(zn-zf),0)
  end
  
  -- Builds a customized perspective projection matrix
  --- @return Matrix4
  --- @see https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dxmatrixperspectiveoffcenterlh
  local matrix4Perspective2 = function(n, f, r, l, t, b)
    return Matrix4:new(2*n/(r-l), 0, (r+l)/(r-l), 0, 0, 2*n/(t-b), (t+b)/(t-b), 0, 0, 0, -(f+n)/(f-n), -2*f*n/(f-n), 0, 0, -1, 0)
  end
  
  -- Builds a look-at matrix
  --- @param PosCamera Vector3 
  --- @param AxisX Vector3
  --- @param AxisY Vector3
  --- @param AxisZ Vector3
  --- @return Matrix4
  --- @see https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dxmatrixlookatlh
  local matrix4Look = function(PosCamera, AxisX, AxisY, AxisZ)
    return Matrix4:new(AxisX.x,AxisY.x,AxisZ.x,0,AxisX.y,AxisY.y,AxisZ.y,0,AxisX.z,AxisY.z,AxisZ.z,0,-AxisX:dotProduct(PosCamera),-AxisY:dotProduct(PosCamera),-AxisZ:dotProduct(PosCamera),1)
  end
  
  
  
  
  -- Camera ====================
  -- Game camera projection state with eye and target
  --- @see https://knowledge.autodesk.com/support/3ds-max/learn-explore/caas/CloudHelp/cloudhelp/2017/ENU/3DSMax/files/GUID-B1F4F126-65AC-4CB6-BDC3-02799A0BAEF3-htm.html
  Camera = {
    
    -- Creates a new camera
    --- @param initialZ number initial z-offset (optional), can be retrieved from GetCameraTargetPositionZ()
    new = function(self, initialZ)
      local o = {}
      setmetatable(o,self)
      o.changed = false
      o.initialZ = initialZ or 0.
      o.eye = Vector3:new(0.0, -922.668, o.initialZ + 1367.912)
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
    
    -- Creates a new camera from another
    --- @param that Camera
    clone = function(self, that)
      local o = {}
      setmetatable(o,self)      
      o.changed = that.changed
      o.initialZ = that.initialZ
      o.eye = Vector3:clone(that.eye)
      o.target = Vector3:clone(that.target)
      o.distance = that.distance
      o.yaw = that.yaw
      o.pitch = that.pitch
      o.roll = that.roll
      o.axisX = Vector3:clone(that.axisX)
      o.axisY = Vector3:clone(that.axisY)
      o.axisZ = Vector3:clone(that.axisZ)
      o.view = Matrix4:clone(that.view)
      o.projection = Matrix4:clone(that.projection)
      
      return o
    end,
    
    -- Converts window coordinate to world coordinate
    --- @param v Vector3 where x and y - window coords and z - overlay range
    --- @return Vector3
    windowToWorld = function(self, v)
      return Vector3:new(
        self.eye.x+self.axisZ.x*v.z+v.x*self.axisX.x*screenWidth*v.z+v.y*self.axisY.x*screenHeight*v.z,
        self.eye.y+self.axisZ.y*v.z+v.x*self.axisX.y*screenWidth*v.z+v.y*self.axisY.y*screenHeight*v.z,
        self.eye.z+self.axisZ.z*v.z+v.x*self.axisX.z*screenWidth*v.z+v.y*self.axisY.z*screenHeight*v.z
      )
    end,
    
    -- Converts world coordinate to window coordinate
    --- @param v Vector3
    --- @return Vector3
    worldToWindow = function(self, v)
      v = v:transform4(self.view):transform4(self.projection)
      v.z = math.abs(v.z)
      return v
    end,
    
    --- @param v Vector3
    setPosition = function(self, v)
      self.eye = self.eye + (v - self.target)
      self.target = Vector3:newFrom(v)
      self.changed = true
    end,
    
    --- @param eye Vector3
    --- @param target Vector3
    setEyeAndTarget = function(self, eye, target)
      self.eye = Vector3:newFrom(eye)
      self.target = Vector3:newFrom(target)
      self:_updateDistanceYawPitch()
      self:_updateAxisMatrix()
      self.changed = true
    end,
    
    --- @param v Vector3 where x = yaw, y = pitch, z = roll
    --- @param eyeLock boolean - move target instead of eye
    setYawPitchRoll = function(self, v, eyeLock)
      local XY = self.distance*math.cos(v.y)
      local modifier = Vector3:new(
        XY * math.cos(v.x),
        XY * math.sin(v.x),
        self.distance * math.sin(v.y)
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
    --- @param thePlayer Player
    --- @param skipChangedFlag boolean. Set to true to deny .changed flag unsetting
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
      self.yaw = delta:getYaw()
      self.pitch = delta:getPitch()
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
    Box = Box,
    Sphere = Sphere,
    Ray = Ray,
    matrix4perspective1 = matrix4perspective1,
    matrix4Perspective2 = matrix4Perspective2,
    matrix4Look = matrix4Look,
    Camera = Camera,
    unlockUnitZ = unlockUnitZ
  }
  exportDefault(wGeometry)
  export(wGeometry)
end)
