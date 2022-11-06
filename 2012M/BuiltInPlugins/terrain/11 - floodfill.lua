--rbxsig%IEUAo3Q1k4Rwb3ZcqPBum//j3+Jm/9Nv0JyCeCRWUrggWps7aG81/aPzlH9pPlMkkdsZwLsCRu6eTTrqzXn2DAJNPRs7y8akc3z91r1DP3jwomfpdT+2DBAmPk3Cdj8NXQzP6T+uEYm2kk2TW9pXonKvCgRVqXFx8J7mTr+aM1M=%
--rbxassetid%45284430%
--rbxsig%py7DtxVWYsfiGWFcgOeTTD6t0Y83b+A8f/srSajSOoTfmDGWj4ZZOUrHRAb0bF1HYs/cTXG10GhZn0vFWP5jDEKOuAlmVYbdattbE/6+DIGFVwzRT8TycYFLLCol0lcc79vrU1b0RnPYt8bZwGnbFeWIObCxHKrGgQXDYKwGeuQ=%
--rbxassetid%60595411%
local t = {}

 

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------JSON Functions Begin----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

 --JSON Encoder and Parser for Lua 5.1
 --
 --Copyright 2007 Shaun Brown  (http://www.chipmunkav.com)
 --All Rights Reserved.
 
 --Permission is hereby granted, free of charge, to any person 
 --obtaining a copy of this software to deal in the Software without 
 --restriction, including without limitation the rights to use, 
 --copy, modify, merge, publish, distribute, sublicense, and/or 
 --sell copies of the Software, and to permit persons to whom the 
 --Software is furnished to do so, subject to the following conditions:
 
 --The above copyright notice and this permission notice shall be 
 --included in all copies or substantial portions of the Software.
 --If you find this software useful please give www.chipmunkav.com a mention.

 --THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 --EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 --OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 --IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
 --ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
 --CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
 --CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
local string = string
local math = math
local table = table
local error = error
local tonumber = tonumber
local tostring = tostring
local type = type
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local assert = assert
local Chipmunk = Chipmunk


local StringBuilder = {
	buffer = {}
}

function StringBuilder:New()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.buffer = {}
	return o
end

function StringBuilder:Append(s)
	self.buffer[#self.buffer+1] = s
end

function StringBuilder:ToString()
	return table.concat(self.buffer)
end

local JsonWriter = {
	backslashes = {
		['\b'] = "\\b",
		['\t'] = "\\t",	
		['\n'] = "\\n", 
		['\f'] = "\\f",
		['\r'] = "\\r", 
		['"']  = "\\\"", 
		['\\'] = "\\\\", 
		['/']  = "\\/"
	}
}

function JsonWriter:New()
	local o = {}
	o.writer = StringBuilder:New()
	setmetatable(o, self)
	self.__index = self
	return o
end

function JsonWriter:Append(s)
	self.writer:Append(s)
end

function JsonWriter:ToString()
	return self.writer:ToString()
end

function JsonWriter:Write(o)
	local t = type(o)
	if t == "nil" then
		self:WriteNil()
	elseif t == "boolean" then
		self:WriteString(o)
	elseif t == "number" then
		self:WriteString(o)
	elseif t == "string" then
		self:ParseString(o)
	elseif t == "table" then
		self:WriteTable(o)
	elseif t == "function" then
		self:WriteFunction(o)
	elseif t == "thread" then
		self:WriteError(o)
	elseif t == "userdata" then
		self:WriteError(o)
	end
end

function JsonWriter:WriteNil()
	self:Append("null")
end

function JsonWriter:WriteString(o)
	self:Append(tostring(o))
end

function JsonWriter:ParseString(s)
	self:Append('"')
	self:Append(string.gsub(s, "[%z%c\\\"/]", function(n)
		local c = self.backslashes[n]
		if c then return c end
		return string.format("\\u%.4X", string.byte(n))
	end))
	self:Append('"')
end

function JsonWriter:IsArray(t)
	local count = 0
	local isindex = function(k) 
		if type(k) == "number" and k > 0 then
			if math.floor(k) == k then
				return true
			end
		end
		return false
	end
	for k,v in pairs(t) do
		if not isindex(k) then
			return false, '{', '}'
		else
			count = math.max(count, k)
		end
	end
	return true, '[', ']', count
end

function JsonWriter:WriteTable(t)
	local ba, st, et, n = self:IsArray(t)
	self:Append(st)	
	if ba then		
		for i = 1, n do
			self:Write(t[i])
			if i < n then
				self:Append(',')
			end
		end
	else
		local first = true;
		for k, v in pairs(t) do
			if not first then
				self:Append(',')
			end
			first = false;			
			self:ParseString(k)
			self:Append(':')
			self:Write(v)			
		end
	end
	self:Append(et)
end

function JsonWriter:WriteError(o)
	error(string.format(
		"Encoding of %s unsupported", 
		tostring(o)))
end

function JsonWriter:WriteFunction(o)
	if o == Null then 
		self:WriteNil()
	else
		self:WriteError(o)
	end
end

local StringReader = {
	s = "",
	i = 0
}

function StringReader:New(s)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.s = s or o.s
	return o	
end

function StringReader:Peek()
	local i = self.i + 1
	if i <= #self.s then
		return string.sub(self.s, i, i)
	end
	return nil
end

function StringReader:Next()
	self.i = self.i+1
	if self.i <= #self.s then
		return string.sub(self.s, self.i, self.i)
	end
	return nil
end

function StringReader:All()
	return self.s
end

local JsonReader = {
	escapes = {
		['t'] = '\t',
		['n'] = '\n',
		['f'] = '\f',
		['r'] = '\r',
		['b'] = '\b',
	}
}

function JsonReader:New(s)
	local o = {}
	o.reader = StringReader:New(s)
	setmetatable(o, self)
	self.__index = self
	return o;
end

function JsonReader:Read()
	self:SkipWhiteSpace()
	local peek = self:Peek()
	if peek == nil then
		error(string.format(
			"Nil string: '%s'", 
			self:All()))
	elseif peek == '{' then
		return self:ReadObject()
	elseif peek == '[' then
		return self:ReadArray()
	elseif peek == '"' then
		return self:ReadString()
	elseif string.find(peek, "[%+%-%d]") then
		return self:ReadNumber()
	elseif peek == 't' then
		return self:ReadTrue()
	elseif peek == 'f' then
		return self:ReadFalse()
	elseif peek == 'n' then
		return self:ReadNull()
	elseif peek == '/' then
		self:ReadComment()
		return self:Read()
	else
		return nil
	end
end
		
function JsonReader:ReadTrue()
	self:TestReservedWord{'t','r','u','e'}
	return true
end

function JsonReader:ReadFalse()
	self:TestReservedWord{'f','a','l','s','e'}
	return false
end

function JsonReader:ReadNull()
	self:TestReservedWord{'n','u','l','l'}
	return nil
end

function JsonReader:TestReservedWord(t)
	for i, v in ipairs(t) do
		if self:Next() ~= v then
			 error(string.format(
				"Error reading '%s': %s", 
				table.concat(t), 
				self:All()))
		end
	end
end

function JsonReader:ReadNumber()
        local result = self:Next()
        local peek = self:Peek()
        while peek ~= nil and string.find(
		peek, 
		"[%+%-%d%.eE]") do
            result = result .. self:Next()
            peek = self:Peek()
	end
	result = tonumber(result)
	if result == nil then
	        error(string.format(
			"Invalid number: '%s'", 
			result))
	else
		return result
	end
end

function JsonReader:ReadString()
	local result = ""
	assert(self:Next() == '"')
        while self:Peek() ~= '"' do
		local ch = self:Next()
		if ch == '\\' then
			ch = self:Next()
			if self.escapes[ch] then
				ch = self.escapes[ch]
			end
		end
                result = result .. ch
	end
        assert(self:Next() == '"')
	local fromunicode = function(m)
		return string.char(tonumber(m, 16))
	end
	return string.gsub(
		result, 
		"u%x%x(%x%x)", 
		fromunicode)
end

function JsonReader:ReadComment()
        assert(self:Next() == '/')
        local second = self:Next()
        if second == '/' then
            self:ReadSingleLineComment()
        elseif second == '*' then
            self:ReadBlockComment()
        else
            error(string.format(
		"Invalid comment: %s", 
		self:All()))
	end
end

function JsonReader:ReadBlockComment()
	local done = false
	while not done do
		local ch = self:Next()		
		if ch == '*' and self:Peek() == '/' then
			done = true
                end
		if not done and 
			ch == '/' and 
			self:Peek() == "*" then
                    error(string.format(
			"Invalid comment: %s, '/*' illegal.",  
			self:All()))
		end
	end
	self:Next()
end

function JsonReader:ReadSingleLineComment()
	local ch = self:Next()
	while ch ~= '\r' and ch ~= '\n' do
		ch = self:Next()
	end
end

function JsonReader:ReadArray()
	local result = {}
	assert(self:Next() == '[')
	local done = false
	if self:Peek() == ']' then
		done = true;
	end
	while not done do
		local item = self:Read()
		result[#result+1] = item
		self:SkipWhiteSpace()
		if self:Peek() == ']' then
			done = true
		end
		if not done then
			local ch = self:Next()
			if ch ~= ',' then
				error(string.format(
					"Invalid array: '%s' due to: '%s'", 
					self:All(), ch))
			end
		end
	end
	assert(']' == self:Next())
	return result
end

function JsonReader:ReadObject()
	local result = {}
	assert(self:Next() == '{')
	local done = false
	if self:Peek() == '}' then
		done = true
	end
	while not done do
		local key = self:Read()
		if type(key) ~= "string" then
			error(string.format(
				"Invalid non-string object key: %s", 
				key))
		end
		self:SkipWhiteSpace()
		local ch = self:Next()
		if ch ~= ':' then
			error(string.format(
				"Invalid object: '%s' due to: '%s'", 
				self:All(), 
				ch))
		end
		self:SkipWhiteSpace()
		local val = self:Read()
		result[key] = val
		self:SkipWhiteSpace()
		if self:Peek() == '}' then
			done = true
		end
		if not done then
			ch = self:Next()
                	if ch ~= ',' then
				error(string.format(
					"Invalid array: '%s' near: '%s'", 
					self:All(), 
					ch))
			end
		end
	end
	assert(self:Next() == "}")
	return result
end

function JsonReader:SkipWhiteSpace()
	local p = self:Peek()
	while p ~= nil and string.find(p, "[%s/]") do
		if p == '/' then
			self:ReadComment()
		else
			self:Next()
		end
		p = self:Peek()
	end
end

function JsonReader:Peek()
	return self.reader:Peek()
end

function JsonReader:Next()
	return self.reader:Next()
end

function JsonReader:All()
	return self.reader:All()
end

function Encode(o)
	local writer = JsonWriter:New()
	writer:Write(o)
	return writer:ToString()
end

function Decode(s)
	local reader = JsonReader:New(s)
	return reader:Read()
end

function Null()
	return Null
end
-------------------- End JSON Parser ------------------------


t.DecodeJSON = function(jsonString)
	if type(jsonString) == "string" then
		return Decode(jsonString)
	end
	print("RbxUtil.DecodeJSON expects string argument!")
	return nil
end

t.EncodeJSON = function(jsonTable)
	return Encode(jsonTable)
end








------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--------------------------------------------Terrain Utilities Begin-----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--makes a wedge at location x, y, z
--sets cell x, y, z to default material if parameter is provided, if not sets cell x, y, z to be whatever material it previously w
--returns true if made a wedge, false if the cell remains a block
t.MakeWedge = function(x, y, z, defaultmaterial)
	return game:GetService("Terrain"):AutoWedgeCell(x,y,z)
end

t.SelectTerrainRegion = function(regionToSelect, color, selectEmptyCells, selectionParent)
	local terrain = game.Workspace:FindFirstChild("Terrain")
	if not terrain then return end

	assert(regionToSelect)
	assert(color)

	if not type(regionToSelect) == "Region3" then
		error("regionToSelect (first arg), should be of type Region3, but is type",type(regionToSelect))
	end
	if not type(color) == "BrickColor" then
		error("color (second arg), should be of type BrickColor, but is type",type(color))
	end

	-- frequently used terrain calls (speeds up call, no lookup necessary)
	local GetCell = terrain.GetCell
	local WorldToCellPreferSolid = terrain.WorldToCellPreferSolid
	local CellCenterToWorld = terrain.CellCenterToWorld
	local emptyMaterial = Enum.CellMaterial.Empty

	-- container for all adornments, passed back to user
	local selectionContainer = Instance.new("Model")
	selectionContainer.Name = "SelectionContainer"
	selectionContainer.Archivable = false
	if selectionParent then
		selectionContainer.Parent = selectionParent
	else
		selectionContainer.Parent = game.Workspace
	end

	local updateSelection = nil -- function we return to allow user to update selection
	local currentKeepAliveTag = nil -- a tag that determines whether adorns should be destroyed
	local aliveCounter = 0 -- helper for currentKeepAliveTag
	local lastRegion = nil -- used to stop updates that do nothing
	local adornments = {} -- contains all adornments
	local reusableAdorns = {}

	local selectionPart = Instance.new("Part")
	selectionPart.Name = "SelectionPart"
	selectionPart.Transparency = 1
	selectionPart.Anchored = true
	selectionPart.Locked = true
	selectionPart.CanCollide = false
	selectionPart.FormFactor = Enum.FormFactor.Custom
	selectionPart.Size = Vector3.new(4.2,4.2,4.2)

	local selectionBox = Instance.new("SelectionBox")

	-- srs translation from region3 to region3int16
	function Region3ToRegion3int16(region3)
		local theLowVec = region3.CFrame.p - (region3.Size/2) + Vector3.new(2,2,2)
		local lowCell = WorldToCellPreferSolid(terrain,theLowVec)

		local theHighVec = region3.CFrame.p + (region3.Size/2) - Vector3.new(2,2,2)
		local highCell = WorldToCellPreferSolid(terrain, theHighVec)

		local highIntVec = Vector3int16.new(highCell.x,highCell.y,highCell.z)
		local lowIntVec = Vector3int16.new(lowCell.x,lowCell.y,lowCell.z)

		return Region3int16.new(lowIntVec,highIntVec)
	end

	-- helper function that creates the basis for a selection box
	function createAdornment(theColor)
		local selectionPartClone = nil
		local selectionBoxClone = nil

		if #reusableAdorns > 0 then
			selectionPartClone = reusableAdorns[1]["part"]
			selectionBoxClone = reusableAdorns[1]["box"]
			table.remove(reusableAdorns,1)

			selectionBoxClone.Visible = true
		else
			selectionPartClone = selectionPart:Clone()
			selectionPartClone.Archivable = false

			selectionBoxClone = selectionBox:Clone()
			selectionBoxClone.Archivable = false

			selectionBoxClone.Adornee = selectionPartClone
			selectionBoxClone.Parent = selectionContainer

			selectionBoxClone.Adornee = selectionPartClone

			selectionBoxClone.Parent = selectionContainer
		end
			
		if theColor then
			selectionBoxClone.Color = theColor
		end

		return selectionPartClone, selectionBoxClone
	end

	-- iterates through all current adornments and deletes any that don't have latest tag
	function cleanUpAdornments()
		for cellPos, adornTable in pairs(adornments) do

			if adornTable.KeepAlive ~= currentKeepAliveTag then -- old news, we should get rid of this
				adornTable.SelectionBox.Visible = false
				table.insert(reusableAdorns,{part = adornTable.SelectionPart, box = adornTable.SelectionBox})
				adornments[cellPos] = nil
			end
		end
	end

	-- helper function to update tag
	function incrementAliveCounter()
		aliveCounter = aliveCounter + 1
		if aliveCounter > 1000000 then
			aliveCounter = 0
		end
		return aliveCounter
	end

	-- finds full cells in region and adorns each cell with a box, with the argument color
	function adornFullCellsInRegion(region, color)
		local regionBegin = region.CFrame.p - (region.Size/2) + Vector3.new(2,2,2)
		local regionEnd = region.CFrame.p + (region.Size/2) - Vector3.new(2,2,2)

		local cellPosBegin = WorldToCellPreferSolid(terrain, regionBegin)
		local cellPosEnd = WorldToCellPreferSolid(terrain, regionEnd)

		currentKeepAliveTag = incrementAliveCounter()
		for y = cellPosBegin.y, cellPosEnd.y do
			for z = cellPosBegin.z, cellPosEnd.z do
				for x = cellPosBegin.x, cellPosEnd.x do
					local cellMaterial = GetCell(terrain, x, y, z)
					
					if cellMaterial ~= emptyMaterial then
						local cframePos = CellCenterToWorld(terrain, x, y, z)
						local cellPos = Vector3int16.new(x,y,z)

						local updated = false
						for cellPosAdorn, adornTable in pairs(adornments) do
							if cellPosAdorn == cellPos then
								adornTable.KeepAlive = currentKeepAliveTag
								if color then
									adornTable.SelectionBox.Color = color
								end
								updated = true
								break
							end 
						end

						if not updated then
							local selectionPart, selectionBox = createAdornment(color)
							selectionPart.Size = Vector3.new(4,4,4)
							selectionPart.CFrame = CFrame.new(cframePos)
							local adornTable = {SelectionPart = selectionPart, SelectionBox = selectionBox, KeepAlive = currentKeepAliveTag}
							adornments[cellPos] = adornTable
						end
					end
				end
			end
		end
		cleanUpAdornments()
	end


	------------------------------------- setup code ------------------------------
	lastRegion = regionToSelect

	if selectEmptyCells then -- use one big selection to represent the area selected
		local selectionPart, selectionBox = createAdornment(color)

		selectionPart.Size = regionToSelect.Size
		selectionPart.CFrame = regionToSelect.CFrame

		adornments.SelectionPart = selectionPart
		adornments.SelectionBox = selectionBox

		updateSelection = 
			function (newRegion, color)
				if newRegion and newRegion ~= lastRegion then
					lastRegion = newRegion
				 	selectionPart.Size = newRegion.Size
					selectionPart.CFrame = newRegion.CFrame
				end
				if color then
					selectionBox.Color = color
				end
			end
	else -- use individual cell adorns to represent the area selected
		adornFullCellsInRegion(regionToSelect, color)
		updateSelection = 
			function (newRegion, color)
				if newRegion and newRegion ~= lastRegion then
					lastRegion = newRegion
					adornFullCellsInRegion(newRegion, color)
				end
			end

	end

	local destroyFunc = function()
		updateSelection = nil
		if selectionContainer then selectionContainer:Destroy() end
		adornments = nil
	end

	return updateSelection, destroyFunc
end

-----------------------------Terrain Utilities End-----------------------------







------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------Signal class begin------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--[[
A 'Signal' object identical to the internal RBXScriptSignal object in it's public API and semantics. This function 
can be used to create "custom events" for user-made code.
API:
Method :connect( function handler )
	Arguments:   The function to connect to.
	Returns:     A new connection object which can be used to disconnect the connection
	Description: Connects this signal to the function specified by |handler|. That is, when |fire( ... )| is called for
	             the signal the |handler| will be called with the arguments given to |fire( ... )|. Note, the functions
	             connected to a signal are called in NO PARTICULAR ORDER, so connecting one function after another does
	             NOT mean that the first will be called before the second as a result of a call to |fire|.

Method :disconnect()
	Arguments:   None
	Returns:     None
	Description: Disconnects all of the functions connected to this signal.

Method :fire( ... )
	Arguments:   Any arguments are accepted
	Returns:     None
	Description: Calls all of the currently connected functions with the given arguments.

Method :wait()
	Arguments:   None
	Returns:     The arguments given to fire
	Description: This call blocks until 
]]

function t.CreateSignal()
	local this = {}

	local mBindableEvent = Instance.new('BindableEvent')
	local mAllCns = {} --all connection objects returned by mBindableEvent::connect

	--main functions
	function this:connect(func)
		if self ~= this then error("connect must be called with `:`, not `.`", 2) end
		if type(func) ~= 'function' then
			error("Argument #1 of connect must be a function, got a "..type(func), 2)
		end
		local cn = mBindableEvent.Event:connect(func)
		mAllCns[cn] = true
		local pubCn = {}
		function pubCn:disconnect()
			cn:disconnect()
			mAllCns[cn] = nil
		end
		return pubCn
	end
	function this:disconnect()
		if self ~= this then error("disconnect must be called with `:`, not `.`", 2) end
		for cn, _ in pairs(mAllCns) do
			cn:disconnect()
			mAllCns[cn] = nil
		end
	end
	function this:wait()
		if self ~= this then error("wait must be called with `:`, not `.`", 2) end
		return mBindableEvent.Event:wait()
	end
	function this:fire(...)
		if self ~= this then error("fire must be called with `:`, not `.`", 2) end
		mBindableEvent:Fire(...)
	end

	return this
end

------------------------------------------------- Sigal class End ------------------------------------------------------




------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------Create Function Begins---------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--[[
A "Create" function for easy creation of Roblox instances. The function accepts a string which is the classname of
the object to be created. The function then returns another function which either accepts accepts no arguments, in 
which case it simply creates an object of the given type, or a table argument that may contain several types of data, 
in which case it mutates the object in varying ways depending on the nature of the aggregate data. These are the
type of data and what operation each will perform:
1) A string key mapping to some value:
      Key-Value pairs in this form will be treated as properties of the object, and will be assigned in NO PARTICULAR
      ORDER. If the order in which properties is assigned matter, then they must be assigned somewhere else than the
      |Create| call's body.

2) An integral key mapping to another Instance:
      Normal numeric keys mapping to Instances will be treated as children if the object being created, and will be
      parented to it. This allows nice recursive calls to Create to create a whole hierarchy of objects without a
      need for temporary variables to store references to those objects.

3) A key which is a value returned from Create.Event( eventname ), and a value which is a function function
      The Create.E( string ) function provides a limited way to connect to signals inside of a Create hierarchy 
      for those who really want such a functionality. The name of the event whose name is passed to 
      Create.E( string )

4) A key which is the Create function itself, and a value which is a function
      The function will be run with the argument of the object itself after all other initialization of the object is 
      done by create. This provides a way to do arbitrary things involving the object from withing the create 
      hierarchy. 
      Note: This function is called SYNCHRONOUSLY, that means that you should only so initialization in
      it, not stuff which requires waiting, as the Create call will block until it returns. While waiting in the 
      constructor callback function is possible, it is probably not a good design choice.
      Note: Since the constructor function is called after all other initialization, a Create block cannot have two 
      constructor functions, as it would not be possible to call both of them last, also, this would be unnecessary.


Some example usages:

A simple example which uses the Create function to create a model object and assign two of it's properties.
local model = Create'Model'{
    Name = 'A New model',
    Parent = game.Workspace,
}


An example where a larger hierarchy of object is made. After the call the hierarchy will look like this:
Model_Container
 |-ObjectValue
 |  |
 |  `-BoolValueChild
 `-IntValue

local model = Create'Model'{
    Name = 'Model_Container',
    Create'ObjectValue'{
        Create'BoolValue'{
            Name = 'BoolValueChild',
        },
    },
    Create'IntValue'{},
}


An example using the event syntax:

local part = Create'Part'{
    [Create.E'Touched'] = function(part)
        print("I was touched by "..part.Name)
    end,	
}


An example using the general constructor syntax:

local model = Create'Part'{
    [Create] = function(this)
        print("Constructor running!")
        this.Name = GetGlobalFoosAndBars(this)
    end,
}


Note: It is also perfectly legal to save a reference to the function returned by a call Create, this will not cause
      any unexpected behavior. EG:
      local partCreatingFunction = Create'Part'
      local part = partCreatingFunction()
]]

--the Create function need to be created as a functor, not a function, in order to support the Create.E syntax, so it
--will be created in several steps rather than as a single function declaration.
local function Create_PrivImpl(objectType)
	if type(objectType) ~= 'string' then
		error("Argument of Create must be a string", 2)
	end
	--return the proxy function that gives us the nice Create'string'{data} syntax
	--The first function call is a function call using Lua's single-string-argument syntax
	--The second function call is using Lua's single-table-argument syntax
	--Both can be chained together for the nice effect.
	return function(dat)
		--default to nothing, to handle the no argument given case
		dat = dat or {}

		--make the object to mutate
		local obj = Instance.new(objectType)

		--stored constructor function to be called after other initialization
		local ctor = nil

		for k, v in pairs(dat) do
			--add property
			if type(k) == 'string' then
				obj[k] = v


			--add child
			elseif type(k) == 'number' then
				if type(v) ~= 'userdata' then
					error("Bad entry in Create body: Numeric keys must be paired with children, got a: "..type(v), 2)
				end
				v.Parent = obj


			--event connect
			elseif type(k) == 'table' and k.__eventname then
				if type(v) ~= 'function' then
					error("Bad entry in Create body: Key `[Create.E\'"..k.__eventname.."\']` must have a function value\
					       got: "..tostring(v), 2)
				end
				obj[k.__eventname]:connect(v)


			--define constructor function
			elseif k == t.Create then
				if type(v) ~= 'function' then
					error("Bad entry in Create body: Key `[Create]` should be paired with a constructor function, \
					       got: "..tostring(v), 2)
				elseif ctor then
					--ctor already exists, only one allowed
					error("Bad entry in Create body: Only one constructor function is allowed", 2)
				end
				ctor = v


			else
				error("Bad entry ("..tostring(k).." => "..tostring(v)..") in Create body", 2)
			end
		end

		--apply constructor function if it exists
		if ctor then
			ctor(obj)
		end

		--return the completed object
		return obj
	end
end

--now, create the functor:
t.Create = setmetatable({}, {__call = function(tb, ...) return Create_PrivImpl(...) end})

--and create the "Event.E" syntax stub. Really it's just a stub to construct a table which our Create
--function can recognize as special.
t.Create.E = function(eventName)
	return {__eventname = eventName}
end

-------------------------------------------------Create function End----------------------------------------------------




------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------Documentation Begin-----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

t.Help = 
	function(funcNameOrFunc) 
		--input argument can be a string or a function.  Should return a description (of arguments and expected side effects)
		if funcNameOrFunc == "DecodeJSON" or funcNameOrFunc == t.DecodeJSON then
			return "Function DecodeJSON.  " ..
			       "Arguments: (string).  " .. 
			       "Side effect: returns a table with all parsed JSON values" 
		end
		if funcNameOrFunc == "EncodeJSON" or funcNameOrFunc == t.EncodeJSON then
			return "Function EncodeJSON.  " ..
			       "Arguments: (table).  " .. 
			       "Side effect: returns a string composed of argument table in JSON data format" 
		end  
		if funcNameOrFunc == "MakeWedge" or funcNameOrFunc == t.MakeWedge then
			return "Function MakeWedge. " ..
			       "Arguments: (x, y, z, [default material]). " ..
			       "Description: Makes a wedge at location x, y, z. Sets cell x, y, z to default material if "..
			       "parameter is provided, if not sets cell x, y, z to be whatever material it previously was. "..
			       "Returns true if made a wedge, false if the cell remains a block "
		end
		if funcNameOrFunc == "SelectTerrainRegion" or funcNameOrFunc == t.SelectTerrainRegion then
			return "Function SelectTerrainRegion. " ..
			       "Arguments: (regionToSelect, color, selectEmptyCells, selectionParent). " ..
			       "Description: Selects all terrain via a series of selection boxes within the regionToSelect " ..
			       "(this should be a region3 value). The selection box color is detemined by the color argument " ..
			       "(should be a brickcolor value). SelectionParent is the parent that the selection model gets placed to (optional)." ..
			       "SelectEmptyCells is bool, when true will select all cells in the " ..
			       "region, otherwise we only select non-empty cells. Returns a function that can update the selection," ..
			       "arguments to said function are a new region3 to select, and the adornment color (color arg is optional). " ..
			       "Also returns a second function that takes no arguments and destroys the selection"
		end
		if funcNameOrFunc == "CreateSignal" or funcNameOrFunc == t.CreateSignal then
			return "Function CreateSignal. "..
			       "Arguments: None. "..
			       "Returns: The newly created Signal object. This object is identical to the RBXScriptSignal class "..
			       "used for events in Objects, but is a Lua-side object so it can be used to create custom events in"..
			       "Lua code. "..
			       "Methods of the Signal object: :connect, :wait, :fire, :disconnect. "..
			       "For more info you can pass the method name to the Help function, or view the wiki page "..
			       "for this library. EG: Help('Signal:connect')."
		end
		if funcNameOrFunc == "Signal:connect" then
			return "Method Signal:connect. "..
			       "Arguments: (function handler). "..
			       "Return: A connection object which can be used to disconnect the connection to this handler. "..
			       "Description: Connectes a handler function to this Signal, so that when |fire| is called the "..
			       "handler function will be called with the arguments passed to |fire|."
		end
		if funcNameOrFunc == "Signal:wait" then
			return "Method Signal:wait. "..
			       "Arguments: None. "..
			       "Returns: The arguments passed to the next call to |fire|. "..
			       "Description: This call does not return until the next call to |fire| is made, at which point it "..
			       "will return the values which were passed as arguments to that |fire| call."
		end
		if funcNameOrFunc == "Signal:fire" then
			return "Method Signal:fire. "..
			       "Arguments: Any number of arguments of any type. "..
			       "Returns: None. "..
			       "Description: This call will invoke any connected handler functions, and notify any waiting code "..
			       "attached to this Signal to continue, with the arguments passed to this function. Note: The calls "..
			       "to handlers are made asynchronously, so this call will return immediately regardless of how long "..
			       "it takes the connected handler functions to complete."
		end
		if funcNameOrFunc == "Signal:disconnect" then
			return "Method Signal:disconnect. "..
			       "Arguments: None. "..
			       "Returns: None. "..
			       "Description: This call disconnects all handlers attacched to this function, note however, it "..
			       "does NOT make waiting code continue, as is the behavior of normal Roblox events. This method "..
			       "can also be called on the connection object which is returned from Signal:connect to only "..
			       "disconnect a single handler, as opposed to this method, which will disconnect all handlers."
		end
		if funcNameOrFunc == "Create" then
			return "Function Create. "..
			       "Arguments: A table containing information about how to construct a collection of objects. "..
			       "Returns: The constructed objects. "..
			       "Descrition: Create is a very powerfull function, whose description is too long to fit here, and "..
			       "is best described via example, please see the wiki page for a description of how to use it."
		end
	end
	
--------------------------------------------Documentation Ends----------------------------------------------------------





















local t = {}

local function ScopedConnect(parentInstance, instance, event, signalFunc, syncFunc, removeFunc)
	local eventConnection = nil

	--Connection on parentInstance is scoped by parentInstance (when destroyed, it goes away)
	local tryConnect = function()
		if game:IsAncestorOf(parentInstance) then
			--Entering the world, make sure we are connected/synced
			if not eventConnection then
				eventConnection = instance[event]:connect(signalFunc)
				if syncFunc then syncFunc() end
			end
		else
			--Probably leaving the world, so disconnect for now
			if eventConnection then
				eventConnection:disconnect()
				if removeFunc then removeFunc() end
			end
		end
	end

	--Hook it up to ancestryChanged signal
	local connection = parentInstance.AncestryChanged:connect(tryConnect)
	
	--Now connect us if we're already in the world
	tryConnect()
	
	return connection
end

local function getScreenGuiAncestor(instance)
	local localInstance = instance
	while localInstance and not localInstance:IsA("ScreenGui") do
		localInstance = localInstance.Parent
	end
	return localInstance
end

local function CreateButtons(frame, buttons, yPos, ySize)
	local buttonNum = 1
	local buttonObjs = {}
	for i, obj in ipairs(buttons) do 
		local button = Instance.new("TextButton")
		button.Name = "Button" .. buttonNum
		button.Font = Enum.Font.Arial
		button.FontSize = Enum.FontSize.Size18
		button.AutoButtonColor = true
		button.Modal = true
		if obj["Style"] then
			button.Style = obj.Style
		else
			button.Style = Enum.ButtonStyle.RobloxButton
		end
		if obj["ZIndex"] then
			button.ZIndex = obj.ZIndex
		end
		button.Text = obj.Text
		button.TextColor3 = Color3.new(1,1,1)
		button.MouseButton1Click:connect(obj.Function)
		button.Parent = frame
		buttonObjs[buttonNum] = button

		buttonNum = buttonNum + 1
	end
	local numButtons = buttonNum-1

	if numButtons == 1 then
		frame.Button1.Position = UDim2.new(0.35, 0, yPos.Scale, yPos.Offset)
		frame.Button1.Size = UDim2.new(.4,0,ySize.Scale, ySize.Offset)
	elseif numButtons == 2 then
		frame.Button1.Position = UDim2.new(0.1, 0, yPos.Scale, yPos.Offset)
		frame.Button1.Size = UDim2.new(.8/3,0, ySize.Scale, ySize.Offset)

		frame.Button2.Position = UDim2.new(0.55, 0, yPos.Scale, yPos.Offset)
		frame.Button2.Size = UDim2.new(.35,0, ySize.Scale, ySize.Offset)
	elseif numButtons >= 3 then
		local spacing = .1 / numButtons
		local buttonSize = .9 / numButtons

		buttonNum = 1
		while buttonNum <= numButtons do
			buttonObjs[buttonNum].Position = UDim2.new(spacing*buttonNum + (buttonNum-1) * buttonSize, 0, yPos.Scale, yPos.Offset)
			buttonObjs[buttonNum].Size = UDim2.new(buttonSize, 0, ySize.Scale, ySize.Offset)
			buttonNum = buttonNum + 1
		end
	end
end

local function setSliderPos(newAbsPosX,slider,sliderPosition,bar,steps)

	local newStep = steps - 1 --otherwise we really get one more step than we want
	local relativePosX = math.min(1, math.max(0, (newAbsPosX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X ))
	local wholeNum, remainder = math.modf(relativePosX * newStep)
	if remainder > 0.5 then
		wholeNum = wholeNum + 1
	end
	relativePosX = wholeNum/newStep

	local result = math.ceil(relativePosX * newStep)
	if sliderPosition.Value ~= (result + 1) then --only update if we moved a step
		sliderPosition.Value = result + 1
		slider.Position = UDim2.new(relativePosX,-slider.AbsoluteSize.X/2,slider.Position.Y.Scale,slider.Position.Y.Offset)
	end
	
end

local function cancelSlide(areaSoak)
	areaSoak.Visible = false
	if areaSoakMouseMoveCon then areaSoakMouseMoveCon:disconnect() end
end

t.CreateStyledMessageDialog = function(title, message, style, buttons)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, 0, 0, 165)
	frame.Position = UDim2.new(0.25, 0, 0.5, -72.5)
	frame.Name = "MessageDialog"
	frame.Active = true
	frame.Style = Enum.FrameStyle.RobloxRound	
	
	local styleImage = Instance.new("ImageLabel")
	styleImage.Name = "StyleImage"
	styleImage.BackgroundTransparency = 1
	styleImage.Position = UDim2.new(0,5,0,15)
	if style == "error" or style == "Error" then
		styleImage.Size = UDim2.new(0, 71, 0, 71)
		styleImage.Image = "http://www.roblox.com/asset/?id=42565285"
	elseif style == "notify" or style == "Notify" then
		styleImage.Size = UDim2.new(0, 71, 0, 71)
		styleImage.Image = "http://www.roblox.com/asset/?id=42604978"
	elseif style == "confirm" or style == "Confirm" then
		styleImage.Size = UDim2.new(0, 74, 0, 76)
		styleImage.Image = "http://www.roblox.com/asset/?id=42557901"
	else
		return t.CreateMessageDialog(title,message,buttons)
	end
	styleImage.Parent = frame
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = title
	titleLabel.TextStrokeTransparency = 0
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	titleLabel.Position = UDim2.new(0, 80, 0, 0)
	titleLabel.Size = UDim2.new(1, -80, 0, 40)
	titleLabel.Font = Enum.Font.ArialBold
	titleLabel.FontSize = Enum.FontSize.Size36
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Text = message
	messageLabel.TextStrokeTransparency = 0
	messageLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	messageLabel.Position = UDim2.new(0.025, 80, 0, 45)
	messageLabel.Size = UDim2.new(0.95, -80, 0, 55)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Arial
	messageLabel.FontSize = Enum.FontSize.Size18
	messageLabel.TextWrap = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.Parent = frame

	CreateButtons(frame, buttons, UDim.new(0, 105), UDim.new(0, 40) )

	return frame
end

t.CreateMessageDialog = function(title, message, buttons)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, 0, 0.5, 0)
	frame.Position = UDim2.new(0.25, 0, 0.25, 0)
	frame.Name = "MessageDialog"
	frame.Active = true
	frame.Style = Enum.FrameStyle.RobloxRound

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Text = title
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
	titleLabel.Font = Enum.Font.ArialBold
	titleLabel.FontSize = Enum.FontSize.Size36
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.new(221/255,221/255,221/255)
	messageLabel.Position = UDim2.new(0.025, 0, 0.175, 0)
	messageLabel.Size = UDim2.new(0.95, 0, .55, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Arial
	messageLabel.FontSize = Enum.FontSize.Size18
	messageLabel.TextWrap = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.Parent = frame

	CreateButtons(frame, buttons, UDim.new(0.8,0), UDim.new(0.15, 0))

	return frame
end

t.CreateDropDownMenu = function(items, onSelect, forRoblox, whiteSkin, baseZ)
	local baseZIndex = 0
	if (type(baseZ) == "number") then
		baseZIndex = baseZ
	end
	local width = UDim.new(0, 100)
	local height = UDim.new(0, 32)

	local xPos = 0.055
	local frame = Instance.new("Frame")
	local textColor = Color3.new(1,1,1)
	if (whiteSkin) then
		textColor = Color3.new(0.5, 0.5, 0.5)
	end
	frame.Name = "DropDownMenu"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(width, height)

	local dropDownMenu = Instance.new("TextButton")
	dropDownMenu.Name = "DropDownMenuButton"
	dropDownMenu.TextWrap = true
	dropDownMenu.TextColor3 = textColor
	dropDownMenu.Text = "Choose One"
	dropDownMenu.Font = Enum.Font.ArialBold
	dropDownMenu.FontSize = Enum.FontSize.Size18
	dropDownMenu.TextXAlignment = Enum.TextXAlignment.Left
	dropDownMenu.TextYAlignment = Enum.TextYAlignment.Center
	dropDownMenu.BackgroundTransparency = 1
	dropDownMenu.AutoButtonColor = true
	if (whiteSkin) then
		dropDownMenu.Style = Enum.ButtonStyle.RobloxRoundDropdownButton
	else
		dropDownMenu.Style = Enum.ButtonStyle.RobloxButton
	end
	dropDownMenu.Size = UDim2.new(1,0,1,0)
	dropDownMenu.Parent = frame
	dropDownMenu.ZIndex = 2 + baseZIndex

	local dropDownIcon = Instance.new("ImageLabel")
	dropDownIcon.Name = "Icon"
	dropDownIcon.Active = false
	if (whiteSkin) then
		dropDownIcon.Image = "rbxasset://textures/ui/dropdown_arrow.png"
		dropDownIcon.Size = UDim2.new(0,16,0,12)
		dropDownIcon.Position = UDim2.new(1,-17,0.5, -6)
	else
		dropDownIcon.Image = "http://www.roblox.com/asset/?id=45732894"
		dropDownIcon.Size = UDim2.new(0,11,0,6)
		dropDownIcon.Position = UDim2.new(1,-11,0.5, -2)
	end
	dropDownIcon.BackgroundTransparency = 1
	dropDownIcon.Parent = dropDownMenu
	dropDownIcon.ZIndex = 2 + baseZIndex
	
	local itemCount = #items
	local dropDownItemCount = #items
	local useScrollButtons = false
	if dropDownItemCount > 6 then
		useScrollButtons = true
		dropDownItemCount = 6
	end
	
	local droppedDownMenu = Instance.new("TextButton")
	droppedDownMenu.Name = "List"
	droppedDownMenu.Text = ""
	droppedDownMenu.BackgroundTransparency = 1
	--droppedDownMenu.AutoButtonColor = true
	if (whiteSkin) then
		droppedDownMenu.Style = Enum.ButtonStyle.RobloxRoundDropdownButton
	else
		droppedDownMenu.Style = Enum.ButtonStyle.RobloxButton
	end
	droppedDownMenu.Visible = false
	droppedDownMenu.Active = true	--Blocks clicks
	droppedDownMenu.Position = UDim2.new(0,0,0,0)
	droppedDownMenu.Size = UDim2.new(1,0, (1 + dropDownItemCount)*.8, 0)
	droppedDownMenu.Parent = frame
	droppedDownMenu.ZIndex = 2 + baseZIndex

	local choiceButton = Instance.new("TextButton")
	choiceButton.Name = "ChoiceButton"
	choiceButton.BackgroundTransparency = 1
	choiceButton.BorderSizePixel = 0
	choiceButton.Text = "ReplaceMe"
	choiceButton.TextColor3 = textColor
	choiceButton.TextXAlignment = Enum.TextXAlignment.Left
	choiceButton.TextYAlignment = Enum.TextYAlignment.Center
	choiceButton.BackgroundColor3 = Color3.new(1, 1, 1)
	choiceButton.Font = Enum.Font.Arial
	choiceButton.FontSize = Enum.FontSize.Size18
	if useScrollButtons then
		choiceButton.Size = UDim2.new(1,-13, .8/((dropDownItemCount + 1)*.8),0) 
	else
		choiceButton.Size = UDim2.new(1, 0, .8/((dropDownItemCount + 1)*.8),0) 
	end
	choiceButton.TextWrap = true
	choiceButton.ZIndex = 2 + baseZIndex

	local areaSoak = Instance.new("TextButton")
	areaSoak.Name = "AreaSoak"
	areaSoak.Text = ""
	areaSoak.BackgroundTransparency = 1
	areaSoak.Active = true
	areaSoak.Size = UDim2.new(1,0,1,0)
	areaSoak.Visible = false
	areaSoak.ZIndex = 3 + baseZIndex

	local dropDownSelected = false

	local scrollUpButton 
	local scrollDownButton
	local scrollMouseCount = 0

	local setZIndex = function(baseZIndex)
		droppedDownMenu.ZIndex = baseZIndex +1
		if scrollUpButton then
			scrollUpButton.ZIndex = baseZIndex + 3
		end
		if scrollDownButton then
			scrollDownButton.ZIndex = baseZIndex + 3
		end
		
		local children = droppedDownMenu:GetChildren()
		if children then
			for i, child in ipairs(children) do
				if child.Name == "ChoiceButton" then
					child.ZIndex = baseZIndex + 2
				elseif child.Name == "ClickCaptureButton" then
					child.ZIndex = baseZIndex
				end
			end
		end
	end

	local scrollBarPosition = 1
	local updateScroll = function()
		if scrollUpButton then
			scrollUpButton.Active = scrollBarPosition > 1 
		end
		if scrollDownButton then
			scrollDownButton.Active = scrollBarPosition + dropDownItemCount <= itemCount 
		end

		local children = droppedDownMenu:GetChildren()
		if not children then return end

		local childNum = 1			
		for i, obj in ipairs(children) do
			if obj.Name == "ChoiceButton" then
				if childNum < scrollBarPosition or childNum >= scrollBarPosition + dropDownItemCount then
					obj.Visible = false
				else
					obj.Position = UDim2.new(0,0,((childNum-scrollBarPosition+1)*.8)/((dropDownItemCount+1)*.8),0)
					obj.Visible = true
				end
				obj.TextColor3 = textColor
				obj.BackgroundTransparency = 1

				childNum = childNum + 1
			end
		end
	end
	local toggleVisibility = function()
		dropDownSelected = not dropDownSelected

		areaSoak.Visible = not areaSoak.Visible
		dropDownMenu.Visible = not dropDownSelected
		droppedDownMenu.Visible = dropDownSelected
		if dropDownSelected then
			setZIndex(4 + baseZIndex)
		else
			setZIndex(2 + baseZIndex)
		end
		if useScrollButtons then
			updateScroll()
		end
	end
	droppedDownMenu.MouseButton1Click:connect(toggleVisibility)

	local updateSelection = function(text)
		local foundItem = false
		local children = droppedDownMenu:GetChildren()
		local childNum = 1
		if children then
			for i, obj in ipairs(children) do
				if obj.Name == "ChoiceButton" then
					if obj.Text == text then
						obj.Font = Enum.Font.ArialBold
						foundItem = true			
						scrollBarPosition = childNum						
						if (whiteSkin) then
							obj.TextColor3 = Color3.new(90/255,142/255,233/255)
						end
					else
						obj.Font = Enum.Font.Arial
						if (whiteSkin) then
							obj.TextColor3 = textColor
						end
					end
					childNum = childNum + 1
				end
			end
		end
		if not text then
			dropDownMenu.Text = "Choose One"
			scrollBarPosition = 1
		else
			if not foundItem then
				error("Invalid Selection Update -- " .. text)
			end

			if scrollBarPosition + dropDownItemCount > itemCount + 1 then
				scrollBarPosition = itemCount - dropDownItemCount + 1
			end

			dropDownMenu.Text = text
		end
	end
	
	local function scrollDown()
		if scrollBarPosition + dropDownItemCount <= itemCount then
			scrollBarPosition = scrollBarPosition + 1
			updateScroll()
			return true
		end
		return false
	end
	local function scrollUp()
		if scrollBarPosition > 1 then
			scrollBarPosition = scrollBarPosition - 1
			updateScroll()
			return true
		end
		return false
	end
	
	if useScrollButtons then
		--Make some scroll buttons
		scrollUpButton = Instance.new("ImageButton")
		scrollUpButton.Name = "ScrollUpButton"
		scrollUpButton.BackgroundTransparency = 1
		scrollUpButton.Image = "rbxasset://textures/ui/scrollbuttonUp.png"
		scrollUpButton.Size = UDim2.new(0,17,0,17) 
		scrollUpButton.Position = UDim2.new(1,-11,(1*.8)/((dropDownItemCount+1)*.8),0)
		scrollUpButton.MouseButton1Click:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollUpButton.MouseLeave:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollUpButton.MouseButton1Down:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
	
				scrollUp()
				local val = scrollMouseCount
				wait(0.5)
				while val == scrollMouseCount do
					if scrollUp() == false then
						break
					end
					wait(0.1)
				end				
			end)

		scrollUpButton.Parent = droppedDownMenu

		scrollDownButton = Instance.new("ImageButton")
		scrollDownButton.Name = "ScrollDownButton"
		scrollDownButton.BackgroundTransparency = 1
		scrollDownButton.Image = "rbxasset://textures/ui/scrollbuttonDown.png"
		scrollDownButton.Size = UDim2.new(0,17,0,17) 
		scrollDownButton.Position = UDim2.new(1,-11,1,-11)
		scrollDownButton.Parent = droppedDownMenu
		scrollDownButton.MouseButton1Click:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollDownButton.MouseLeave:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1
			end)
		scrollDownButton.MouseButton1Down:connect(
			function()
				scrollMouseCount = scrollMouseCount + 1

				scrollDown()
				local val = scrollMouseCount
				wait(0.5)
				while val == scrollMouseCount do
					if scrollDown() == false then
						break
					end
					wait(0.1)
				end				
			end)	

		local scrollbar = Instance.new("ImageLabel")
		scrollbar.Name = "ScrollBar"
		scrollbar.Image = "rbxasset://textures/ui/scrollbar.png"
		scrollbar.BackgroundTransparency = 1
		scrollbar.Size = UDim2.new(0, 18, (dropDownItemCount*.8)/((dropDownItemCount+1)*.8), -(17) - 11 - 4)
		scrollbar.Position = UDim2.new(1,-11,(1*.8)/((dropDownItemCount+1)*.8),17+2)
		scrollbar.Parent = droppedDownMenu
	end

	for i,item in ipairs(items) do
		-- needed to maintain local scope for items in event listeners below
		local button = choiceButton:clone()
		if forRoblox then
			button.RobloxLocked = true
		end		
		button.Text = item
		button.Parent = droppedDownMenu
		if (whiteSkin) then
			button.TextColor3 = textColor
		end

		button.MouseButton1Click:connect(function()
			--Remove Highlight
			if (not whiteSkin) then
				button.TextColor3 = Color3.new(1,1,1)
			end
			button.BackgroundTransparency = 1

			updateSelection(item)
			onSelect(item)

			toggleVisibility()
		end)
		button.MouseEnter:connect(function()
			--Add Highlight	
			if (not whiteSkin) then
				button.TextColor3 = Color3.new(0,0,0)
			end
			button.BackgroundTransparency = 0
		end)

		button.MouseLeave:connect(function()
			--Remove Highlight
			if (not whiteSkin) then
				button.TextColor3 = Color3.new(1,1,1)
			end
			button.BackgroundTransparency = 1
		end)
	end

	--This does the initial layout of the buttons	
	updateScroll()
	
	frame.AncestryChanged:connect(function(child,parent)
		if parent == nil then
			areaSoak.Parent = nil
		else
			areaSoak.Parent = getScreenGuiAncestor(frame)
		end
	end)

	dropDownMenu.MouseButton1Click:connect(toggleVisibility)
	areaSoak.MouseButton1Click:connect(toggleVisibility)
	return frame, updateSelection
end

t.CreatePropertyDropDownMenu = function(instance, property, enum)

	local items = enum:GetEnumItems()
	local names = {}
	local nameToItem = {}
	for i,obj in ipairs(items) do
		names[i] = obj.Name
		nameToItem[obj.Name] = obj
	end

	local frame
	local updateSelection
	frame, updateSelection = t.CreateDropDownMenu(names, function(text) instance[property] = nameToItem[text] end)

	ScopedConnect(frame, instance, "Changed", 
		function(prop)
			if prop == property then
				updateSelection(instance[property].Name)
			end
		end,
		function()
			updateSelection(instance[property].Name)
		end)

	return frame
end

t.GetFontHeight = function(font, fontSize)
	if font == nil or fontSize == nil then
		error("Font and FontSize must be non-nil")
	end

	if font == Enum.Font.Legacy then
		if fontSize == Enum.FontSize.Size8 then
			return 12
		elseif fontSize == Enum.FontSize.Size9 then
			return 14
		elseif fontSize == Enum.FontSize.Size10 then
			return 15
		elseif fontSize == Enum.FontSize.Size11 then
			return 17
		elseif fontSize == Enum.FontSize.Size12 then
			return 18
		elseif fontSize == Enum.FontSize.Size14 then
			return 21
		elseif fontSize == Enum.FontSize.Size18 then
			return 27
		elseif fontSize == Enum.FontSize.Size24 then
			return 36
		elseif fontSize == Enum.FontSize.Size36 then
			return 54
		elseif fontSize == Enum.FontSize.Size48 then
			return 72
		else
			error("Unknown FontSize")
		end
	elseif font == Enum.Font.Arial or font == Enum.Font.ArialBold then
		if fontSize == Enum.FontSize.Size8 then
			return 8
		elseif fontSize == Enum.FontSize.Size9 then
			return 9
		elseif fontSize == Enum.FontSize.Size10 then
			return 10
		elseif fontSize == Enum.FontSize.Size11 then
			return 11
		elseif fontSize == Enum.FontSize.Size12 then
			return 12
		elseif fontSize == Enum.FontSize.Size14 then
			return 14
		elseif fontSize == Enum.FontSize.Size18 then
			return 18
		elseif fontSize == Enum.FontSize.Size24 then
			return 24
		elseif fontSize == Enum.FontSize.Size36 then
			return 36
		elseif fontSize == Enum.FontSize.Size48 then
			return 48
		else
			error("Unknown FontSize")
		end
	else
		error("Unknown Font " .. font)
	end
end

local function layoutGuiObjectsHelper(frame, guiObjects, settingsTable)
	local totalPixels = frame.AbsoluteSize.Y
	local pixelsRemaining = frame.AbsoluteSize.Y
	for i, child in ipairs(guiObjects) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			local isLabel = child:IsA("TextLabel")
			if isLabel then
				pixelsRemaining = pixelsRemaining - settingsTable["TextLabelPositionPadY"]
			else
				pixelsRemaining = pixelsRemaining - settingsTable["TextButtonPositionPadY"]
			end
			child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, totalPixels - pixelsRemaining)
			child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, pixelsRemaining)

			if child.TextFits and child.TextBounds.Y < pixelsRemaining then
				child.Visible = true
				if isLabel then
					child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, child.TextBounds.Y + settingsTable["TextLabelSizePadY"])
				else 
					child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, child.TextBounds.Y + settingsTable["TextButtonSizePadY"])
				end

				while not child.TextFits do
					child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, child.AbsoluteSize.Y + 1)
				end
				pixelsRemaining = pixelsRemaining - child.AbsoluteSize.Y		

				if isLabel then
					pixelsRemaining = pixelsRemaining - settingsTable["TextLabelPositionPadY"]
				else
					pixelsRemaining = pixelsRemaining - settingsTable["TextButtonPositionPadY"]
				end
			else
				child.Visible = false
				pixelsRemaining = -1
			end			

		else
			--GuiObject
			child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, totalPixels - pixelsRemaining)
			pixelsRemaining = pixelsRemaining - child.AbsoluteSize.Y
			child.Visible = (pixelsRemaining >= 0)
		end
	end
end

t.LayoutGuiObjects = function(frame, guiObjects, settingsTable)
	if not frame:IsA("GuiObject") then
		error("Frame must be a GuiObject")
	end
	for i, child in ipairs(guiObjects) do
		if not child:IsA("GuiObject") then
			error("All elements that are layed out must be of type GuiObject")
		end
	end

	if not settingsTable then
		settingsTable = {}
	end

	if not settingsTable["TextLabelSizePadY"] then
		settingsTable["TextLabelSizePadY"] = 0
	end
	if not settingsTable["TextLabelPositionPadY"] then
		settingsTable["TextLabelPositionPadY"] = 0
	end
	if not settingsTable["TextButtonSizePadY"] then
		settingsTable["TextButtonSizePadY"] = 12
	end
	if not settingsTable["TextButtonPositionPadY"] then
		settingsTable["TextButtonPositionPadY"] = 2
	end

	--Wrapper frame takes care of styled objects
	local wrapperFrame = Instance.new("Frame")
	wrapperFrame.Name = "WrapperFrame"
	wrapperFrame.BackgroundTransparency = 1
	wrapperFrame.Size = UDim2.new(1,0,1,0)
	wrapperFrame.Parent = frame

	for i, child in ipairs(guiObjects) do
		child.Parent = wrapperFrame
	end

	local recalculate = function()
		wait()
		layoutGuiObjectsHelper(wrapperFrame, guiObjects, settingsTable)
	end
	
	frame.Changed:connect(
		function(prop)
			if prop == "AbsoluteSize" then
				--Wait a heartbeat for it to sync in
				recalculate(nil)
			end
		end)
	frame.AncestryChanged:connect(recalculate)

	layoutGuiObjectsHelper(wrapperFrame, guiObjects, settingsTable)
end


t.CreateSlider = function(steps,width,position)
	local sliderGui = Instance.new("Frame")
	sliderGui.Size = UDim2.new(1,0,1,0)
	sliderGui.BackgroundTransparency = 1
	sliderGui.Name = "SliderGui"
	
	local sliderSteps = Instance.new("IntValue")
	sliderSteps.Name = "SliderSteps"
	sliderSteps.Value = steps
	sliderSteps.Parent = sliderGui
	
	local areaSoak = Instance.new("TextButton")
	areaSoak.Name = "AreaSoak"
	areaSoak.Text = ""
	areaSoak.BackgroundTransparency = 1
	areaSoak.Active = false
	areaSoak.Size = UDim2.new(1,0,1,0)
	areaSoak.Visible = false
	areaSoak.ZIndex = 4
	
	sliderGui.AncestryChanged:connect(function(child,parent)
		if parent == nil then
			areaSoak.Parent = nil
		else
			areaSoak.Parent = getScreenGuiAncestor(sliderGui)
		end
	end)
	
	local sliderPosition = Instance.new("IntValue")
	sliderPosition.Name = "SliderPosition"
	sliderPosition.Value = 0
	sliderPosition.Parent = sliderGui
	
	local id = math.random(1,100)
	
	local bar = Instance.new("TextButton")
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Name = "Bar"
	bar.BackgroundColor3 = Color3.new(0,0,0)
	if type(width) == "number" then
		bar.Size = UDim2.new(0,width,0,5)
	else
		bar.Size = UDim2.new(0,200,0,5)
	end
	bar.BorderColor3 = Color3.new(95/255,95/255,95/255)
	bar.ZIndex = 2
	bar.Parent = sliderGui
	
	if position["X"] and position["X"]["Scale"] and position["X"]["Offset"] and position["Y"] and position["Y"]["Scale"] and position["Y"]["Offset"] then
		bar.Position = position
	end
	
	local slider = Instance.new("ImageButton")
	slider.Name = "Slider"
	slider.BackgroundTransparency = 1
	slider.Image = "rbxasset://textures/ui/Slider.png"
	slider.Position = UDim2.new(0,0,0.5,-10)
	slider.Size = UDim2.new(0,20,0,20)
	slider.ZIndex = 3
	slider.Parent = bar
	
	local areaSoakMouseMoveCon = nil
	
	areaSoak.MouseLeave:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	areaSoak.MouseButton1Up:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	
	slider.MouseButton1Down:connect(function()
		areaSoak.Visible = true
		if areaSoakMouseMoveCon then areaSoakMouseMoveCon:disconnect() end
		areaSoakMouseMoveCon = areaSoak.MouseMoved:connect(function(x,y)
			setSliderPos(x,slider,sliderPosition,bar,steps)
		end)
	end)
	
	slider.MouseButton1Up:connect(function() cancelSlide(areaSoak) end)
	
	sliderPosition.Changed:connect(function(prop)
		sliderPosition.Value = math.min(steps, math.max(1,sliderPosition.Value))
		local relativePosX = (sliderPosition.Value - 1) / (steps - 1)
		slider.Position = UDim2.new(relativePosX,-slider.AbsoluteSize.X/2,slider.Position.Y.Scale,slider.Position.Y.Offset)
	end)
	
	bar.MouseButton1Down:connect(function(x,y)
		setSliderPos(x,slider,sliderPosition,bar,steps)
	end)
	
	return sliderGui, sliderPosition, sliderSteps

end



t.CreateSliderNew = function(steps,width,position)
	local sliderGui = Instance.new("Frame")
	sliderGui.Size = UDim2.new(1,0,1,0)
	sliderGui.BackgroundTransparency = 1
	sliderGui.Name = "SliderGui"
	
	local sliderSteps = Instance.new("IntValue")
	sliderSteps.Name = "SliderSteps"
	sliderSteps.Value = steps
	sliderSteps.Parent = sliderGui
	
	local areaSoak = Instance.new("TextButton")
	areaSoak.Name = "AreaSoak"
	areaSoak.Text = ""
	areaSoak.BackgroundTransparency = 1
	areaSoak.Active = false
	areaSoak.Size = UDim2.new(1,0,1,0)
	areaSoak.Visible = false
	areaSoak.ZIndex = 6
	
	sliderGui.AncestryChanged:connect(function(child,parent)
		if parent == nil then
			areaSoak.Parent = nil
		else
			areaSoak.Parent = getScreenGuiAncestor(sliderGui)
		end
	end)
	
	local sliderPosition = Instance.new("IntValue")
	sliderPosition.Name = "SliderPosition"
	sliderPosition.Value = 0
	sliderPosition.Parent = sliderGui
	
	local id = math.random(1,100)
	
	local sliderBarImgHeight = 7
	local sliderBarCapImgWidth = 4

	local bar = Instance.new("ImageButton")
	bar.BackgroundTransparency = 1
	bar.Image = "rbxasset://textures/ui/Slider-BKG-Center.png"
	bar.Name = "Bar"
	local displayWidth = 200
	if type(width) == "number" then
		bar.Size = UDim2.new(0,width - (sliderBarCapImgWidth * 2),0,sliderBarImgHeight)
		displayWidth = width - (sliderBarCapImgWidth * 2)
	else
		bar.Size = UDim2.new(0,200,0,sliderBarImgHeight)
	end
	bar.ZIndex = 3
	bar.Parent = sliderGui	
	if position["X"] and position["X"]["Scale"] and position["X"]["Offset"] and position["Y"] and position["Y"]["Scale"] and position["Y"]["Offset"] then
		bar.Position = position
	end

	local barLeft = bar:clone()
	barLeft.Name = "BarLeft"
	barLeft.Image = "rbxasset://textures/ui/Slider-BKG-Left-Cap.png"
	barLeft.Size = UDim2.new(0, sliderBarCapImgWidth, 0, sliderBarImgHeight)
	barLeft.Position = UDim2.new(position.X.Scale, position.X.Offset - sliderBarCapImgWidth, position.Y.Scale, position.Y.Offset)
	barLeft.Parent = sliderGui	
	barLeft.ZIndex = 3

	local barRight = barLeft:clone()
	barRight.Name = "BarRight"
	barRight.Image = "rbxasset://textures/ui/Slider-BKG-Right-Cap.png"
	barRight.Position = UDim2.new(position.X.Scale, position.X.Offset + displayWidth, position.Y.Scale, position.Y.Offset)
	barRight.Parent = sliderGui	

	local fillLeft = barLeft:clone()
	fillLeft.Name = "FillLeft"
	fillLeft.Image = "rbxasset://textures/ui/Slider-Fill-Left-Cap.png"
	fillLeft.Parent = sliderGui	
	fillLeft.ZIndex = 4

	local fill = fillLeft:clone()
	fill.Name = "Fill"
	fill.Image = "rbxasset://textures/ui/Slider-Fill-Center.png"
	fill.Parent = bar	
	fill.ZIndex = 4
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.Size = UDim2.new(0.5, 0, 1, 0)


--	bar.Visible = false

	local slider = Instance.new("ImageButton")
	slider.Name = "Slider"
	slider.BackgroundTransparency = 1
	slider.Image = "rbxasset://textures/ui/slider_new_tab.png"
	slider.Position = UDim2.new(0,0,0.5,-14)
	slider.Size = UDim2.new(0,28,0,28)
	slider.ZIndex = 5
	slider.Parent = bar
	
	local areaSoakMouseMoveCon = nil
	
	areaSoak.MouseLeave:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	areaSoak.MouseButton1Up:connect(function()
		if areaSoak.Visible then
			cancelSlide(areaSoak)
		end
	end)
	
	slider.MouseButton1Down:connect(function()
		areaSoak.Visible = true
		if areaSoakMouseMoveCon then areaSoakMouseMoveCon:disconnect() end
		areaSoakMouseMoveCon = areaSoak.MouseMoved:connect(function(x,y)
			setSliderPos(x,slider,sliderPosition,bar,steps)
		end)
	end)
	
	slider.MouseButton1Up:connect(function() cancelSlide(areaSoak) end)
	
	sliderPosition.Changed:connect(function(prop)
		sliderPosition.Value = math.min(steps, math.max(1,sliderPosition.Value))
		local relativePosX = (sliderPosition.Value - 1) / (steps - 1)
		slider.Position = UDim2.new(relativePosX,-slider.AbsoluteSize.X/2,slider.Position.Y.Scale,slider.Position.Y.Offset)
		fill.Size = UDim2.new(relativePosX, 0, 1, 0)
	end)
	
	bar.MouseButton1Down:connect(function(x,y)
		setSliderPos(x,slider,sliderPosition,bar,steps)
	end)

	return sliderGui, sliderPosition, sliderSteps

end





t.CreateTrueScrollingFrame = function()
	local lowY = nil
	local highY = nil
	
	local dragCon = nil
	local upCon = nil

	local internalChange = false

	local descendantsChangeConMap = {}

	local scrollingFrame = Instance.new("Frame")
	scrollingFrame.Name = "ScrollingFrame"
	scrollingFrame.Active = true
	scrollingFrame.Size = UDim2.new(1,0,1,0)
	scrollingFrame.ClipsDescendants = true

	local controlFrame = Instance.new("Frame")
	controlFrame.Name = "ControlFrame"
	controlFrame.BackgroundTransparency = 1
	controlFrame.Size = UDim2.new(0,18,1,0)
	controlFrame.Position = UDim2.new(1,-20,0,0)
	controlFrame.Parent = scrollingFrame
	
	local scrollBottom = Instance.new("BoolValue")
	scrollBottom.Value = false
	scrollBottom.Name = "ScrollBottom"
	scrollBottom.Parent = controlFrame
	
	local scrollUp = Instance.new("BoolValue")
	scrollUp.Value = false
	scrollUp.Name = "scrollUp"
	scrollUp.Parent = controlFrame

	local scrollUpButton = Instance.new("TextButton")
	scrollUpButton.Name = "ScrollUpButton"
	scrollUpButton.Text = ""
	scrollUpButton.AutoButtonColor = false
	scrollUpButton.BackgroundColor3 = Color3.new(0,0,0)
	scrollUpButton.BorderColor3 = Color3.new(1,1,1)
	scrollUpButton.BackgroundTransparency = 0.5
	scrollUpButton.Size = UDim2.new(0,18,0,18)
	scrollUpButton.ZIndex = 2
	scrollUpButton.Parent = controlFrame
	for i = 1, 6 do
		local triFrame = Instance.new("Frame")
		triFrame.BorderColor3 = Color3.new(1,1,1)
		triFrame.Name = "tri" .. tostring(i)
		triFrame.ZIndex = 3
		triFrame.BackgroundTransparency = 0.5
		triFrame.Size = UDim2.new(0,12 - ((i -1) * 2),0,0)
		triFrame.Position = UDim2.new(0,3 + (i -1),0.5,2 - (i -1))
		triFrame.Parent = scrollUpButton
	end
	scrollUpButton.MouseEnter:connect(function()
		scrollUpButton.BackgroundTransparency = 0.1
		local upChildren = scrollUpButton:GetChildren()
		for i = 1, #upChildren do
			upChildren[i].BackgroundTransparency = 0.1
		end
	end)
	scrollUpButton.MouseLeave:connect(function()
		scrollUpButton.BackgroundTransparency = 0.5
		local upChildren = scrollUpButton:GetChildren()
		for i = 1, #upChildren do
			upChildren[i].BackgroundTransparency = 0.5
		end
	end)

	local scrollDownButton = scrollUpButton:clone()
	scrollDownButton.Name = "ScrollDownButton"
	scrollDownButton.Position = UDim2.new(0,0,1,-18)
	local downChildren = scrollDownButton:GetChildren()
	for i = 1, #downChildren do
		downChildren[i].Position = UDim2.new(0,3 + (i -1),0.5,-2 + (i - 1))
	end
	scrollDownButton.MouseEnter:connect(function()
		scrollDownButton.BackgroundTransparency = 0.1
		local downChildren = scrollDownButton:GetChildren()
		for i = 1, #downChildren do
			downChildren[i].BackgroundTransparency = 0.1
		end
	end)
	scrollDownButton.MouseLeave:connect(function()
		scrollDownButton.BackgroundTransparency = 0.5
		local downChildren = scrollDownButton:GetChildren()
		for i = 1, #downChildren do
			downChildren[i].BackgroundTransparency = 0.5
		end
	end)
	scrollDownButton.Parent = controlFrame
	
	local scrollTrack = Instance.new("Frame")
	scrollTrack.Name = "ScrollTrack"
	scrollTrack.BackgroundTransparency = 1
	scrollTrack.Size = UDim2.new(0,18,1,-38)
	scrollTrack.Position = UDim2.new(0,0,0,19)
	scrollTrack.Parent = controlFrame

	local scrollbar = Instance.new("TextButton")
	scrollbar.BackgroundColor3 = Color3.new(0,0,0)
	scrollbar.BorderColor3 = Color3.new(1,1,1)
	scrollbar.BackgroundTransparency = 0.5
	scrollbar.AutoButtonColor = false
	scrollbar.Text = ""
	scrollbar.Active = true
	scrollbar.Name = "ScrollBar"
	scrollbar.ZIndex = 2
	scrollbar.BackgroundTransparency = 0.5
	scrollbar.Size = UDim2.new(0, 18, 0.1, 0)
	scrollbar.Position = UDim2.new(0,0,0,0)
	scrollbar.Parent = scrollTrack

	local scrollNub = Instance.new("Frame")
	scrollNub.Name = "ScrollNub"
	scrollNub.BorderColor3 = Color3.new(1,1,1)
	scrollNub.Size = UDim2.new(0,10,0,0)
	scrollNub.Position = UDim2.new(0.5,-5,0.5,0)
	scrollNub.ZIndex = 2
	scrollNub.BackgroundTransparency = 0.5
	scrollNub.Parent = scrollbar

	local newNub = scrollNub:clone()
	newNub.Position = UDim2.new(0.5,-5,0.5,-2)
	newNub.Parent = scrollbar
	
	local lastNub = scrollNub:clone()
	lastNub.Position = UDim2.new(0.5,-5,0.5,2)
	lastNub.Parent = scrollbar

	scrollbar.MouseEnter:connect(function()
		scrollbar.BackgroundTransparency = 0.1
		scrollNub.BackgroundTransparency = 0.1
		newNub.BackgroundTransparency = 0.1
		lastNub.BackgroundTransparency = 0.1
	end)
	scrollbar.MouseLeave:connect(function()
		scrollbar.BackgroundTransparency = 0.5
		scrollNub.BackgroundTransparency = 0.5
		newNub.BackgroundTransparency = 0.5
		lastNub.BackgroundTransparency = 0.5
	end)

	local mouseDrag = Instance.new("ImageButton")
	mouseDrag.Active = false
	mouseDrag.Size = UDim2.new(1.5, 0, 1.5, 0)
	mouseDrag.AutoButtonColor = false
	mouseDrag.BackgroundTransparency = 1
	mouseDrag.Name = "mouseDrag"
	mouseDrag.Position = UDim2.new(-0.25, 0, -0.25, 0)
	mouseDrag.ZIndex = 10
	
	local function positionScrollBar(x,y,offset)
		local oldPos = scrollbar.Position

		if y < scrollTrack.AbsolutePosition.y then
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,0,0)
			return (oldPos ~= scrollbar.Position)
		end
		
		local relativeSize = scrollbar.AbsoluteSize.Y/scrollTrack.AbsoluteSize.Y

		if y > (scrollTrack.AbsolutePosition.y + scrollTrack.AbsoluteSize.y) then
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,1 - relativeSize,0)
			return (oldPos ~= scrollbar.Position)
		end
		local newScaleYPos = (y - scrollTrack.AbsolutePosition.y - offset)/scrollTrack.AbsoluteSize.y
		if newScaleYPos + relativeSize > 1 then
			newScaleYPos = 1 - relativeSize
			scrollBottom.Value = true
			scrollUp.Value = false
		elseif newScaleYPos <= 0 then
			newScaleYPos = 0
			scrollUp.Value = true
			scrollBottom.Value = false
		else
			scrollUp.Value = false
			scrollBottom.Value = false
		end
		scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,newScaleYPos,0)
		
		return (oldPos ~= scrollbar.Position)
	end

	local function drillDownSetHighLow(instance)
		if not instance or not instance:IsA("GuiObject") then return end
		if instance == controlFrame then return end
		if instance:IsDescendantOf(controlFrame) then return end
		if not instance.Visible then return end

		if lowY and lowY > instance.AbsolutePosition.Y then
			lowY = instance.AbsolutePosition.Y
		elseif not lowY then
			lowY = instance.AbsolutePosition.Y
		end
		if highY and highY < (instance.AbsolutePosition.Y + instance.AbsoluteSize.Y) then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		elseif not highY then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		end
		local children = instance:GetChildren()
		for i = 1, #children do
			drillDownSetHighLow(children[i])
		end
	end

	local function resetHighLow()
		local firstChildren = scrollingFrame:GetChildren()

		for i = 1, #firstChildren do
			drillDownSetHighLow(firstChildren[i])
		end
	end

	local function recalculate()
		internalChange = true

		local percentFrame = 0
		if scrollbar.Position.Y.Scale > 0 then
			if scrollbar.Visible then
				percentFrame = scrollbar.Position.Y.Scale/((scrollTrack.AbsoluteSize.Y - scrollbar.AbsoluteSize.Y)/scrollTrack.AbsoluteSize.Y)
			else
				percentFrame = 0
			end
		end
		if percentFrame > 0.99 then percentFrame = 1 end

		local hiddenYAmount = (scrollingFrame.AbsoluteSize.Y - (highY - lowY)) * percentFrame
		
		local guiChildren = scrollingFrame:GetChildren()
		for i = 1, #guiChildren do
			if guiChildren[i] ~= controlFrame then
				guiChildren[i].Position = UDim2.new(guiChildren[i].Position.X.Scale,guiChildren[i].Position.X.Offset,
					0, math.ceil(guiChildren[i].AbsolutePosition.Y) - math.ceil(lowY) + hiddenYAmount)
			end
		end

		lowY = nil
		highY = nil
		resetHighLow()
		internalChange = false
	end

	local function setSliderSizeAndPosition()
		if not highY or not lowY then return end

		local totalYSpan = math.abs(highY - lowY)
		if totalYSpan == 0 then
			scrollbar.Visible = false
			scrollDownButton.Visible = false
			scrollUpButton.Visible = false

			if dragCon then dragCon:disconnect() dragCon = nil end
			if upCon then upCon:disconnect() upCon = nil end
			return
		end

		local percentShown = scrollingFrame.AbsoluteSize.Y/totalYSpan
		if percentShown >= 1 then
			scrollbar.Visible = false
			scrollDownButton.Visible = false
			scrollUpButton.Visible = false
			recalculate()
		else
			scrollbar.Visible = true
			scrollDownButton.Visible = true
			scrollUpButton.Visible = true

			scrollbar.Size = UDim2.new(scrollbar.Size.X.Scale,scrollbar.Size.X.Offset,percentShown,0)
		end

		local percentPosition = (scrollingFrame.AbsolutePosition.Y - lowY)/totalYSpan
		scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,percentPosition,-scrollbar.AbsoluteSize.X/2)

		if scrollbar.AbsolutePosition.y < scrollTrack.AbsolutePosition.y then
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,0,0)
		end

		if (scrollbar.AbsolutePosition.y + scrollbar.AbsoluteSize.Y) > (scrollTrack.AbsolutePosition.y + scrollTrack.AbsoluteSize.y) then
			local relativeSize = scrollbar.AbsoluteSize.Y/scrollTrack.AbsoluteSize.Y
			scrollbar.Position = UDim2.new(scrollbar.Position.X.Scale,scrollbar.Position.X.Offset,1 - relativeSize,0)
		end
	end
	
	local buttonScrollAmountPixels = 7
	local reentrancyGuardScrollUp = false
	local function doScrollUp()
		if reentrancyGuardScrollUp then return end
		
		reentrancyGuardScrollUp = true
			if positionScrollBar(0,scrollbar.AbsolutePosition.Y - buttonScrollAmountPixels,0) then
				recalculate()
			end
		reentrancyGuardScrollUp = false
	end
	
	local reentrancyGuardScrollDown = false
	local function doScrollDown()
		if reentrancyGuardScrollDown then return end
		
		reentrancyGuardScrollDown = true
			if positionScrollBar(0,scrollbar.AbsolutePosition.Y + buttonScrollAmountPixels,0) then
				recalculate()
			end
		reentrancyGuardScrollDown = false
	end

	local function scrollUp(mouseYPos)
		if scrollUpButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local upCon
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				upCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollUp()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollUp()
				if mouseYPos and mouseYPos > scrollbar.AbsolutePosition.y then
					break
				end
				if not scrollUpButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end

	local function scrollDown(mouseYPos)
		if scrollDownButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local downCon
			downCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				downCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollDown()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollDown()
				if mouseYPos and mouseYPos < (scrollbar.AbsolutePosition.y + scrollbar.AbsoluteSize.x) then
					break
				end
				if not scrollDownButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end
	
	scrollbar.MouseButton1Down:connect(function(x,y)
		if scrollbar.Active then
			scrollStamp = tick()
			local mouseOffset = y - scrollbar.AbsolutePosition.y
			if dragCon then dragCon:disconnect() dragCon = nil end
			if upCon then upCon:disconnect() upCon = nil end
			local prevY = y
			local reentrancyGuardMouseScroll = false
			dragCon = mouseDrag.MouseMoved:connect(function(x,y)
				if reentrancyGuardMouseScroll then return end
				
				reentrancyGuardMouseScroll = true
					if positionScrollBar(x,y,mouseOffset) then
						recalculate()
					end
				reentrancyGuardMouseScroll = false
				
			end)
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				dragCon:disconnect(); dragCon = nil
				upCon:disconnect(); drag = nil
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
		end
	end)

	local scrollMouseCount = 0

	scrollUpButton.MouseButton1Down:connect(function()
		scrollUp()
	end)
	scrollUpButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)

	scrollDownButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	scrollDownButton.MouseButton1Down:connect(function()
		 scrollDown()
	end)
		
	scrollbar.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	
	local function heightCheck(instance)
		if highY and (instance.AbsolutePosition.Y + instance.AbsoluteSize.Y) > highY then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		elseif not highY then
			highY = instance.AbsolutePosition.Y + instance.AbsoluteSize.Y
		end
		setSliderSizeAndPosition()
	end
	
	local function highLowRecheck()
		local oldLowY = lowY
		local oldHighY = highY
		lowY = nil
		highY = nil
		resetHighLow()

		if (lowY ~= oldLowY) or (highY ~= oldHighY) then
			setSliderSizeAndPosition()
		end
	end

	local function descendantChanged(this, prop)
		if internalChange then return end
		if not this.Visible then return end

		if prop == "Size" or prop == "Position" then
			wait()
			highLowRecheck()
		end
	end

	scrollingFrame.DescendantAdded:connect(function(instance)
		if not instance:IsA("GuiObject") then return end

		if instance.Visible then
			wait() -- wait a heartbeat for sizes to reconfig
			highLowRecheck()
		end

		descendantsChangeConMap[instance] = instance.Changed:connect(function(prop) descendantChanged(instance, prop) end)
	end)

	scrollingFrame.DescendantRemoving:connect(function(instance)
		if not instance:IsA("GuiObject") then return end
		if descendantsChangeConMap[instance] then
			descendantsChangeConMap[instance]:disconnect()
			descendantsChangeConMap[instance] = nil
		end
		wait() -- wait a heartbeat for sizes to reconfig
		highLowRecheck()
	end)
	
	scrollingFrame.Changed:connect(function(prop)
		if prop == "AbsoluteSize" then
			if not highY or not lowY then return end

			highLowRecheck()
			setSliderSizeAndPosition()
		end
	end)

	return scrollingFrame, controlFrame
end

t.CreateScrollingFrame = function(orderList,scrollStyle)
	local frame = Instance.new("Frame")
	frame.Name = "ScrollingFrame"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1,0,1,0)
	
	local scrollUpButton = Instance.new("ImageButton")
	scrollUpButton.Name = "ScrollUpButton"
	scrollUpButton.BackgroundTransparency = 1
	scrollUpButton.Image = "rbxasset://textures/ui/scrollbuttonUp.png"
	scrollUpButton.Size = UDim2.new(0,17,0,17) 

	
	local scrollDownButton = Instance.new("ImageButton")
	scrollDownButton.Name = "ScrollDownButton"
	scrollDownButton.BackgroundTransparency = 1
	scrollDownButton.Image = "rbxasset://textures/ui/scrollbuttonDown.png"
	scrollDownButton.Size = UDim2.new(0,17,0,17) 
	
	local scrollbar = Instance.new("ImageButton")
	scrollbar.Name = "ScrollBar"
	scrollbar.Image = "rbxasset://textures/ui/scrollbar.png"
	scrollbar.BackgroundTransparency = 1
	scrollbar.Size = UDim2.new(0, 18, 0, 150)

	local scrollStamp = 0
		
	local scrollDrag = Instance.new("ImageButton")
	scrollDrag.Image = "http://www.roblox.com/asset/?id=61367186"
	scrollDrag.Size = UDim2.new(1, 0, 0, 16)
	scrollDrag.BackgroundTransparency = 1
	scrollDrag.Name = "ScrollDrag"
	scrollDrag.Active = true
	scrollDrag.Parent = scrollbar
	
	local mouseDrag = Instance.new("ImageButton")
	mouseDrag.Active = false
	mouseDrag.Size = UDim2.new(1.5, 0, 1.5, 0)
	mouseDrag.AutoButtonColor = false
	mouseDrag.BackgroundTransparency = 1
	mouseDrag.Name = "mouseDrag"
	mouseDrag.Position = UDim2.new(-0.25, 0, -0.25, 0)
	mouseDrag.ZIndex = 10

	local style = "simple"
	if scrollStyle and tostring(scrollStyle) then
		style = scrollStyle
	end
	
	local scrollPosition = 1
	local rowSize = 0
	local howManyDisplayed = 0
		
	local layoutGridScrollBar = function()
		howManyDisplayed = 0
		local guiObjects = {}
		if orderList then
			for i, child in ipairs(orderList) do
				if child.Parent == frame then
					table.insert(guiObjects, child)
				end
			end
		else
			local children = frame:GetChildren()
			if children then
				for i, child in ipairs(children) do 
					if child:IsA("GuiObject") then
						table.insert(guiObjects, child)
					end
				end
			end
		end
		if #guiObjects == 0 then
			scrollUpButton.Active = false
			scrollDownButton.Active = false
			scrollDrag.Active = false
			scrollPosition = 1
			return
		end

		if scrollPosition > #guiObjects then
			scrollPosition = #guiObjects
		end
		
		if scrollPosition < 1 then scrollPosition = 1 end
		
		local totalPixelsY = frame.AbsoluteSize.Y
		local pixelsRemainingY = frame.AbsoluteSize.Y
		
		local totalPixelsX  = frame.AbsoluteSize.X
		
		local xCounter = 0
		local rowSizeCounter = 0
		local setRowSize = true

		local pixelsBelowScrollbar = 0
		local pos = #guiObjects
		
		local currentRowY = 0

		pos = scrollPosition
		--count up from current scroll position to fill out grid
		while pos <= #guiObjects and pixelsBelowScrollbar < totalPixelsY do
			xCounter = xCounter + guiObjects[pos].AbsoluteSize.X
			--previous pos was the end of a row
			if xCounter >= totalPixelsX then
				pixelsBelowScrollbar = pixelsBelowScrollbar + currentRowY
				currentRowY = 0
				xCounter = guiObjects[pos].AbsoluteSize.X
			end
			if guiObjects[pos].AbsoluteSize.Y > currentRowY then
				currentRowY = guiObjects[pos].AbsoluteSize.Y
			end
			pos = pos + 1
		end
		--Count wherever current row left off
		pixelsBelowScrollbar = pixelsBelowScrollbar + currentRowY
		currentRowY = 0
		
		pos = scrollPosition - 1
		xCounter = 0
		
		--objects with varying X,Y dimensions can rarely cause minor errors
		--rechecking every new scrollPosition is necessary to avoid 100% of errors
		
		--count backwards from current scrollPosition to see if we can add more rows
		while pixelsBelowScrollbar + currentRowY < totalPixelsY and pos >= 1 do
			xCounter = xCounter + guiObjects[pos].AbsoluteSize.X
			rowSizeCounter = rowSizeCounter + 1
			if xCounter >= totalPixelsX then
				rowSize = rowSizeCounter - 1
				rowSizeCounter = 0
				xCounter = guiObjects[pos].AbsoluteSize.X
				if pixelsBelowScrollbar + currentRowY <= totalPixelsY then
					--It fits, so back up our scroll position
					pixelsBelowScrollbar = pixelsBelowScrollbar + currentRowY
					if scrollPosition <= rowSize then
						scrollPosition = 1 
						break
					else
						scrollPosition = scrollPosition - rowSize
					end
					currentRowY = 0
				else
					break
				end
			end
			
			if guiObjects[pos].AbsoluteSize.Y > currentRowY then
				currentRowY = guiObjects[pos].AbsoluteSize.Y
			end

			pos = pos - 1
		end
		
		--Do check last time if pos = 0
		if (pos == 0) and (pixelsBelowScrollbar + currentRowY <= totalPixelsY) then
			scrollPosition = 1
		end

		xCounter = 0
		--pos = scrollPosition
		rowSizeCounter = 0
		setRowSize = true
		local lastChildSize = 0
		
		local xOffset,yOffset = 0
		if guiObjects[1] then
			yOffset = math.ceil(math.floor(math.fmod(totalPixelsY,guiObjects[1].AbsoluteSize.X))/2)
			xOffset = math.ceil(math.floor(math.fmod(totalPixelsX,guiObjects[1].AbsoluteSize.Y))/2)
		end
		
		for i, child in ipairs(guiObjects) do
			if i < scrollPosition then
				--print("Hiding " .. child.Name)
				child.Visible = false
			else
				if pixelsRemainingY < 0 then
					--print("Out of Space " .. child.Name)
					child.Visible = false
				else
					--print("Laying out " .. child.Name)
					--GuiObject
					if setRowSize then rowSizeCounter = rowSizeCounter + 1 end
					if xCounter + child.AbsoluteSize.X >= totalPixelsX then
						if setRowSize then
							rowSize = rowSizeCounter - 1
							setRowSize = false
						end
						xCounter = 0
						pixelsRemainingY = pixelsRemainingY - child.AbsoluteSize.Y
					end
					child.Position = UDim2.new(child.Position.X.Scale,xCounter + xOffset, 0, totalPixelsY - pixelsRemainingY + yOffset)
					xCounter = xCounter + child.AbsoluteSize.X
					child.Visible = ((pixelsRemainingY - child.AbsoluteSize.Y) >= 0)
					if child.Visible then
						howManyDisplayed = howManyDisplayed + 1
					end
					lastChildSize = child.AbsoluteSize				
				end
			end
		end

		scrollUpButton.Active = (scrollPosition > 1)
		if lastChildSize == 0 then 
			scrollDownButton.Active = false
		else
			scrollDownButton.Active = ((pixelsRemainingY - lastChildSize.Y) < 0)
		end
		scrollDrag.Active = #guiObjects > howManyDisplayed
		scrollDrag.Visible = scrollDrag.Active
	end



	local layoutSimpleScrollBar = function()
		local guiObjects = {}	
		howManyDisplayed = 0
		
		if orderList then
			for i, child in ipairs(orderList) do
				if child.Parent == frame then
					table.insert(guiObjects, child)
				end
			end
		else
			local children = frame:GetChildren()
			if children then
				for i, child in ipairs(children) do 
					if child:IsA("GuiObject") then
						table.insert(guiObjects, child)
					end
				end
			end
		end
		if #guiObjects == 0 then
			scrollUpButton.Active = false
			scrollDownButton.Active = false
			scrollDrag.Active = false
			scrollPosition = 1
			return
		end

		if scrollPosition > #guiObjects then
			scrollPosition = #guiObjects
		end
		
		local totalPixels = frame.AbsoluteSize.Y
		local pixelsRemaining = frame.AbsoluteSize.Y

		local pixelsBelowScrollbar = 0
		local pos = #guiObjects
		while pixelsBelowScrollbar < totalPixels and pos >= 1 do
			if pos >= scrollPosition then
				pixelsBelowScrollbar = pixelsBelowScrollbar + guiObjects[pos].AbsoluteSize.Y
			else
				if pixelsBelowScrollbar + guiObjects[pos].AbsoluteSize.Y <= totalPixels then
					--It fits, so back up our scroll position
					pixelsBelowScrollbar = pixelsBelowScrollbar + guiObjects[pos].AbsoluteSize.Y
					if scrollPosition <= 1 then
						scrollPosition = 1
						break
					else
						--local ("Backing up ScrollPosition from -- " ..scrollPosition)
						scrollPosition = scrollPosition - 1
					end
				else
					break
				end
			end
			pos = pos - 1
		end

		pos = scrollPosition
		for i, child in ipairs(guiObjects) do
			if i < scrollPosition then
				--print("Hiding " .. child.Name)
				child.Visible = false
			else
				if pixelsRemaining < 0 then
					--print("Out of Space " .. child.Name)
					child.Visible = false
				else
					--print("Laying out " .. child.Name)
					--GuiObject
					child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, 0, totalPixels - pixelsRemaining)
					pixelsRemaining = pixelsRemaining - child.AbsoluteSize.Y
					if  (pixelsRemaining >= 0) then
						child.Visible = true
						howManyDisplayed = howManyDisplayed + 1
					else
						child.Visible = false
					end		
				end
			end
		end
		scrollUpButton.Active = (scrollPosition > 1)
		scrollDownButton.Active = (pixelsRemaining < 0)
		scrollDrag.Active = #guiObjects > howManyDisplayed
		scrollDrag.Visible = scrollDrag.Active
	end
	
		
	local moveDragger = function()	
		local guiObjects = 0
		local children = frame:GetChildren()
		if children then
			for i, child in ipairs(children) do 
				if child:IsA("GuiObject") then
					guiObjects = guiObjects + 1
				end
			end
		end
		
		if not scrollDrag.Parent then return end
		
		local dragSizeY = scrollDrag.Parent.AbsoluteSize.y * (1/(guiObjects - howManyDisplayed + 1))
		if dragSizeY < 16 then dragSizeY = 16 end
		scrollDrag.Size = UDim2.new(scrollDrag.Size.X.Scale,scrollDrag.Size.X.Offset,scrollDrag.Size.Y.Scale,dragSizeY)

		local relativeYPos = (scrollPosition - 1)/(guiObjects - (howManyDisplayed))
		if relativeYPos > 1 then relativeYPos = 1
		elseif relativeYPos < 0 then relativeYPos = 0 end
		local absYPos = 0
		
		if relativeYPos ~= 0 then
			absYPos = (relativeYPos * scrollbar.AbsoluteSize.y) - (relativeYPos * scrollDrag.AbsoluteSize.y)
		end
		
		scrollDrag.Position = UDim2.new(scrollDrag.Position.X.Scale,scrollDrag.Position.X.Offset,scrollDrag.Position.Y.Scale,absYPos)
	end

	local reentrancyGuard = false
	local recalculate = function()
		if reentrancyGuard then
			return
		end
		reentrancyGuard = true
		wait()
		local success, err = nil
		if style == "grid" then
			success, err = pcall(function() layoutGridScrollBar() end)
		elseif style == "simple" then
			success, err = pcall(function() layoutSimpleScrollBar() end)
		end
		if not success then print(err) end
		moveDragger()
		reentrancyGuard = false
	end
	
	local doScrollUp = function()
		scrollPosition = (scrollPosition) - rowSize
		if scrollPosition < 1 then scrollPosition = 1 end
		recalculate(nil)
	end
	
	local doScrollDown = function()
		scrollPosition = (scrollPosition) + rowSize
		recalculate(nil)
	end

	local scrollUp = function(mouseYPos)
		if scrollUpButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local upCon
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				upCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollUp()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollUp()
				if mouseYPos and mouseYPos > scrollDrag.AbsolutePosition.y then
					break
				end
				if not scrollUpButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end

	local scrollDown = function(mouseYPos)
		if scrollDownButton.Active then
			scrollStamp = tick()
			local current = scrollStamp
			local downCon
			downCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				downCon:disconnect()
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
			doScrollDown()
			wait(0.2)
			local t = tick()
			local w = 0.1
			while scrollStamp == current do
				doScrollDown()
				if mouseYPos and mouseYPos < (scrollDrag.AbsolutePosition.y + scrollDrag.AbsoluteSize.x) then
					break
				end
				if not scrollDownButton.Active then break end
				if tick()-t > 5 then
					w = 0
				elseif tick()-t > 2 then
					w = 0.06
				end
				wait(w)
			end
		end
	end
	
	local y = 0
	scrollDrag.MouseButton1Down:connect(function(x,y)
		if scrollDrag.Active then
			scrollStamp = tick()
			local mouseOffset = y - scrollDrag.AbsolutePosition.y
			local dragCon
			local upCon
			dragCon = mouseDrag.MouseMoved:connect(function(x,y)
				local barAbsPos = scrollbar.AbsolutePosition.y
				local barAbsSize = scrollbar.AbsoluteSize.y
				
				local dragAbsSize = scrollDrag.AbsoluteSize.y
				local barAbsOne = barAbsPos + barAbsSize - dragAbsSize
				y = y - mouseOffset
				y = y < barAbsPos and barAbsPos or y > barAbsOne and barAbsOne or y
				y = y - barAbsPos
				
				local guiObjects = 0
				local children = frame:GetChildren()
				if children then
					for i, child in ipairs(children) do 
						if child:IsA("GuiObject") then
							guiObjects = guiObjects + 1
						end
					end
				end
				
				local doublePercent = y/(barAbsSize-dragAbsSize)
				local rowDiff = rowSize
				local totalScrollCount = guiObjects - (howManyDisplayed - 1)
				local newScrollPosition = math.floor((doublePercent * totalScrollCount) + 0.5) + rowDiff
				if newScrollPosition < scrollPosition then
					rowDiff = -rowDiff
				end
				
				if newScrollPosition < 1 then
					newScrollPosition = 1
				end
				
				scrollPosition = newScrollPosition
				recalculate(nil)
			end)
			upCon = mouseDrag.MouseButton1Up:connect(function()
				scrollStamp = tick()
				mouseDrag.Parent = nil
				dragCon:disconnect(); dragCon = nil
				upCon:disconnect(); drag = nil
			end)
			mouseDrag.Parent = getScreenGuiAncestor(scrollbar)
		end
	end)

	local scrollMouseCount = 0

	scrollUpButton.MouseButton1Down:connect(
		function()
			scrollUp()
		end)
	scrollUpButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)


	scrollDownButton.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	scrollDownButton.MouseButton1Down:connect(
		function()
			scrollDown()	
		end)
		
	scrollbar.MouseButton1Up:connect(function()
		scrollStamp = tick()
	end)
	scrollbar.MouseButton1Down:connect(
		function(x,y)
			if y > (scrollDrag.AbsoluteSize.y + scrollDrag.AbsolutePosition.y) then
				scrollDown(y)
			elseif y < (scrollDrag.AbsolutePosition.y) then
				scrollUp(y)
			end
		end)


	frame.ChildAdded:connect(function()
		recalculate(nil)
	end)

	frame.ChildRemoved:connect(function()
		recalculate(nil)
	end)
	
	frame.Changed:connect(
		function(prop)
			if prop == "AbsoluteSize" then
				--Wait a heartbeat for it to sync in
				recalculate(nil)
			end
		end)
	frame.AncestryChanged:connect(function() recalculate(nil) end)

	return frame, scrollUpButton, scrollDownButton, recalculate, scrollbar
end
local function binaryGrow(min, max, fits)
	if min > max then
		return min
	end
	local biggestLegal = min

	while min <= max do
		local mid = min + math.floor((max - min) / 2)
		if fits(mid) and (biggestLegal == nil or biggestLegal < mid) then
			biggestLegal = mid
			
			--Try growing
			min = mid + 1
		else
			--Doesn't fit, shrink
			max = mid - 1
		end
	end
	return biggestLegal
end


local function binaryShrink(min, max, fits)
	if min > max then
		return min
	end
	local smallestLegal = max

	while min <= max do
		local mid = min + math.floor((max - min) / 2)
		if fits(mid) and (smallestLegal == nil or smallestLegal > mid) then
			smallestLegal = mid
			
			--It fits, shrink
			max = mid - 1			
		else
			--Doesn't fit, grow
			min = mid + 1
		end
	end
	return smallestLegal
end


local function getGuiOwner(instance)
	while instance ~= nil do
		if instance:IsA("ScreenGui") or instance:IsA("BillboardGui")  then
			return instance
		end
		instance = instance.Parent
	end
	return nil
end

t.AutoTruncateTextObject = function(textLabel)
	local text = textLabel.Text

	local fullLabel = textLabel:Clone()
	fullLabel.Name = "Full" .. textLabel.Name 
	fullLabel.BorderSizePixel = 0
	fullLabel.BackgroundTransparency = 0
	fullLabel.Text = text
	fullLabel.TextXAlignment = Enum.TextXAlignment.Center
	fullLabel.Position = UDim2.new(0,-3,0,0)
	fullLabel.Size = UDim2.new(0,100,1,0)
	fullLabel.Visible = false
	fullLabel.Parent = textLabel

	local shortText = nil
	local mouseEnterConnection = nil
	local mouseLeaveConnection= nil

	local checkForResize = function()
		if getGuiOwner(textLabel) == nil then
			return
		end
		textLabel.Text = text
		if textLabel.TextFits then 
			--Tear down the rollover if it is active
			if mouseEnterConnection then
				mouseEnterConnection:disconnect()
				mouseEnterConnection = nil
			end
			if mouseLeaveConnection then
				mouseLeaveConnection:disconnect()
				mouseLeaveConnection = nil
			end
		else
			local len = string.len(text)
			textLabel.Text = text .. "~"

			--Shrink the text
			local textSize = binaryGrow(0, len, 
				function(pos)
					if pos == 0 then
						textLabel.Text = "~"
					else
						textLabel.Text = string.sub(text, 1, pos) .. "~"
					end
					return textLabel.TextFits
				end)
			shortText = string.sub(text, 1, textSize) .. "~"
			textLabel.Text = shortText
			
			--Make sure the fullLabel fits
			if not fullLabel.TextFits then
				--Already too small, grow it really bit to start
				fullLabel.Size = UDim2.new(0, 10000, 1, 0)
			end
			
			--Okay, now try to binary shrink it back down
			local fullLabelSize = binaryShrink(textLabel.AbsoluteSize.X,fullLabel.AbsoluteSize.X, 
				function(size)
					fullLabel.Size = UDim2.new(0, size, 1, 0)
					return fullLabel.TextFits
				end)
			fullLabel.Size = UDim2.new(0,fullLabelSize+6,1,0)

			--Now setup the rollover effects, if they are currently off
			if mouseEnterConnection == nil then
				mouseEnterConnection = textLabel.MouseEnter:connect(
					function()
						fullLabel.ZIndex = textLabel.ZIndex + 1
						fullLabel.Visible = true
						--textLabel.Text = ""
					end)
			end
			if mouseLeaveConnection == nil then
				mouseLeaveConnection = textLabel.MouseLeave:connect(
					function()
						fullLabel.Visible = false
						--textLabel.Text = shortText
					end)
			end
		end
	end
	textLabel.AncestryChanged:connect(checkForResize)
	textLabel.Changed:connect(
		function(prop) 
			if prop == "AbsoluteSize" then 
				checkForResize() 	
			end 
		end)

	checkForResize()

	local function changeText(newText)
		text = newText
		fullLabel.Text = text
		checkForResize()
	end

	return textLabel, changeText
end

local function TransitionTutorialPages(fromPage, toPage, transitionFrame, currentPageValue)	
	if fromPage then
		fromPage.Visible = false
		if transitionFrame.Visible == false then
			transitionFrame.Size = fromPage.Size
			transitionFrame.Position = fromPage.Position
		end
	else
		if transitionFrame.Visible == false then
			transitionFrame.Size = UDim2.new(0.0,50,0.0,50)
			transitionFrame.Position = UDim2.new(0.5,-25,0.5,-25)
		end
	end
	transitionFrame.Visible = true
	currentPageValue.Value = nil

	local newsize, newPosition
	if toPage then
		--Make it visible so it resizes
		toPage.Visible = true

		newSize = toPage.Size
		newPosition = toPage.Position

		toPage.Visible = false
	else
		newSize = UDim2.new(0.0,50,0.0,50)
		newPosition = UDim2.new(0.5,-25,0.5,-25)
	end
	transitionFrame:TweenSizeAndPosition(newSize, newPosition, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.3, true,
		function(state)
			if state == Enum.TweenStatus.Completed then
				transitionFrame.Visible = false
				if toPage then
					toPage.Visible = true
					currentPageValue.Value = toPage
				end
			end
		end)
end

t.CreateTutorial = function(name, tutorialKey, createButtons)
	local frame = Instance.new("Frame")
	frame.Name = "Tutorial-" .. name
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(0.6, 0, 0.6, 0)
	frame.Position = UDim2.new(0.2, 0, 0.2, 0)

	local transitionFrame = Instance.new("Frame")
	transitionFrame.Name = "TransitionFrame"
	transitionFrame.Style = Enum.FrameStyle.RobloxRound
	transitionFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
	transitionFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
	transitionFrame.Visible = false
	transitionFrame.Parent = frame

	local currentPageValue = Instance.new("ObjectValue")
	currentPageValue.Name = "CurrentTutorialPage"
	currentPageValue.Value = nil
	currentPageValue.Parent = frame

	local boolValue = Instance.new("BoolValue")
	boolValue.Name = "Buttons"
	boolValue.Value = createButtons
	boolValue.Parent = frame

	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.BackgroundTransparency = 1
	pages.Size = UDim2.new(1,0,1,0)
	pages.Parent = frame

	local function getVisiblePageAndHideOthers()
		local visiblePage = nil
		local children = pages:GetChildren()
		if children then
			for i,child in ipairs(children) do
				if child.Visible then
					if visiblePage then
						child.Visible = false
					else
						visiblePage = child
					end
				end
			end
		end
		return visiblePage
	end

	local showTutorial = function(alwaysShow)
		if alwaysShow or UserSettings().GameSettings:GetTutorialState(tutorialKey) == false then
			print("Showing tutorial-",tutorialKey)
			local currentTutorialPage = getVisiblePageAndHideOthers()

			local firstPage = pages:FindFirstChild("TutorialPage1")
			if firstPage then
				TransitionTutorialPages(currentTutorialPage, firstPage, transitionFrame, currentPageValue)	
			else
				error("Could not find TutorialPage1")
			end
		end
	end

	local dismissTutorial = function()
		local currentTutorialPage = getVisiblePageAndHideOthers()

		if currentTutorialPage then
			TransitionTutorialPages(currentTutorialPage, nil, transitionFrame, currentPageValue)
		end

		UserSettings().GameSettings:SetTutorialState(tutorialKey, true)
	end

	local gotoPage = function(pageNum)
		local page = pages:FindFirstChild("TutorialPage" .. pageNum)
		local currentTutorialPage = getVisiblePageAndHideOthers()
		TransitionTutorialPages(currentTutorialPage, page, transitionFrame, currentPageValue)
	end

	return frame, showTutorial, dismissTutorial, gotoPage
end 

local function CreateBasicTutorialPage(name, handleResize, skipTutorial, giveDoneButton)
	local frame = Instance.new("Frame")
	frame.Name = "TutorialPage"
	frame.Style = Enum.FrameStyle.RobloxRound
	frame.Size = UDim2.new(0.6, 0, 0.6, 0)
	frame.Position = UDim2.new(0.2, 0, 0.2, 0)
	frame.Visible = false
	
	local frameHeader = Instance.new("TextLabel")
	frameHeader.Name = "Header"
	frameHeader.Text = name
	frameHeader.BackgroundTransparency = 1
	frameHeader.FontSize = Enum.FontSize.Size24
	frameHeader.Font = Enum.Font.ArialBold
	frameHeader.TextColor3 = Color3.new(1,1,1)
	frameHeader.TextXAlignment = Enum.TextXAlignment.Center
	frameHeader.TextWrap = true
	frameHeader.Size = UDim2.new(1,-55, 0, 22)
	frameHeader.Position = UDim2.new(0,0,0,0)
	frameHeader.Parent = frame

	local skipButton = Instance.new("ImageButton")
	skipButton.Name = "SkipButton"
	skipButton.AutoButtonColor = false
	skipButton.BackgroundTransparency = 1
	skipButton.Image = "rbxasset://textures/ui/closeButton.png"
	skipButton.MouseButton1Click:connect(function()
		skipTutorial()
	end)
	skipButton.MouseEnter:connect(function()
		skipButton.Image = "rbxasset://textures/ui/closeButton_dn.png"
	end)
	skipButton.MouseLeave:connect(function()
		skipButton.Image = "rbxasset://textures/ui/closeButton.png"
	end)
	skipButton.Size = UDim2.new(0, 25, 0, 25)
	skipButton.Position = UDim2.new(1, -25, 0, 0)
	skipButton.Parent = frame
	
	
	if giveDoneButton then
		local doneButton = Instance.new("TextButton")
		doneButton.Name = "DoneButton"
		doneButton.Style = Enum.ButtonStyle.RobloxButtonDefault
		doneButton.Text = "Done"
		doneButton.TextColor3 = Color3.new(1,1,1)
		doneButton.Font = Enum.Font.ArialBold
		doneButton.FontSize = Enum.FontSize.Size18
		doneButton.Size = UDim2.new(0,100,0,50)
		doneButton.Position = UDim2.new(0.5,-50,1,-50)
		
		if skipTutorial then
			doneButton.MouseButton1Click:connect(function() skipTutorial() end)
		end
		
		doneButton.Parent = frame
	end

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "ContentFrame"
	innerFrame.BackgroundTransparency = 1
	innerFrame.Position = UDim2.new(0,0,0,25)
	innerFrame.Parent = frame

	local nextButton = Instance.new("TextButton")
	nextButton.Name = "NextButton"
	nextButton.Text = "Next"
	nextButton.TextColor3 = Color3.new(1,1,1)
	nextButton.Font = Enum.Font.Arial
	nextButton.FontSize = Enum.FontSize.Size18
	nextButton.Style = Enum.ButtonStyle.RobloxButtonDefault
	nextButton.Size = UDim2.new(0,80, 0, 32)
	nextButton.Position = UDim2.new(0.5, 5, 1, -32)
	nextButton.Active = false
	nextButton.Visible = false
	nextButton.Parent = frame

	local prevButton = Instance.new("TextButton")
	prevButton.Name = "PrevButton"
	prevButton.Text = "Previous"
	prevButton.TextColor3 = Color3.new(1,1,1)
	prevButton.Font = Enum.Font.Arial
	prevButton.FontSize = Enum.FontSize.Size18
	prevButton.Style = Enum.ButtonStyle.RobloxButton
	prevButton.Size = UDim2.new(0,80, 0, 32)
	prevButton.Position = UDim2.new(0.5, -85, 1, -32)
	prevButton.Active = false
	prevButton.Visible = false
	prevButton.Parent = frame

	if giveDoneButton then
		innerFrame.Size = UDim2.new(1,0,1,-75)
	else
		innerFrame.Size = UDim2.new(1,0,1,-22)
	end

	local parentConnection = nil

	local function basicHandleResize()
		if frame.Visible and frame.Parent then
			local maxSize = math.min(frame.Parent.AbsoluteSize.X, frame.Parent.AbsoluteSize.Y)
			handleResize(200,maxSize)
		end
	end

	frame.Changed:connect(
		function(prop)
			if prop == "Parent" then
				if parentConnection ~= nil then
					parentConnection:disconnect()
					parentConnection = nil
				end
				if frame.Parent and frame.Parent:IsA("GuiObject") then
					parentConnection = frame.Parent.Changed:connect(
						function(parentProp)
							if parentProp == "AbsoluteSize" then
								wait()
								basicHandleResize()
							end
						end)
					basicHandleResize()
				end
			end

			if prop == "Visible" then 
				basicHandleResize()
			end
		end)

	return frame, innerFrame
end

t.CreateTextTutorialPage = function(name, text, skipTutorialFunc)
	local frame = nil
	local contentFrame = nil

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1,1,1)
	textLabel.Text = text
	textLabel.TextWrap = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Font = Enum.Font.Arial
	textLabel.FontSize = Enum.FontSize.Size14
	textLabel.Size = UDim2.new(1,0,1,0)

	local function handleResize(minSize, maxSize)
		size = binaryShrink(minSize, maxSize,
			function(size)
				frame.Size = UDim2.new(0, size, 0, size)
				return textLabel.TextFits
			end)
		frame.Size = UDim2.new(0, size, 0, size)
		frame.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
	end

	frame, contentFrame = CreateBasicTutorialPage(name, handleResize, skipTutorialFunc)
	textLabel.Parent = contentFrame

	return frame
end

t.CreateImageTutorialPage = function(name, imageAsset, x, y, skipTutorialFunc, giveDoneButton)
	local frame = nil
	local contentFrame = nil

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = imageAsset
	imageLabel.Size = UDim2.new(0,x,0,y)
	imageLabel.Position = UDim2.new(0.5,-x/2,0.5,-y/2)

	local function handleResize(minSize, maxSize)
		size = binaryShrink(minSize, maxSize,
			function(size)
				return size >= x and size >= y
			end)
		if size >= x and size >= y then
			imageLabel.Size = UDim2.new(0,x, 0,y)
			imageLabel.Position = UDim2.new(0.5,-x/2, 0.5, -y/2)
		else
			if x > y then
				--X is limiter, so 
				imageLabel.Size = UDim2.new(1,0,y/x,0)
				imageLabel.Position = UDim2.new(0,0, 0.5 - (y/x)/2, 0)
			else
				--Y is limiter
				imageLabel.Size = UDim2.new(x/y,0,1, 0)
				imageLabel.Position = UDim2.new(0.5-(x/y)/2, 0, 0, 0)
			end
		end
		size = size + 50
		frame.Size = UDim2.new(0, size, 0, size)
		frame.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
	end

	frame, contentFrame = CreateBasicTutorialPage(name, handleResize, skipTutorialFunc, giveDoneButton)
	imageLabel.Parent = contentFrame

	return frame
end

t.AddTutorialPage = function(tutorial, tutorialPage)
	local transitionFrame = tutorial.TransitionFrame
	local currentPageValue = tutorial.CurrentTutorialPage

	if not tutorial.Buttons.Value then
		tutorialPage.NextButton.Parent = nil
		tutorialPage.PrevButton.Parent = nil
	end

	local children = tutorial.Pages:GetChildren()
	if children and #children > 0 then
		tutorialPage.Name = "TutorialPage" .. (#children+1)
		local previousPage = children[#children]
		if not previousPage:IsA("GuiObject") then
			error("All elements under Pages must be GuiObjects")
		end

		if tutorial.Buttons.Value then
			if previousPage.NextButton.Active then
				error("NextButton already Active on previousPage, please only add pages with RbxGui.AddTutorialPage function")
			end
			previousPage.NextButton.MouseButton1Click:connect(
				function()
					TransitionTutorialPages(previousPage, tutorialPage, transitionFrame, currentPageValue)
				end)
			previousPage.NextButton.Active = true
			previousPage.NextButton.Visible = true

			if tutorialPage.PrevButton.Active then
				error("PrevButton already Active on tutorialPage, please only add pages with RbxGui.AddTutorialPage function")
			end
			tutorialPage.PrevButton.MouseButton1Click:connect(
				function()
					TransitionTutorialPages(tutorialPage, previousPage, transitionFrame, currentPageValue)
				end)
			tutorialPage.PrevButton.Active = true
			tutorialPage.PrevButton.Visible = true
		end

		tutorialPage.Parent = tutorial.Pages
	else
		--First child
		tutorialPage.Name = "TutorialPage1"
		tutorialPage.Parent = tutorial.Pages
	end
end 

t.CreateSetPanel = function(userIdsForSets, objectSelected, dialogClosed, size, position, showAdminCategories, useAssetVersionId)

	if not userIdsForSets then
		error("CreateSetPanel: userIdsForSets (first arg) is nil, should be a table of number ids")
	end
	if type(userIdsForSets) ~= "table" and type(userIdsForSets) ~= "userdata" then
		error("CreateSetPanel: userIdsForSets (first arg) is of type " ..type(userIdsForSets) .. ", should be of type table or userdata")
	end
	if not objectSelected then
		error("CreateSetPanel: objectSelected (second arg) is nil, should be a callback function!")
	end
	if type(objectSelected) ~= "function" then
		error("CreateSetPanel: objectSelected (second arg) is of type " .. type(objectSelected) .. ", should be of type function!")
	end
	if dialogClosed and type(dialogClosed) ~= "function" then
		error("CreateSetPanel: dialogClosed (third arg) is of type " .. type(dialogClosed) .. ", should be of type function!")
	end
	
	if showAdminCategories == nil then -- by default, don't show beta sets
		showAdminCategories = false
	end

	local arrayPosition = 1
	local insertButtons = {}
	local insertButtonCons = {}
	local contents = nil
	local setGui = nil

	-- used for water selections
	local waterForceDirection = "NegX"
	local waterForce = "None"
	local waterGui, waterTypeChangedEvent = nil
	
	local Data = {}
	Data.CurrentCategory = nil
	Data.Category = {}
	local SetCache = {}
	
	local userCategoryButtons = nil
	
	local buttonWidth = 64
	local buttonHeight = buttonWidth
	
	local SmallThumbnailUrl = nil
	local LargeThumbnailUrl = nil
	local BaseUrl = game:GetService("ContentProvider").BaseUrl:lower()
	
	if useAssetVersionId then
		LargeThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=420&ht=420&assetversionid="
		SmallThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=75&ht=75&assetversionid="
	else
		LargeThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=420&ht=420&aid="
		SmallThumbnailUrl = BaseUrl .. "Game/Tools/ThumbnailAsset.ashx?fmt=png&wd=75&ht=75&aid="
	end
		
	local function drillDownSetZIndex(parent, index)
		local children = parent:GetChildren()
		for i = 1, #children do
			if children[i]:IsA("GuiObject") then
				children[i].ZIndex = index
			end
			drillDownSetZIndex(children[i], index)
		end
	end
	
	-- for terrain stamping
	local currTerrainDropDownFrame = nil
	local terrainShapes = {"Block","Vertical Ramp","Corner Wedge","Inverse Corner Wedge","Horizontal Ramp","Auto-Wedge"}
	local terrainShapeMap = {}
	for i = 1, #terrainShapes do
		terrainShapeMap[terrainShapes[i]] = i - 1
	end	
	terrainShapeMap[terrainShapes[#terrainShapes]] = 6

	local function createWaterGui()
		local waterForceDirections = {"NegX","X","NegY","Y","NegZ","Z"}
		local waterForces = {"None", "Small", "Medium", "Strong", "Max"}

		local waterFrame = Instance.new("Frame")
		waterFrame.Name = "WaterFrame"
		waterFrame.Style = Enum.FrameStyle.RobloxSquare
		waterFrame.Size = UDim2.new(0,150,0,110)
		waterFrame.Visible = false

		local waterForceLabel = Instance.new("TextLabel")
		waterForceLabel.Name = "WaterForceLabel"
		waterForceLabel.BackgroundTransparency = 1
		waterForceLabel.Size = UDim2.new(1,0,0,12)
		waterForceLabel.Font = Enum.Font.ArialBold
		waterForceLabel.FontSize = Enum.FontSize.Size12
		waterForceLabel.TextColor3 = Color3.new(1,1,1)
		waterForceLabel.TextXAlignment = Enum.TextXAlignment.Left
		waterForceLabel.Text = "Water Force"
		waterForceLabel.Parent = waterFrame

		local waterForceDirLabel = waterForceLabel:Clone()
		waterForceDirLabel.Name = "WaterForceDirectionLabel"
		waterForceDirLabel.Text = "Water Force Direction"
		waterForceDirLabel.Position = UDim2.new(0,0,0,50)
		waterForceDirLabel.Parent = waterFrame

		local waterTypeChangedEvent = Instance.new("BindableEvent",waterFrame)
		waterTypeChangedEvent.Name = "WaterTypeChangedEvent"

		local waterForceDirectionSelectedFunc = function(newForceDirection)
			waterForceDirection = newForceDirection
			waterTypeChangedEvent:Fire({waterForce, waterForceDirection})
		end
		local waterForceSelectedFunc = function(newForce)
			waterForce = newForce
			waterTypeChangedEvent:Fire({waterForce, waterForceDirection})
		end

		local waterForceDirectionDropDown, forceWaterDirectionSelection = t.CreateDropDownMenu(waterForceDirections, waterForceDirectionSelectedFunc)
		waterForceDirectionDropDown.Size = UDim2.new(1,0,0,25)
		waterForceDirectionDropDown.Position = UDim2.new(0,0,1,3)
		forceWaterDirectionSelection("NegX")
		waterForceDirectionDropDown.Parent = waterForceDirLabel

		local waterForceDropDown, forceWaterForceSelection = t.CreateDropDownMenu(waterForces, waterForceSelectedFunc)
		forceWaterForceSelection("None")
		waterForceDropDown.Size = UDim2.new(1,0,0,25)
		waterForceDropDown.Position = UDim2.new(0,0,1,3)
		waterForceDropDown.Parent = waterForceLabel

		return waterFrame, waterTypeChangedEvent
	end

	-- Helper Function that contructs gui elements
	local function createSetGui()
	
		local setGui = Instance.new("ScreenGui")
		setGui.Name = "SetGui"
		
		local setPanel = Instance.new("Frame")
		setPanel.Name = "SetPanel"
		setPanel.Active = true
		setPanel.BackgroundTransparency = 1
		if position then
			setPanel.Position = position
		else
			setPanel.Position = UDim2.new(0.2, 29, 0.1, 24)
		end
		if size then
			setPanel.Size = size
		else
			setPanel.Size = UDim2.new(0.6, -58, 0.64, 0)
		end
		setPanel.Style = Enum.FrameStyle.RobloxRound
		setPanel.ZIndex = 6
		setPanel.Parent = setGui
		
			-- Children of SetPanel
			local itemPreview = Instance.new("Frame")
			itemPreview.Name = "ItemPreview"
			itemPreview.BackgroundTransparency = 1
			itemPreview.Position = UDim2.new(0.8,5,0.085,0)
			itemPreview.Size = UDim2.new(0.21,0,0.9,0)
			itemPreview.ZIndex = 6
			itemPreview.Parent = setPanel
			
				-- Children of ItemPreview
				local textPanel = Instance.new("Frame")
				textPanel.Name = "TextPanel"
				textPanel.BackgroundTransparency = 1
				textPanel.Position = UDim2.new(0,0,0.45,0)
				textPanel.Size = UDim2.new(1,0,0.55,0)
				textPanel.ZIndex = 6
				textPanel.Parent = itemPreview
					
					-- Children of TextPanel
					local rolloverText = Instance.new("TextLabel")
					rolloverText.Name = "RolloverText"
					rolloverText.BackgroundTransparency = 1
					rolloverText.Size = UDim2.new(1,0,0,48)
					rolloverText.ZIndex = 6
					rolloverText.Font = Enum.Font.ArialBold
					rolloverText.FontSize = Enum.FontSize.Size24
					rolloverText.Text = ""
					rolloverText.TextColor3 = Color3.new(1,1,1)
					rolloverText.TextWrap = true
					rolloverText.TextXAlignment = Enum.TextXAlignment.Left
					rolloverText.TextYAlignment = Enum.TextYAlignment.Top
					rolloverText.Parent = textPanel
					
				local largePreview = Instance.new("ImageLabel")
				largePreview.Name = "LargePreview"
				largePreview.BackgroundTransparency = 1
				largePreview.Image = ""
				largePreview.Size = UDim2.new(1,0,0,170)
				largePreview.ZIndex = 6
				largePreview.Parent = itemPreview
				
			local sets = Instance.new("Frame")
			sets.Name = "Sets"
			sets.BackgroundTransparency = 1
			sets.Position = UDim2.new(0,0,0,5)
			sets.Size = UDim2.new(0.23,0,1,-5)
			sets.ZIndex = 6
			sets.Parent = setPanel
			
				-- Children of Sets
				local line = Instance.new("Frame")
				line.Name = "Line"
				line.BackgroundColor3 = Color3.new(1,1,1)
				line.BackgroundTransparency = 0.7
				line.BorderSizePixel = 0
				line.Position = UDim2.new(1,-3,0.06,0)
				line.Size = UDim2.new(0,3,0.9,0)
				line.ZIndex = 6
				line.Parent = sets
				
				local setsLists, controlFrame = t.CreateTrueScrollingFrame()
				setsLists.Size = UDim2.new(1,-6,0.94,0)
				setsLists.Position = UDim2.new(0,0,0.06,0)
				setsLists.BackgroundTransparency = 1
				setsLists.Name = "SetsLists"
				setsLists.ZIndex = 6
				setsLists.Parent = sets
				drillDownSetZIndex(controlFrame, 7)
					
				local setsHeader = Instance.new("TextLabel")
				setsHeader.Name = "SetsHeader"
				setsHeader.BackgroundTransparency = 1
				setsHeader.Size = UDim2.new(0,47,0,24)
				setsHeader.ZIndex = 6
				setsHeader.Font = Enum.Font.ArialBold
				setsHeader.FontSize = Enum.FontSize.Size24
				setsHeader.Text = "Sets"
				setsHeader.TextColor3 = Color3.new(1,1,1)
				setsHeader.TextXAlignment = Enum.TextXAlignment.Left
				setsHeader.TextYAlignment = Enum.TextYAlignment.Top
				setsHeader.Parent = sets
			
			local cancelButton = Instance.new("TextButton")
			cancelButton.Name = "CancelButton"
			cancelButton.Position = UDim2.new(1,-32,0,-2)
			cancelButton.Size = UDim2.new(0,34,0,34)
			cancelButton.Style = Enum.ButtonStyle.RobloxButtonDefault
			cancelButton.ZIndex = 6
			cancelButton.Text = ""
			cancelButton.Modal = true
			cancelButton.Parent = setPanel
			
				-- Children of Cancel Button
				local cancelImage = Instance.new("ImageLabel")
				cancelImage.Name = "CancelImage"
				cancelImage.BackgroundTransparency = 1
				cancelImage.Image = "http://www.roblox.com/asset/?id=54135717"
				cancelImage.Position = UDim2.new(0,-2,0,-2)
				cancelImage.Size = UDim2.new(0,16,0,16)
				cancelImage.ZIndex = 6
				cancelImage.Parent = cancelButton
					
		return setGui
	end
	
	local function createSetButton(text)
		local setButton = Instance.new("TextButton")
		
		if text then setButton.Text = text
		else setButton.Text = "" end
		
		setButton.AutoButtonColor = false
		setButton.BackgroundTransparency = 1
		setButton.BackgroundColor3 = Color3.new(1,1,1)
		setButton.BorderSizePixel = 0
		setButton.Size = UDim2.new(1,-5,0,18)
		setButton.ZIndex = 6
		setButton.Visible = false
		setButton.Font = Enum.Font.Arial
		setButton.FontSize = Enum.FontSize.Size18
		setButton.TextColor3 = Color3.new(1,1,1)
		setButton.TextXAlignment = Enum.TextXAlignment.Left
		
		return setButton
	end
	
	local function buildSetButton(name, setId, setImageId, i,  count)
		local button = createSetButton(name)
		button.Text = name
		button.Name = "SetButton"
		button.Visible = true
		
		local setValue = Instance.new("IntValue")
		setValue.Name = "SetId"
		setValue.Value = setId
		setValue.Parent = button

		local setName = Instance.new("StringValue")
		setName.Name = "SetName"
		setName.Value = name
		setName.Parent = button

		return button
	end
	
	local function processCategory(sets)
		local setButtons = {}
		local numSkipped = 0
		for i = 1, #sets do
			if not showAdminCategories and sets[i].Name == "Beta" then
				numSkipped = numSkipped + 1
			else
				setButtons[i - numSkipped] = buildSetButton(sets[i].Name, sets[i].CategoryId, sets[i].ImageAssetId, i - numSkipped, #sets)
			end
		end
		return setButtons
	end
	
	local function handleResize()
		wait() -- neccessary to insure heartbeat happened
		
		local itemPreview = setGui.SetPanel.ItemPreview
		
		itemPreview.LargePreview.Size = UDim2.new(1,0,0,itemPreview.AbsoluteSize.X)
		itemPreview.LargePreview.Position = UDim2.new(0.5,-itemPreview.LargePreview.AbsoluteSize.X/2,0,0)
		itemPreview.TextPanel.Position = UDim2.new(0,0,0,itemPreview.LargePreview.AbsoluteSize.Y)
		itemPreview.TextPanel.Size = UDim2.new(1,0,0,itemPreview.AbsoluteSize.Y - itemPreview.LargePreview.AbsoluteSize.Y)
	end
	
	local function makeInsertAssetButton()
		local insertAssetButtonExample = Instance.new("Frame")
		insertAssetButtonExample.Name = "InsertAssetButtonExample"
		insertAssetButtonExample.Position = UDim2.new(0,128,0,64)
		insertAssetButtonExample.Size = UDim2.new(0,64,0,64)
		insertAssetButtonExample.BackgroundTransparency = 1
		insertAssetButtonExample.ZIndex = 6
		insertAssetButtonExample.Visible = false

		local assetId = Instance.new("IntValue")
		assetId.Name = "AssetId"
		assetId.Value = 0
		assetId.Parent = insertAssetButtonExample
		
		local assetName = Instance.new("StringValue")
		assetName.Name = "AssetName"
		assetName.Value = ""
		assetName.Parent = insertAssetButtonExample

		local button = Instance.new("TextButton")
		button.Name = "Button"
		button.Text = ""
		button.Style = Enum.ButtonStyle.RobloxButton
		button.Position = UDim2.new(0.025,0,0.025,0)
		button.Size = UDim2.new(0.95,0,0.95,0)
		button.ZIndex = 6
		button.Parent = insertAssetButtonExample

		local buttonImage = Instance.new("ImageLabel")
		buttonImage.Name = "ButtonImage"
		buttonImage.Image = ""
		buttonImage.Position = UDim2.new(0,-7,0,-7)
		buttonImage.Size = UDim2.new(1,14,1,14)
		buttonImage.BackgroundTransparency = 1
		buttonImage.ZIndex = 7
		buttonImage.Parent = button

		local configIcon = buttonImage:clone()
		configIcon.Name = "ConfigIcon"
		configIcon.Visible = false
		configIcon.Position = UDim2.new(1,-23,1,-24)
		configIcon.Size = UDim2.new(0,16,0,16)
		configIcon.Image = ""
		configIcon.ZIndex = 6
		configIcon.Parent = insertAssetButtonExample
		
		return insertAssetButtonExample
	end
	
	local function showLargePreview(insertButton)
		if insertButton:FindFirstChild("AssetId") then
			delay(0,function()
				game:GetService("ContentProvider"):Preload(LargeThumbnailUrl .. tostring(insertButton.AssetId.Value))
				setGui.SetPanel.ItemPreview.LargePreview.Image = LargeThumbnailUrl .. tostring(insertButton.AssetId.Value)
			end)
		end
		if insertButton:FindFirstChild("AssetName") then
			setGui.SetPanel.ItemPreview.TextPanel.RolloverText.Text = insertButton.AssetName.Value
		end
	end
	
	local function selectTerrainShape(shape)
		if currTerrainDropDownFrame then
			objectSelected(tostring(currTerrainDropDownFrame.AssetName.Value), tonumber(currTerrainDropDownFrame.AssetId.Value), shape)
		end
	end
	
	local function createTerrainTypeButton(name, parent)
		local dropDownTextButton = Instance.new("TextButton")
		dropDownTextButton.Name = name .. "Button"
		dropDownTextButton.Font = Enum.Font.ArialBold
		dropDownTextButton.FontSize = Enum.FontSize.Size14
		dropDownTextButton.BorderSizePixel = 0
		dropDownTextButton.TextColor3 = Color3.new(1,1,1)
		dropDownTextButton.Text = name
		dropDownTextButton.TextXAlignment = Enum.TextXAlignment.Left
		dropDownTextButton.BackgroundTransparency = 1
		dropDownTextButton.ZIndex = parent.ZIndex + 1
		dropDownTextButton.Size = UDim2.new(0,parent.Size.X.Offset - 2,0,16)
		dropDownTextButton.Position = UDim2.new(0,1,0,0)

		dropDownTextButton.MouseEnter:connect(function()
			dropDownTextButton.BackgroundTransparency = 0
			dropDownTextButton.TextColor3 = Color3.new(0,0,0)
		end)

		dropDownTextButton.MouseLeave:connect(function()
			dropDownTextButton.BackgroundTransparency = 1
			dropDownTextButton.TextColor3 = Color3.new(1,1,1)
		end)

		dropDownTextButton.MouseButton1Click:connect(function()
			dropDownTextButton.BackgroundTransparency = 1
			dropDownTextButton.TextColor3 = Color3.new(1,1,1)
			if dropDownTextButton.Parent and dropDownTextButton.Parent:IsA("GuiObject") then
				dropDownTextButton.Parent.Visible = false
			end
			selectTerrainShape(terrainShapeMap[dropDownTextButton.Text])
		end)

		return dropDownTextButton
	end
	
	local function createTerrainDropDownMenu(zIndex)
		local dropDown = Instance.new("Frame")
		dropDown.Name = "TerrainDropDown"
		dropDown.BackgroundColor3 = Color3.new(0,0,0)
		dropDown.BorderColor3 = Color3.new(1,0,0)
		dropDown.Size = UDim2.new(0,200,0,0)
		dropDown.Visible = false
		dropDown.ZIndex = zIndex
		dropDown.Parent = setGui

		for i = 1, #terrainShapes do
			local shapeButton = createTerrainTypeButton(terrainShapes[i],dropDown)
			shapeButton.Position = UDim2.new(0,1,0,(i - 1) * (shapeButton.Size.Y.Offset))
			shapeButton.Parent = dropDown
			dropDown.Size = UDim2.new(0,200,0,dropDown.Size.Y.Offset + (shapeButton.Size.Y.Offset))
		end

		dropDown.MouseLeave:connect(function()
			dropDown.Visible = false
		end)
	end

	
	local function createDropDownMenuButton(parent)
		local dropDownButton = Instance.new("ImageButton")
		dropDownButton.Name = "DropDownButton"
		dropDownButton.Image = "http://www.roblox.com/asset/?id=67581509"
		dropDownButton.BackgroundTransparency = 1
		dropDownButton.Size = UDim2.new(0,16,0,16)
		dropDownButton.Position = UDim2.new(1,-24,0,6)
		dropDownButton.ZIndex = parent.ZIndex + 2
		dropDownButton.Parent = parent
		
		if not setGui:FindFirstChild("TerrainDropDown") then
			createTerrainDropDownMenu(8)
		end
		
		dropDownButton.MouseButton1Click:connect(function()
			setGui.TerrainDropDown.Visible = true
			setGui.TerrainDropDown.Position = UDim2.new(0,parent.AbsolutePosition.X,0,parent.AbsolutePosition.Y)
			currTerrainDropDownFrame = parent
		end)
	end
	
	local function buildInsertButton()
		local insertButton = makeInsertAssetButton()
		insertButton.Name = "InsertAssetButton"
		insertButton.Visible = true

		if Data.Category[Data.CurrentCategory].SetName == "High Scalability" then
			createDropDownMenuButton(insertButton)
		end

		local lastEnter = nil
		local mouseEnterCon = insertButton.MouseEnter:connect(function()
			lastEnter = insertButton
			delay(0.1,function()
				if lastEnter == insertButton then
					showLargePreview(insertButton)
				end
			end)
		end)
		return insertButton, mouseEnterCon
	end
	
	local function realignButtonGrid(columns)
		local x = 0
		local y = 0 
		for i = 1, #insertButtons do
			insertButtons[i].Position = UDim2.new(0, buttonWidth * x, 0, buttonHeight * y)
			x = x + 1
			if x >= columns then
				x = 0
				y = y + 1
			end
		end
	end

	local function setInsertButtonImageBehavior(insertFrame, visible, name, assetId)
		if visible then
			insertFrame.AssetName.Value = name
			insertFrame.AssetId.Value = assetId
			local newImageUrl = SmallThumbnailUrl  .. assetId
			if newImageUrl ~= insertFrame.Button.ButtonImage.Image then
				delay(0,function()
					game:GetService("ContentProvider"):Preload(SmallThumbnailUrl  .. assetId)
					if insertFrame:findFirstChild("Button") then
						insertFrame.Button.ButtonImage.Image = SmallThumbnailUrl  .. assetId
					end
				end)
			end
			table.insert(insertButtonCons,
				insertFrame.Button.MouseButton1Click:connect(function()
					-- special case for water, show water selection gui
					local isWaterSelected = (name == "Water") and (Data.Category[Data.CurrentCategory].SetName == "High Scalability")
					waterGui.Visible = isWaterSelected
					if isWaterSelected then
						objectSelected(name, tonumber(assetId), nil)
					else
						objectSelected(name, tonumber(assetId))
					end
				end)
			)
			insertFrame.Visible = true
		else
			insertFrame.Visible = false
		end
	end
	
	local function loadSectionOfItems(setGui, rows, columns)
		local pageSize = rows * columns

		if arrayPosition > #contents then return end

		local origArrayPos = arrayPosition

		local yCopy = 0
		for i = 1, pageSize + 1 do 
			if arrayPosition >= #contents + 1 then
				break
			end

			local buttonCon
			insertButtons[arrayPosition], buttonCon = buildInsertButton()
			table.insert(insertButtonCons,buttonCon)
			insertButtons[arrayPosition].Parent = setGui.SetPanel.ItemsFrame
			arrayPosition = arrayPosition + 1
		end
		realignButtonGrid(columns)

		local indexCopy = origArrayPos
		for index = origArrayPos, arrayPosition do
			if insertButtons[index] then
				if contents[index] then

					-- we don't want water to have a drop down button
					if contents[index].Name == "Water" then
						if Data.Category[Data.CurrentCategory].SetName == "High Scalability" then
							insertButtons[index]:FindFirstChild("DropDownButton",true):Destroy()
						end
					end

					local assetId
					if useAssetVersionId then
						assetId = contents[index].AssetVersionId
					else
						assetId = contents[index].AssetId
					end
					setInsertButtonImageBehavior(insertButtons[index], true, contents[index].Name, assetId)
				else
					break
				end
			else
				break
			end
			indexCopy = index
		end
	end
	
	local function setSetIndex()
		Data.Category[Data.CurrentCategory].Index = 0

		rows = 7
		columns = math.floor(setGui.SetPanel.ItemsFrame.AbsoluteSize.X/buttonWidth)

		contents = Data.Category[Data.CurrentCategory].Contents
		if contents then
			-- remove our buttons and their connections
			for i = 1, #insertButtons do
				insertButtons[i]:remove()
			end
			for i = 1, #insertButtonCons do
				if insertButtonCons[i] then insertButtonCons[i]:disconnect() end
			end
			insertButtonCons = {}
			insertButtons = {}

			arrayPosition = 1
			loadSectionOfItems(setGui, rows, columns)
		end
	end
	
	local function selectSet(button, setName, setId, setIndex)
		if button and Data.Category[Data.CurrentCategory] ~= nil then
			if button ~= Data.Category[Data.CurrentCategory].Button then
				Data.Category[Data.CurrentCategory].Button = button

				if SetCache[setId] == nil then
					SetCache[setId] = game:GetService("InsertService"):GetCollection(setId)
				end
				Data.Category[Data.CurrentCategory].Contents = SetCache[setId]

				Data.Category[Data.CurrentCategory].SetName = setName
				Data.Category[Data.CurrentCategory].SetId = setId
			end
			setSetIndex()
		end
	end
	
	local function selectCategoryPage(buttons, page)
		if buttons ~= Data.CurrentCategory then
			if Data.CurrentCategory then
				for key, button in pairs(Data.CurrentCategory) do
					button.Visible = false
				end
			end

			Data.CurrentCategory = buttons
			if Data.Category[Data.CurrentCategory] == nil then
				Data.Category[Data.CurrentCategory] = {}
				if #buttons > 0 then
					selectSet(buttons[1], buttons[1].SetName.Value, buttons[1].SetId.Value, 0)
				end
			else
				Data.Category[Data.CurrentCategory].Button = nil
				selectSet(Data.Category[Data.CurrentCategory].ButtonFrame, Data.Category[Data.CurrentCategory].SetName, Data.Category[Data.CurrentCategory].SetId, Data.Category[Data.CurrentCategory].Index)
			end
		end
	end
	
	local function selectCategory(category)
		selectCategoryPage(category, 0)
	end
	
	local function resetAllSetButtonSelection()
		local setButtons = setGui.SetPanel.Sets.SetsLists:GetChildren()
		for i = 1, #setButtons do
			if setButtons[i]:IsA("TextButton") then
				setButtons[i].Selected = false
				setButtons[i].BackgroundTransparency = 1
				setButtons[i].TextColor3 = Color3.new(1,1,1)
				setButtons[i].BackgroundColor3 = Color3.new(1,1,1)
			end
		end
	end
	
	local function populateSetsFrame()
		local currRow = 0
		for i = 1, #userCategoryButtons do
			local button = userCategoryButtons[i]
			button.Visible = true
			button.Position = UDim2.new(0,5,0,currRow * button.Size.Y.Offset)
			button.Parent = setGui.SetPanel.Sets.SetsLists
			
			if i == 1 then -- we will have this selected by default, so show it
				button.Selected = true
				button.BackgroundColor3 = Color3.new(0,204/255,0)
				button.TextColor3 = Color3.new(0,0,0)
				button.BackgroundTransparency = 0
			end

			button.MouseEnter:connect(function()
				if not button.Selected then
					button.BackgroundTransparency = 0
					button.TextColor3 = Color3.new(0,0,0)
				end
			end)
			button.MouseLeave:connect(function()
				if not button.Selected then
					button.BackgroundTransparency = 1
					button.TextColor3 = Color3.new(1,1,1)
				end
			end)
			button.MouseButton1Click:connect(function()
				resetAllSetButtonSelection()
				button.Selected = not button.Selected
				button.BackgroundColor3 = Color3.new(0,204/255,0)
				button.TextColor3 = Color3.new(0,0,0)
				button.BackgroundTransparency = 0
				selectSet(button, button.Text, userCategoryButtons[i].SetId.Value, 0)
			end)

			currRow = currRow + 1
		end

		local buttons =  setGui.SetPanel.Sets.SetsLists:GetChildren()

		-- set first category as loaded for default
		if buttons then
			for i = 1, #buttons do
				if buttons[i]:IsA("TextButton") then
					selectSet(buttons[i], buttons[i].Text, userCategoryButtons[i].SetId.Value, 0)
					selectCategory(userCategoryButtons)
					break
				end
			end
		end
	end

	setGui = createSetGui()
	waterGui, waterTypeChangedEvent = createWaterGui()
	waterGui.Position = UDim2.new(0,55,0,0)
	waterGui.Parent = setGui
	setGui.Changed:connect(function(prop) -- this resizes the preview image to always be the right size
		if prop == "AbsoluteSize" then
			handleResize()
			setSetIndex()
		end
	end)
	
	local scrollFrame, controlFrame = t.CreateTrueScrollingFrame()
	scrollFrame.Size = UDim2.new(0.54,0,0.85,0)
	scrollFrame.Position = UDim2.new(0.24,0,0.085,0)
	scrollFrame.Name = "ItemsFrame"
	scrollFrame.ZIndex = 6
	scrollFrame.Parent = setGui.SetPanel
	scrollFrame.BackgroundTransparency = 1

	drillDownSetZIndex(controlFrame,7)

	controlFrame.Parent = setGui.SetPanel
	controlFrame.Position = UDim2.new(0.76, 5, 0, 0)

	local debounce = false
	controlFrame.ScrollBottom.Changed:connect(function(prop)
		if controlFrame.ScrollBottom.Value == true then
			if debounce then return end
			debounce = true
				loadSectionOfItems(setGui, rows, columns)
			debounce = false
		end
	end)

	local userData = {}
	for id = 1, #userIdsForSets do
		local newUserData = game:GetService("InsertService"):GetUserSets(userIdsForSets[id])
		if newUserData and #newUserData > 2 then
			-- start at #3 to skip over My Decals and My Models for each account
			for category = 3, #newUserData do
				if newUserData[category].Name == "High Scalability" then -- we want high scalability parts to show first
					table.insert(userData,1,newUserData[category])
				else
					table.insert(userData, newUserData[category])
				end
			end
		end
	
	end
	if userData then
		userCategoryButtons = processCategory(userData)
	end

	rows = math.floor(setGui.SetPanel.ItemsFrame.AbsoluteSize.Y/buttonHeight)
	columns = math.floor(setGui.SetPanel.ItemsFrame.AbsoluteSize.X/buttonWidth)

	populateSetsFrame()

	insertPanelCloseCon = setGui.SetPanel.CancelButton.MouseButton1Click:connect(function()
		setGui.SetPanel.Visible = false
		if dialogClosed then dialogClosed() end
	end)
	
	local setVisibilityFunction = function(visible)
		if visible then
			setGui.SetPanel.Visible = true
		else
			setGui.SetPanel.Visible = false
		end
	end
	
	local getVisibilityFunction = function()
		if setGui then
			if setGui:FindFirstChild("SetPanel") then
				return setGui.SetPanel.Visible
			end
		end
		
		return false
	end
	
	return setGui, setVisibilityFunction, getVisibilityFunction, waterTypeChangedEvent
end

t.CreateTerrainMaterialSelector = function(size,position)
	local terrainMaterialSelectionChanged = Instance.new("BindableEvent")
	terrainMaterialSelectionChanged.Name = "TerrainMaterialSelectionChanged"

	local selectedButton = nil

	local frame = Instance.new("Frame")
	frame.Name = "TerrainMaterialSelector"
	if size then
		frame.Size = size
	else
		frame.Size = UDim2.new(0, 245, 0, 230)
	end
	if position then
		frame.Position = position
	end
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Color3.new(0,0,0)
	frame.Active = true

	terrainMaterialSelectionChanged.Parent = frame

	local waterEnabled = true -- todo: turn this on when water is ready

	local materialToImageMap = {}
	local materialNames = {"Grass", "Sand", "Brick", "Granite", "Asphalt", "Iron", "Aluminum", "Gold", "Plank", "Log", "Gravel", "Cinder Block", "Stone Wall", "Concrete", "Plastic (red)", "Plastic (blue)"}
	if waterEnabled then
		table.insert(materialNames,"Water")
	end
	local currentMaterial = 1

	function getEnumFromName(choice)
		if choice == "Grass" then return 1 end
		if choice == "Sand" then return 2 end 
		if choice == "Erase" then return 0 end
		if choice == "Brick" then return 3 end
		if choice == "Granite" then return 4 end
		if choice == "Asphalt" then return 5 end
		if choice == "Iron" then return 6 end
		if choice == "Aluminum" then return 7 end
		if choice == "Gold" then return 8 end
		if choice == "Plank" then return 9 end
		if choice == "Log" then return 10 end
		if choice == "Gravel" then return 11 end
		if choice == "Cinder Block" then return 12 end
		if choice == "Stone Wall" then return 13 end
		if choice == "Concrete" then return 14 end
		if choice == "Plastic (red)" then return 15 end
		if choice == "Plastic (blue)" then return 16 end
		if choice == "Water" then return 17 end
	end

	function getNameFromEnum(choice)
		if choice == Enum.CellMaterial.Grass or choice == 1 then return "Grass"end
		if choice == Enum.CellMaterial.Sand or choice == 2 then return "Sand" end 
		if choice == Enum.CellMaterial.Empty or choice == 0 then return "Erase" end
		if choice == Enum.CellMaterial.Brick or choice == 3 then return "Brick" end
		if choice == Enum.CellMaterial.Granite or choice == 4 then return "Granite" end
		if choice == Enum.CellMaterial.Asphalt or choice == 5 then return "Asphalt" end
		if choice == Enum.CellMaterial.Iron or choice == 6 then return "Iron" end
		if choice == Enum.CellMaterial.Aluminum or choice == 7 then return "Aluminum" end
		if choice == Enum.CellMaterial.Gold or choice == 8 then return "Gold" end
		if choice == Enum.CellMaterial.WoodPlank or choice == 9 then return "Plank" end
		if choice == Enum.CellMaterial.WoodLog or choice == 10 then return "Log" end
		if choice == Enum.CellMaterial.Gravel or choice == 11 then return "Gravel" end
		if choice == Enum.CellMaterial.CinderBlock or choice == 12 then return "Cinder Block" end
		if choice == Enum.CellMaterial.MossyStone or choice == 13 then return "Stone Wall" end
		if choice == Enum.CellMaterial.Cement or choice == 14 then return "Concrete" end
		if choice == Enum.CellMaterial.RedPlastic or choice == 15 then return "Plastic (red)" end
		if choice == Enum.CellMaterial.BluePlastic or choice == 16 then return "Plastic (blue)" end

		if waterEnabled then
			if choice == Enum.CellMaterial.Water or choice == 17 then return "Water" end
		end
	end


	local function updateMaterialChoice(choice)
		currentMaterial = getEnumFromName(choice)
		terrainMaterialSelectionChanged:Fire(currentMaterial)
	end

	-- we so need a better way to do this
	for i,v in pairs(materialNames) do
		materialToImageMap[v] = {}
		if v == "Grass" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=56563112"
		elseif v == "Sand" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=62356652"
		elseif v == "Brick" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=65961537"
		elseif v == "Granite" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532153"
		elseif v == "Asphalt" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532038"
		elseif v == "Iron" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532093"
		elseif v == "Aluminum" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531995"
		elseif v == "Gold" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532118"
		elseif v == "Plastic (red)" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531848"
		elseif v == "Plastic (blue)" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531924"
		elseif v == "Plank" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532015"
		elseif v == "Log" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532051"
		elseif v == "Gravel" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532206"
		elseif v == "Cinder Block" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532103"
		elseif v == "Stone Wall" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67531804"
		elseif v == "Concrete" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=67532059"
		elseif v == "Water" then materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=81407474"
		else materialToImageMap[v].Regular = "http://www.roblox.com/asset/?id=66887593" -- fill in the rest here!!
		end
	end

	local scrollFrame, scrollUp, scrollDown, recalculateScroll = t.CreateScrollingFrame(nil,"grid")
	scrollFrame.Size = UDim2.new(0.85,0,1,0)
	scrollFrame.Position = UDim2.new(0,0,0,0)
	scrollFrame.Parent = frame

	scrollUp.Parent = frame
	scrollUp.Visible = true
	scrollUp.Position = UDim2.new(1,-19,0,0)

	scrollDown.Parent = frame
	scrollDown.Visible = true
	scrollDown.Position = UDim2.new(1,-19,1,-17)

	local function goToNewMaterial(buttonWrap, materialName)
		updateMaterialChoice(materialName)
		buttonWrap.BackgroundTransparency = 0
		selectedButton.BackgroundTransparency = 1
		selectedButton = buttonWrap
	end

	local function createMaterialButton(name)	
		local buttonWrap = Instance.new("TextButton")
		buttonWrap.Text = ""
		buttonWrap.Size = UDim2.new(0,32,0,32)
		buttonWrap.BackgroundColor3 = Color3.new(1,1,1)
		buttonWrap.BorderSizePixel = 0
		buttonWrap.BackgroundTransparency = 1
		buttonWrap.AutoButtonColor = false
		buttonWrap.Name = tostring(name)
		
		local imageButton = Instance.new("ImageButton")
		imageButton.AutoButtonColor = false
		imageButton.BackgroundTransparency = 1
		imageButton.Size = UDim2.new(0,30,0,30)
		imageButton.Position = UDim2.new(0,1,0,1)
		imageButton.Name = tostring(name)
		imageButton.Parent = buttonWrap
		imageButton.Image = materialToImageMap[name].Regular

		local enumType = Instance.new("NumberValue")
		enumType.Name = "EnumType"
		enumType.Parent = buttonWrap
		enumType.Value = 0
		
		imageButton.MouseEnter:connect(function()
			buttonWrap.BackgroundTransparency = 0
		end)
		imageButton.MouseLeave:connect(function()
			if selectedButton ~= buttonWrap then
				buttonWrap.BackgroundTransparency = 1
			end
		end)
		imageButton.MouseButton1Click:connect(function()
			if selectedButton ~= buttonWrap then
				goToNewMaterial(buttonWrap, tostring(name))
			end
		end)
		
		return buttonWrap 
	end

	for i = 1, #materialNames do
		local imageButton = createMaterialButton(materialNames[i])
		
		if materialNames[i] == "Grass" then -- always start with grass as the default
			selectedButton = imageButton
			imageButton.BackgroundTransparency = 0
		end
		
		imageButton.Parent = scrollFrame
	end

	local forceTerrainMaterialSelection = function(newMaterialType)
		if not newMaterialType then return end
		if currentMaterial == newMaterialType then return end

		local matName = getNameFromEnum(newMaterialType)
		local buttons = scrollFrame:GetChildren()
		for i = 1, #buttons do
			if buttons[i].Name == "Plastic (blue)" and matName == "Plastic (blue)" then goToNewMaterial(buttons[i],matName) return end
			if buttons[i].Name == "Plastic (red)" and matName == "Plastic (red)" then goToNewMaterial(buttons[i],matName) return end
			if string.find(buttons[i].Name, matName) then
				goToNewMaterial(buttons[i],matName)
				return
			end
		end
	end

	frame.Changed:connect(function ( prop )
		if prop == "AbsoluteSize" then
			recalculateScroll()
		end
	end)

	recalculateScroll()
	return frame, terrainMaterialSelectionChanged, forceTerrainMaterialSelection
end

t.CreateLoadingFrame = function(name,size,position)
	game:GetService("ContentProvider"):Preload("http://www.roblox.com/asset/?id=35238053")

	local loadingFrame = Instance.new("Frame")
	loadingFrame.Name = "LoadingFrame"
	loadingFrame.Style = Enum.FrameStyle.RobloxRound

	if size then loadingFrame.Size = size
	else loadingFrame.Size = UDim2.new(0,300,0,160) end
	if position then loadingFrame.Position = position 
	else loadingFrame.Position = UDim2.new(0.5, -150, 0.5,-80) end

	local loadingBar = Instance.new("Frame")
	loadingBar.Name = "LoadingBar"
	loadingBar.BackgroundColor3 = Color3.new(0,0,0)
	loadingBar.BorderColor3 = Color3.new(79/255,79/255,79/255)
	loadingBar.Position = UDim2.new(0,0,0,41)
	loadingBar.Size = UDim2.new(1,0,0,30)
	loadingBar.Parent = loadingFrame

		local loadingGreenBar = Instance.new("ImageLabel")
		loadingGreenBar.Name = "LoadingGreenBar"
		loadingGreenBar.Image = "http://www.roblox.com/asset/?id=35238053"
		loadingGreenBar.Position = UDim2.new(0,0,0,0)
		loadingGreenBar.Size = UDim2.new(0,0,1,0)
		loadingGreenBar.Visible = false
		loadingGreenBar.Parent = loadingBar

		local loadingPercent = Instance.new("TextLabel")
		loadingPercent.Name = "LoadingPercent"
		loadingPercent.BackgroundTransparency = 1
		loadingPercent.Position = UDim2.new(0,0,1,0)
		loadingPercent.Size = UDim2.new(1,0,0,14)
		loadingPercent.Font = Enum.Font.Arial
		loadingPercent.Text = "0%"
		loadingPercent.FontSize = Enum.FontSize.Size14
		loadingPercent.TextColor3 = Color3.new(1,1,1)
		loadingPercent.Parent = loadingBar

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Position = UDim2.new(0.5,-60,1,-40)
	cancelButton.Size = UDim2.new(0,120,0,40)
	cancelButton.Font = Enum.Font.Arial
	cancelButton.FontSize = Enum.FontSize.Size18
	cancelButton.TextColor3 = Color3.new(1,1,1)
	cancelButton.Text = "Cancel"
	cancelButton.Style = Enum.ButtonStyle.RobloxButton
	cancelButton.Parent = loadingFrame

	local loadingName = Instance.new("TextLabel")
	loadingName.Name = "loadingName"
	loadingName.BackgroundTransparency = 1
	loadingName.Size = UDim2.new(1,0,0,18)
	loadingName.Position = UDim2.new(0,0,0,2)
	loadingName.Font = Enum.Font.Arial
	loadingName.Text = name
	loadingName.TextColor3 = Color3.new(1,1,1)
	loadingName.TextStrokeTransparency = 1
	loadingName.FontSize = Enum.FontSize.Size18
	loadingName.Parent = loadingFrame

	local cancelButtonClicked = Instance.new("BindableEvent")
	cancelButtonClicked.Name = "CancelButtonClicked"
	cancelButtonClicked.Parent = cancelButton
	cancelButton.MouseButton1Click:connect(function()
		cancelButtonClicked:Fire()
	end)

	local updateLoadingGuiPercent = function(percent, tweenAction, tweenLength)
		if percent and type(percent) ~= "number" then
			error("updateLoadingGuiPercent expects number as argument, got",type(percent),"instead")
		end

		local newSize = nil
		if percent < 0 then
			newSize = UDim2.new(0,0,1,0)
		elseif percent > 1 then
			newSize = UDim2.new(1,0,1,0)
		else
			newSize = UDim2.new(percent,0,1,0)
		end

		if tweenAction then
			if not tweenLength then
				error("updateLoadingGuiPercent is set to tween new percentage, but got no tween time length! Please pass this in as third argument")
			end

			if (newSize.X.Scale > 0) then
				loadingGreenBar.Visible = true
				loadingGreenBar:TweenSize(	newSize,
											Enum.EasingDirection.Out,
											Enum.EasingStyle.Quad,
											tweenLength,
											true)
			else
				loadingGreenBar:TweenSize(	newSize,
											Enum.EasingDirection.Out,
											Enum.EasingStyle.Quad,
											tweenLength,
											true,
											function() 
												if (newSize.X.Scale < 0) then
													loadingGreenBar.Visible = false
												end
											end)
			end

		else
			loadingGreenBar.Size = newSize
			loadingGreenBar.Visible = (newSize.X.Scale > 0)
		end
	end

	loadingGreenBar.Changed:connect(function(prop)
		if prop == "Size" then
			loadingPercent.Text = tostring( math.ceil(loadingGreenBar.Size.X.Scale * 100) ) .. "%"
		end
	end)

	return loadingFrame, updateLoadingGuiPercent, cancelButtonClicked
end

t.CreatePluginFrame = function (name,size,position,scrollable,parent)
	function createMenuButton(size,position,text,fontsize,name,parent)
		local button = Instance.new("TextButton",parent)
		button.AutoButtonColor = false
		button.Name = name
		button.BackgroundTransparency = 1
		button.Position = position
		button.Size = size
		button.Font = Enum.Font.ArialBold
		button.FontSize = fontsize
		button.Text =  text
		button.TextColor3 = Color3.new(1,1,1)
		button.BorderSizePixel = 0
		button.BackgroundColor3 = Color3.new(20/255,20/255,20/255)

		button.MouseEnter:connect(function ( )
			if button.Selected then return end
			button.BackgroundTransparency = 0
		end)
		button.MouseLeave:connect(function ( )
			if button.Selected then return end
			button.BackgroundTransparency = 1
		end)

		return button

	end

	local dragBar = Instance.new("Frame",parent)
	dragBar.Name = tostring(name) .. "DragBar"
	dragBar.BackgroundColor3 = Color3.new(39/255,39/255,39/255)
	dragBar.BorderColor3 = Color3.new(0,0,0)
	if size then
		dragBar.Size =  UDim2.new(size.X.Scale,size.X.Offset,0,20)  + UDim2.new(0,20,0,0)
	else
		dragBar.Size = UDim2.new(0,183,0,20)
	end
	if position then
		dragBar.Position = position
	end
	dragBar.Active = true
	dragBar.Draggable = true
	--dragBar.Visible = false
	dragBar.MouseEnter:connect(function (  )
		dragBar.BackgroundColor3 = Color3.new(49/255,49/255,49/255)
	end)
	dragBar.MouseLeave:connect(function (  )
		dragBar.BackgroundColor3 = Color3.new(39/255,39/255,39/255)
	end)

	-- plugin name label
	local pluginNameLabel = Instance.new("TextLabel",dragBar)
	pluginNameLabel.Name = "BarNameLabel"
	pluginNameLabel.Text = " " .. tostring(name)
	pluginNameLabel.TextColor3 = Color3.new(1,1,1)
	pluginNameLabel.TextStrokeTransparency = 0
	pluginNameLabel.Size = UDim2.new(1,0,1,0)
	pluginNameLabel.Font = Enum.Font.ArialBold
	pluginNameLabel.FontSize = Enum.FontSize.Size18
	pluginNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	pluginNameLabel.BackgroundTransparency = 1

	-- close button
	local closeButton = createMenuButton(UDim2.new(0,15,0,17),UDim2.new(1,-16,0.5,-8),"X",Enum.FontSize.Size14,"CloseButton",dragBar)
	local closeEvent = Instance.new("BindableEvent")
	closeEvent.Name = "CloseEvent"
	closeEvent.Parent = closeButton
	closeButton.MouseButton1Click:connect(function ()
		closeEvent:Fire()
		closeButton.BackgroundTransparency = 1
	end)

	-- help button
	local helpButton = createMenuButton(UDim2.new(0,15,0,17),UDim2.new(1,-51,0.5,-8),"?",Enum.FontSize.Size14,"HelpButton",dragBar)
	local helpFrame = Instance.new("Frame",dragBar)
	helpFrame.Name = "HelpFrame"
	helpFrame.BackgroundColor3 = Color3.new(0,0,0)
	helpFrame.Size = UDim2.new(0,300,0,552)
	helpFrame.Position = UDim2.new(1,5,0,0)
	helpFrame.Active = true
	helpFrame.BorderSizePixel = 0
	helpFrame.Visible = false

	helpButton.MouseButton1Click:connect(function(  )
		helpFrame.Visible = not helpFrame.Visible
		if helpFrame.Visible then
			helpButton.Selected = true
			helpButton.BackgroundTransparency = 0
			local screenGui = getScreenGuiAncestor(helpFrame)
			if screenGui then
				if helpFrame.AbsolutePosition.X + helpFrame.AbsoluteSize.X > screenGui.AbsoluteSize.X then --position on left hand side
					helpFrame.Position = UDim2.new(0,-5 - helpFrame.AbsoluteSize.X,0,0)
				else -- position on right hand side
					helpFrame.Position = UDim2.new(1,5,0,0)
				end
			else
				helpFrame.Position = UDim2.new(1,5,0,0)
			end
		else
			helpButton.Selected = false
			helpButton.BackgroundTransparency = 1
		end
	end)

	local minimizeButton = createMenuButton(UDim2.new(0,16,0,17),UDim2.new(1,-34,0.5,-8),"-",Enum.FontSize.Size14,"MinimizeButton",dragBar)
	minimizeButton.TextYAlignment = Enum.TextYAlignment.Top

	local minimizeFrame = Instance.new("Frame",dragBar)
	minimizeFrame.Name = "MinimizeFrame"
	minimizeFrame.BackgroundColor3 = Color3.new(73/255,73/255,73/255)
	minimizeFrame.BorderColor3 = Color3.new(0,0,0)
	minimizeFrame.Position = UDim2.new(0,0,1,0)
	if size then
		minimizeFrame.Size =  UDim2.new(size.X.Scale,size.X.Offset,0,50) + UDim2.new(0,20,0,0)
	else
		minimizeFrame.Size = UDim2.new(0,183,0,50)
	end
	minimizeFrame.Visible = false

	local minimizeBigButton = Instance.new("TextButton",minimizeFrame)
	minimizeBigButton.Position = UDim2.new(0.5,-50,0.5,-20)
	minimizeBigButton.Name = "MinimizeButton"
	minimizeBigButton.Size = UDim2.new(0,100,0,40)
	minimizeBigButton.Style = Enum.ButtonStyle.RobloxButton
	minimizeBigButton.Font = Enum.Font.ArialBold
	minimizeBigButton.FontSize = Enum.FontSize.Size18
	minimizeBigButton.TextColor3 = Color3.new(1,1,1)
	minimizeBigButton.Text = "Show"

	local separatingLine = Instance.new("Frame",dragBar)
	separatingLine.Name = "SeparatingLine"
	separatingLine.BackgroundColor3 = Color3.new(115/255,115/255,115/255)
	separatingLine.BorderSizePixel = 0
	separatingLine.Position = UDim2.new(1,-18,0.5,-7)
	separatingLine.Size = UDim2.new(0,1,0,14)

	local otherSeparatingLine = separatingLine:clone()
	otherSeparatingLine.Position = UDim2.new(1,-35,0.5,-7)
	otherSeparatingLine.Parent = dragBar

	local widgetContainer = Instance.new("Frame",dragBar)
	widgetContainer.Name = "WidgetContainer"
	widgetContainer.BackgroundTransparency = 1
	widgetContainer.Position = UDim2.new(0,0,1,0)
	widgetContainer.BorderColor3 = Color3.new(0,0,0)
	if not scrollable then
		widgetContainer.BackgroundTransparency = 0
		widgetContainer.BackgroundColor3 = Color3.new(72/255,72/255,72/255)
	end

	if size then
		if scrollable then
			widgetContainer.Size = size
		else
			widgetContainer.Size = UDim2.new(0,dragBar.AbsoluteSize.X,size.Y.Scale,size.Y.Offset)
		end
	else
		if scrollable then
			widgetContainer.Size = UDim2.new(0,163,0,400)
		else
			widgetContainer.Size = UDim2.new(0,dragBar.AbsoluteSize.X,0,400)
		end
	end
	if position then
		widgetContainer.Position = position + UDim2.new(0,0,0,20)
	end

	local frame,control,verticalDragger = nil
	if scrollable then
		--frame for widgets
		frame,control = t.CreateTrueScrollingFrame()
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.new(72/255,72/255,72/255)
		frame.BorderColor3 = Color3.new(0,0,0)
		frame.Active = true
		frame.Parent = widgetContainer
		control.Parent = dragBar
		control.BackgroundColor3 = Color3.new(72/255,72/255,72/255)
		control.BorderSizePixel = 0
		control.BackgroundTransparency = 0
		control.Position = UDim2.new(1,-21,1,1)
		if size then
			control.Size = UDim2.new(0,21,size.Y.Scale,size.Y.Offset)
		else
			control.Size = UDim2.new(0,21,0,400)
		end
		control:FindFirstChild("ScrollDownButton").Position = UDim2.new(0,0,1,-20)

		local fakeLine = Instance.new("Frame",control)
		fakeLine.Name = "FakeLine"
		fakeLine.BorderSizePixel = 0
		fakeLine.BackgroundColor3 = Color3.new(0,0,0)
		fakeLine.Size = UDim2.new(0,1,1,1)
		fakeLine.Position = UDim2.new(1,0,0,0)

		verticalDragger = Instance.new("TextButton",widgetContainer)
		verticalDragger.ZIndex = 2
		verticalDragger.AutoButtonColor = false
		verticalDragger.Name = "VerticalDragger"
		verticalDragger.BackgroundColor3 = Color3.new(50/255,50/255,50/255)
		verticalDragger.BorderColor3 = Color3.new(0,0,0)
		verticalDragger.Size = UDim2.new(1,20,0,20)
		verticalDragger.Position = UDim2.new(0,0,1,0)
		verticalDragger.Active = true
		verticalDragger.Text = ""

		local scrubFrame = Instance.new("Frame",verticalDragger)
		scrubFrame.Name = "ScrubFrame"
		scrubFrame.BackgroundColor3 = Color3.new(1,1,1)
		scrubFrame.BorderSizePixel = 0
		scrubFrame.Position = UDim2.new(0.5,-5,0.5,0)
		scrubFrame.Size = UDim2.new(0,10,0,1)
		scrubFrame.ZIndex = 5
		local scrubTwo = scrubFrame:clone()
		scrubTwo.Position = UDim2.new(0.5,-5,0.5,-2)
		scrubTwo.Parent = verticalDragger
		local scrubThree = scrubFrame:clone()
		scrubThree.Position = UDim2.new(0.5,-5,0.5,2)
		scrubThree.Parent = verticalDragger

		local areaSoak = Instance.new("TextButton",getScreenGuiAncestor(parent))
		areaSoak.Name = "AreaSoak"
		areaSoak.Size = UDim2.new(1,0,1,0)
		areaSoak.BackgroundTransparency = 1
		areaSoak.BorderSizePixel = 0
		areaSoak.Text = ""
		areaSoak.ZIndex = 10
		areaSoak.Visible = false
		areaSoak.Active = true

		local draggingVertical = false
		local startYPos = nil
		verticalDragger.MouseEnter:connect(function ()
			verticalDragger.BackgroundColor3 = Color3.new(60/255,60/255,60/255)
		end)
		verticalDragger.MouseLeave:connect(function ()
			verticalDragger.BackgroundColor3 = Color3.new(50/255,50/255,50/255)
		end)
		verticalDragger.MouseButton1Down:connect(function(x,y)
			draggingVertical = true
			areaSoak.Visible = true
			startYPos = y
		end)
		areaSoak.MouseButton1Up:connect(function (  )
			draggingVertical = false
			areaSoak.Visible = false
		end)
		areaSoak.MouseMoved:connect(function(x,y)
			if not draggingVertical then return end

			local yDelta = y - startYPos
			if not control.ScrollDownButton.Visible and yDelta > 0 then
				return
			end

			if (widgetContainer.Size.Y.Offset + yDelta) < 150 then
				widgetContainer.Size = UDim2.new(widgetContainer.Size.X.Scale, widgetContainer.Size.X.Offset,widgetContainer.Size.Y.Scale,150)
				control.Size = UDim2.new (0,21,0,150)
				return 
			end 

			startYPos = y

			if widgetContainer.Size.Y.Offset + yDelta >= 0 then
				widgetContainer.Size = UDim2.new(widgetContainer.Size.X.Scale, widgetContainer.Size.X.Offset,widgetContainer.Size.Y.Scale,widgetContainer.Size.Y.Offset + yDelta)
				control.Size = UDim2.new(0,21,0,control.Size.Y.Offset + yDelta )
			end
		end)
	end

	local function switchMinimize()
		minimizeFrame.Visible = not minimizeFrame.Visible
		if scrollable then
			frame.Visible = not frame.Visible
			verticalDragger.Visible = not verticalDragger.Visible
			control.Visible = not control.Visible
		else
			widgetContainer.Visible = not widgetContainer.Visible
		end

		if minimizeFrame.Visible then
			minimizeButton.Text = "+"
		else
			minimizeButton.Text = "-"
		end
	end

	minimizeBigButton.MouseButton1Click:connect(function (  )
		switchMinimize()
	end)

	minimizeButton.MouseButton1Click:connect(function(  )
		switchMinimize()
	end)

	if scrollable then
		return dragBar, frame, helpFrame, closeEvent
	else
		return dragBar, widgetContainer, helpFrame, closeEvent
	end
end

t.Help = 
	function(funcNameOrFunc) 
		--input argument can be a string or a function.  Should return a description (of arguments and expected side effects)
		if funcNameOrFunc == "CreatePropertyDropDownMenu" or funcNameOrFunc == t.CreatePropertyDropDownMenu then
			return "Function CreatePropertyDropDownMenu.  " ..
				   "Arguments: (instance, propertyName, enumType).  " .. 
				   "Side effect: returns a container with a drop-down-box that is linked to the 'property' field of 'instance' which is of type 'enumType'" 
		end 
		if funcNameOrFunc == "CreateDropDownMenu" or funcNameOrFunc == t.CreateDropDownMenu then
			return "Function CreateDropDownMenu.  " .. 
			       "Arguments: (items, onItemSelected).  " .. 
				   "Side effect: Returns 2 results, a container to the gui object and a 'updateSelection' function for external updating.  The container is a drop-down-box created around a list of items" 
		end 
		if funcNameOrFunc == "CreateMessageDialog" or funcNameOrFunc == t.CreateMessageDialog then
			return "Function CreateMessageDialog.  " .. 
			       "Arguments: (title, message, buttons). " .. 
			       "Side effect: Returns a gui object of a message box with 'title' and 'message' as passed in.  'buttons' input is an array of Tables contains a 'Text' and 'Function' field for the text/callback of each button"
		end		
		if funcNameOrFunc == "CreateStyledMessageDialog" or funcNameOrFunc == t.CreateStyledMessageDialog then
			return "Function CreateStyledMessageDialog.  " .. 
			       "Arguments: (title, message, style, buttons). " .. 
			       "Side effect: Returns a gui object of a message box with 'title' and 'message' as passed in.  'buttons' input is an array of Tables contains a 'Text' and 'Function' field for the text/callback of each button, 'style' is a string, either Error, Notify or Confirm"
		end
		if funcNameOrFunc == "GetFontHeight" or funcNameOrFunc == t.GetFontHeight then
			return "Function GetFontHeight.  " .. 
			       "Arguments: (font, fontSize). " .. 
			       "Side effect: returns the size in pixels of the given font + fontSize"
		end
		if funcNameOrFunc == "LayoutGuiObjects" or funcNameOrFunc == t.LayoutGuiObjects then
		
		end
		if funcNameOrFunc == "CreateScrollingFrame" or funcNameOrFunc == t.CreateScrollingFrame then
			return "Function CreateScrollingFrame.  " .. 
			   "Arguments: (orderList, style) " .. 
			   "Side effect: returns 4 objects, (scrollFrame, scrollUpButton, scrollDownButton, recalculateFunction).  'scrollFrame' can be filled with GuiObjects.  It will lay them out and allow scrollUpButton/scrollDownButton to interact with them.  Orderlist is optional (and specifies the order to layout the children.  Without orderlist, it uses the children order. style is also optional, and allows for a 'grid' styling if style is passed 'grid' as a string.  recalculateFunction can be called when a relayout is needed (when orderList changes)"
		end
		if funcNameOrFunc == "CreateTrueScrollingFrame" or funcNameOrFunc == t.CreateTrueScrollingFrame then
			return "Function CreateTrueScrollingFrame.  " .. 
			   "Arguments: (nil) " .. 
			   "Side effect: returns 2 objects, (scrollFrame, controlFrame).  'scrollFrame' can be filled with GuiObjects, and they will be clipped if not inside the frame's bounds. controlFrame has children scrollup and scrolldown, as well as a slider.  controlFrame can be parented to any guiobject and it will readjust itself to fit."
		end
		if funcNameOrFunc == "AutoTruncateTextObject" or funcNameOrFunc == t.AutoTruncateTextObject then
			return "Function AutoTruncateTextObject.  " .. 
			   "Arguments: (textLabel) " .. 
			   "Side effect: returns 2 objects, (textLabel, changeText).  The 'textLabel' input is modified to automatically truncate text (with ellipsis), if it gets too small to fit.  'changeText' is a function that can be used to change the text, it takes 1 string as an argument"
		end
		if funcNameOrFunc == "CreateSlider" or funcNameOrFunc == t.CreateSlider then
			return "Function CreateSlider.  " ..
				"Arguments: (steps, width, position) " ..
				"Side effect: returns 2 objects, (sliderGui, sliderPosition).  The 'steps' argument specifies how many different positions the slider can hold along the bar.  'width' specifies in pixels how wide the bar should be (modifiable afterwards if desired). 'position' argument should be a UDim2 for slider positioning. 'sliderPosition' is an IntValue whose current .Value specifies the specific step the slider is currently on."
		end
		if funcNameOrFunc == "CreateSliderNew" or funcNameOrFunc == t.CreateSliderNew then
			return "Function CreateSliderNew.  " ..
				"Arguments: (steps, width, position) " ..
				"Side effect: returns 2 objects, (sliderGui, sliderPosition).  The 'steps' argument specifies how many different positions the slider can hold along the bar.  'width' specifies in pixels how wide the bar should be (modifiable afterwards if desired). 'position' argument should be a UDim2 for slider positioning. 'sliderPosition' is an IntValue whose current .Value specifies the specific step the slider is currently on."
		end
		if funcNameOrFunc == "CreateLoadingFrame" or funcNameOrFunc == t.CreateLoadingFrame then
			return "Function CreateLoadingFrame.  " ..
				"Arguments: (name, size, position) " ..
				"Side effect: Creates a gui that can be manipulated to show progress for a particular action.  Name appears above the loading bar, and size and position are udim2 values (both size and position are optional arguments).  Returns 3 arguments, the first being the gui created. The second being updateLoadingGuiPercent, which is a bindable function.  This function takes one argument (two optionally), which should be a number between 0 and 1, representing the percentage the loading gui should be at.  The second argument to this function is a boolean value that if set to true will tween the current percentage value to the new percentage value, therefore our third argument is how long this tween should take. Our third returned argument is a BindableEvent, that when fired means that someone clicked the cancel button on the dialog."
		end
		if funcNameOrFunc == "CreateTerrainMaterialSelector" or funcNameOrFunc == t.CreateTerrainMaterialSelector then
			return "Function CreateTerrainMaterialSelector.  " ..
				"Arguments: (size, position) " ..
				"Side effect: Size and position are UDim2 values that specifies the selector's size and position.  Both size and position are optional arguments. This method returns 3 objects (terrainSelectorGui, terrainSelected, forceTerrainSelection).  terrainSelectorGui is just the gui object that we generate with this function, parent it as you like. TerrainSelected is a BindableEvent that is fired whenever a new terrain type is selected in the gui.  ForceTerrainSelection is a function that takes an argument of Enum.CellMaterial and will force the gui to show that material as currently selected."
		end
	end

-----------------------------
--LOCAL FUNCTION DEFINITIONS-
-----------------------------
local c = game.Workspace.Terrain
local WorldToCellPreferSolid = c.WorldToCellPreferSolid
local WorldToCellPreferEmpty = c.WorldToCellPreferEmpty
local CellCenterToWorld = c.CellCenterToWorld
local GetCell = c.GetCell
local SetCell = c.SetCell
local maxYExtents = c.MaxExtents.Max.Y

local emptyMaterial = Enum.CellMaterial.Empty
local waterMaterial = Enum.CellMaterial.Water

local floodFill = nil

-----------------
--DEFAULT VALUES-
-----------------
local startCell = nil
local loaded = false
local on = false
local processing = false

-- gui values
local screenGui = nil
local dragBar, closeEvent, helpFrame, lastCell = nil
local progressBar, setProgressFunc, cancelEvent = nil
local ConfirmationPopupObject = nil

--- exposed values to user via gui
local currentMaterial = 1


---------------
--PLUGIN SETUP-
---------------
self = PluginManager():CreatePlugin()
local mouse = self:GetMouse()
mouse.Button1Down:connect(function() mouseDown(mouse) end)
mouse.Button1Up:connect(function() mouseUp(mouse) end)

self.Deactivation:connect(function()
	Off()
end)
toolbar = self:CreateToolbar("Terrain")
toolbarbutton = toolbar:CreateButton("", "Flood Fill", "floodFill.png")
toolbarbutton.Click:connect(function()
	if on then
		Off()
	elseif loaded then
		On()
	end
end)

-- load our libraries
local RbxGui = t
local RbxUtil = t
game:GetService("ContentProvider"):Preload("http://www.roblox.com/asset/?id=82741829")


------------------------- OBJECT DEFINITIONS ---------------------

-- helper function for objects
function getClosestColorToTerrainMaterial(terrainValue)
	if terrainValue == 1 then return BrickColor.new("Bright green")
	elseif terrainValue == 2 then return BrickColor.new("Bright yellow")
	elseif terrainValue == 3 then return BrickColor.new("Bright red")
	elseif terrainValue == 4 then return BrickColor.new("Sand red")
	elseif terrainValue == 5 then return BrickColor.new("Black")
	elseif terrainValue == 6 then return BrickColor.new("Dark stone grey")
	elseif terrainValue == 7 then return BrickColor.new("Sand blue")
	elseif terrainValue == 8 then return BrickColor.new("Deep orange")
	elseif terrainValue == 9 then return BrickColor.new("Dark orange")
	elseif terrainValue == 10 then return BrickColor.new("Reddish brown")
	elseif terrainValue == 11 then return BrickColor.new("Light orange")
	elseif terrainValue == 12 then return BrickColor.new("Light stone grey")
	elseif terrainValue == 13 then return BrickColor.new("Sand green")
	elseif terrainValue == 14 then return BrickColor.new("Medium stone grey")
	elseif terrainValue == 15 then return BrickColor.new("Really red")
	elseif terrainValue == 16 then return BrickColor.new("Really blue")
	elseif terrainValue == 17 then return BrickColor.new("Bright blue")
	else return BrickColor.new("Bright green")
	end
end



-- Used to create a highlighter that follows the mouse.
-- It is a class mouse highlighter.  To use, call MouseHighlighter.Create(mouse) where mouse is the mouse to track.
MouseHighlighter = {}
MouseHighlighter.__index = MouseHighlighter

-- Create a mouse movement highlighter.
-- plugin - Plugin to get the mouse from.
function MouseHighlighter.Create(mouseUse)
	local highlighter = {}
	
	local mouse = mouseUse
	highlighter.OnClicked = nil
	highlighter.mouseDown = false
	
	-- Store the last point used to draw.
	highlighter.lastUsedPoint = nil
	
	-- Will hold a part the highlighter will be attached to.  This will be moved where the mouse is.
	highlighter.selectionPart = nil

	-- Hook the mouse up to check for movement.
	mouse.Move:connect(function() MouseMoved() end)	
	
	mouse.Button1Down:connect(function() highlighter.mouseDown = true end)
	mouse.Button1Up:connect(function() highlighter.mouseDown = false
                                      end)
	
	
	-- Create the part that the highlighter will be attached to.
	highlighter.selectionPart = Instance.new("Part")
	highlighter.selectionPart.Name = "SelectionPart"
	highlighter.selectionPart.Archivable = false
	highlighter.selectionPart.Transparency = 0.5
	highlighter.selectionPart.Anchored = true
	highlighter.selectionPart.Locked = true
	highlighter.selectionPart.CanCollide = false
	highlighter.selectionPart.FormFactor = Enum.FormFactor.Custom
	highlighter.selectionPart.Size = Vector3.new(4,4,4)
	highlighter.selectionPart.BottomSurface = 0
	highlighter.selectionPart.TopSurface = 0
	highlighter.selectionPart.BrickColor = getClosestColorToTerrainMaterial(currentMaterial)
	highlighter.selectionPart.Parent = game.Workspace

	local billboardGui = Instance.new("BillboardGui",highlighter.selectionPart)
	billboardGui.Size = UDim2.new(5,0,5,0)
	billboardGui.StudsOffset = Vector3.new(0,2.5,0)

	local imageLabel = Instance.new("ImageLabel",billboardGui)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Size = UDim2.new(1,0,1,0)
	imageLabel.Position = UDim2.new(-0.35,0,-0.5,0)
	imageLabel.Image = "http://www.roblox.com/asset/?id=82741829"

	local lastTweenChange = nil

	function startTween()
		while tweenUp or tweenDown do
			wait(0.2)
		end
		lastTweenChange = tick()

		delay(0,function (  )
			local thisTweenStamp = lastTweenChange
			local tweenDown, tweenUp = nil

			tweenDown = function()
				if imageLabel and imageLabel:IsDescendantOf(game.Workspace) and thisTweenStamp == lastTweenChange then 
					imageLabel:TweenPosition(UDim2.new(-0.35,0,-0.5,0), Enum.EasingDirection.In, Enum.EasingStyle.Quad,0.4,true,tweenUp)
				end
			end
			tweenUp = function()
				if imageLabel and imageLabel:IsDescendantOf(game.Workspace) and thisTweenStamp == lastTweenChange then
					imageLabel:TweenPosition(UDim2.new(-0.35,0,-0.7,0), Enum.EasingDirection.Out, Enum.EasingStyle.Sine,0.4,true,tweenDown)
				end
			end

			tweenUp()
		end)
	end

	function stopTween()
		lastTweenChange = tick()
	end

	mouse.TargetFilter = highlighter.selectionPart
	setmetatable(highlighter, MouseHighlighter)

	-- Function to call when the mouse has moved.  Updates where to display the highlighter.
	function MouseMoved()
		if on and not processing then
			UpdatePosition(mouse.Hit)
		end
	end

	-- Update where the highlighter is displayed.
	-- position - Where to display the highlighter, in world space.
	function UpdatePosition(position)
		if not position then 
			return 
		end
		
		if not mouse.Target then 
			stopTween()
			highlighter.selectionPart.Parent = nil
			return 
		end

		if highlighter.selectionPart.Parent ~= game.Workspace then
			highlighter.selectionPart.Parent = game.Workspace
			startTween()
		end
		
		local vectorPos = Vector3.new(position.x,position.y,position.z)
		local cellPos = WorldToCellPreferEmpty(c, vectorPos)

		local regionToSelect = nil

		local cellMaterial = GetCell(c, cellPos.x,cellPos.y,cellPos.z)
		local y = cellPos.y
		-- only select empty cells
		while cellMaterial ~= emptyMaterial do
			y = y + 1
			cellMaterial = GetCell(c, cellPos.x,y,cellPos.z)
		end
		cellPos = Vector3.new(cellPos.x,y,cellPos.z)

		local lowVec = CellCenterToWorld(c, cellPos.x , cellPos.y - 1, cellPos.z)
		local highVec = CellCenterToWorld(c, cellPos.x, cellPos.y + 1, cellPos.z)
		regionToSelect = Region3.new(lowVec, highVec)

		highlighter.selectionPart.CFrame = regionToSelect.CFrame
		
		if nil ~= highlighter.OnClicked and highlighter.mouseDown then
			if nil == highlighter.lastUsedPoint then 
				highlighter.lastUsedPoint = WorldToCellPreferEmpty(c, Vector3.new(mouse.Hit.x, mouse.Hit.y, mouse.Hit.z))
			else
				cellPos = WorldToCellPreferEmpty(c, Vector3.new(mouse.Hit.x, mouse.Hit.y, mouse.Hit.z))
				
				holdChange = cellPos - highlighter.lastUsedPoint
			
				-- Require terrain.
				if 0 == GetCell(c, cellPos.X, cellPos.Y, cellPos.Z).Value then
					return
				else
					highlighter.lastUsedPoint = cellPos
				end

			end
		end		
	end	
	
	return highlighter
end

function MouseHighlighter:SetMaterial(newMaterial)
	self.selectionPart.BrickColor = getClosestColorToTerrainMaterial(newMaterial)
end

function MouseHighlighter:GetPosition()
	local position = self.selectionPart.CFrame.p
	return WorldToCellPreferEmpty(c,position)
end

-- Hide the highlighter.
function MouseHighlighter:DisablePreview()
	stopTween()
	self.selectionPart.Parent = nil
end

-- Show the highlighter.
function MouseHighlighter:EnablePreview()
	self.selectionPart.Parent = game.Workspace
	startTween()
end

-- Create the mouse movement highlighter.
local mouseHighlighter = MouseHighlighter.Create(mouse)
mouseHighlighter:DisablePreview()


-- Used to create a highlighter.
-- A highlighter is a open, rectuangular area displayed in 3D.
ConfirmationPopup = {}
ConfirmationPopup.__index = ConfirmationPopup

-- Create a standard text label.  Use this for all lables in the popup so it is easy to standardize.
-- labelName - What to set the text label name as.
-- pos    	 - Where to position the label.  Should be of type UDim2.
-- size   	 - How large to make the label.	 Should be of type UDim2.
-- text   	 - Text to display.
-- parent 	 - What to set the text parent as.
-- Return:
-- Value is the created label.
function CreateStandardLabel(labelName,
                             pos,
							 size,
							 text,
							 parent)
	local label = Instance.new("TextLabel", parent)
	label.Name = labelName
	label.Position = pos
	label.Size = size
	label.Text = text
	label.TextColor3 = Color3.new(0.95, 0.95, 0.95)
	label.Font = Enum.Font.ArialBold
	label.FontSize = Enum.FontSize.Size14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundTransparency = 1	
	label.Parent = parent	
	
	return label
end

-- Keep common button properties here to make it easer to change them all at once.
-- These are the default properties to use for a button.
buttonTextColor = Color3.new(1, 1, 1);
buttonFont = Enum.Font.ArialBold;
buttonFontSize = Enum.FontSize.Size18;

-- Create a standard dropdown.  Use this for all dropdowns in the popup so it is easy to standardize.
-- name - What to use.
-- pos    	 	- Where to position the button.  Should be of type UDim2.
-- text         - Text to show in the button.
-- funcOnPress  - Function to run when the button is pressed.
-- parent 	 	- What to set the parent as.
-- Return:
-- button 	   - The button gui.																																	
function CreateStandardButton(name,
  							  pos,
							  text,
							  funcOnPress,
							  parent,
							  size)					
	button = Instance.new("TextButton", parent)
	button.Name = name
	button.Position = pos

	button.Size = UDim2.new(0,120,0,40)
	button.Text = text

	if size then
		button.Size = size
	end
	
	button.Style = Enum.ButtonStyle.RobloxButton

	button.TextColor3 = buttonTextColor
	button.Font = buttonFont
	button.FontSize = buttonFontSize

	button.MouseButton1Click:connect(funcOnPress)
	
	return button
end	
					 
-- Create a confirmation popup.
--
-- confirmText      - What to display in the popup.
-- textOffset       - Offset to position text at.
-- confirmFunction  - Function to run on confirmation.
-- declineFunction  - Function to run when declining.
--
-- Return:
-- Value a table with confirmation gui and options.	
function ConfirmationPopup.Create(confirmText,
								  confirmSmallText,
								  confirmButtonText,
								  declineButtonText,
							      confirmFunction,
							      declineFunction)			  
	local popup = {}
	popup.confirmButton = nil			-- Hold the button to confirm a choice.
	popup.declineButton = nil			-- Hold the button to decline a choice.		 			 
	popup.confirmationFrame = nil       -- Hold the conformation frame.
	popup.confirmationText = nil        -- Hold the text label to display the conformation message.
	popup.confirmationHelpText = nil    -- Hold the text label to display the conformation message help.

	
	popup.confirmationFrame = Instance.new("Frame",screenGui)
	popup.confirmationFrame.Name = "ConfirmationFrame"
	popup.confirmationFrame.Size = UDim2.new(0, 280, 0, 160)
	popup.confirmationFrame.Position = UDim2.new(.5, -popup.confirmationFrame.Size.X.Offset/2, 0.5, -popup.confirmationFrame.Size.Y.Offset/2)
	popup.confirmationFrame.Style = Enum.FrameStyle.RobloxRound
	popup.confirmLabel = CreateStandardLabel("ConfirmLabel", UDim2.new(0,0,0,15), UDim2.new(1, 0, 0, 24), confirmText, popup.confirmationFrame)
	popup.confirmLabel.FontSize = Enum.FontSize.Size18
	popup.confirmLabel.TextXAlignment = Enum.TextXAlignment.Center

	popup.confirmationHelpText = CreateStandardLabel("ConfirmSmallLabel", UDim2.new(0,0,0,40), UDim2.new(1, 0, 0, 28), confirmSmallText, popup.confirmationFrame)
	popup.confirmationHelpText.FontSize = Enum.FontSize.Size14
	popup.confirmationHelpText.TextWrap = true
	popup.confirmationHelpText.Font = Enum.Font.Arial
	popup.confirmationHelpText.TextXAlignment = Enum.TextXAlignment.Center

	-- Confirm
	popup.confirmButton = CreateStandardButton("ConfirmButton",
										UDim2.new(0.5, -120, 1, -50),
									    confirmButtonText,
									    confirmFunction,
									    popup.confirmationFrame)	
										
	-- Decline
	popup.declineButton  = CreateStandardButton("DeclineButton",
										UDim2.new(0.5, 0, 1, -50),
									    declineButtonText,
									    declineFunction,
									    popup.confirmationFrame)										
	
	setmetatable(popup, ConfirmationPopup)
	
	return popup
end	

-- Clear the popup, free up assets.
function ConfirmationPopup:Clear()

	if nil ~= self.confirmButton then
		self.confirmButton.Parent = nil
	end
	
	if nil ~= self.declineButton then
		self.declineButton.Parent = nil	
	end
	
	if nil ~= self.confirmationFrame then
		self.confirmationFrame.Parent = nil
	end
	
	if nil ~= self.confirmLabel then
		self.confirmLabel.Parent = nil    
	end
	
	self.confirmButton = nil
	self.declineButton = nil			 
	self.conformationFrame = nil
	self.conformText = nil      
end

-----------------------
--FUNCTION DEFINITIONS-
-----------------------

local floodFill = function ( x,y,z )
	LoadProgressBar("Processing")
		breadthFill(x,y,z)
	UnloadProgressBar()
	game:GetService("ChangeHistoryService"): SetWaypoint("FloodFill")		
end

-- Function used when we try and flood fill.  Prompts the user first.
-- Will not show if disabled or terrain is being processed.
function ConfirmFloodFill(x,y,z)
	-- Only do if something isn't already being processed.
	if not processing then
		processing = true
		if nil == ConfirmationPopupObject then
			ConfirmationPopupObject = ConfirmationPopup.Create("Flood Fill At Selected Location?",
															 "This operation may take some time.",
														     "Fill",
														     "Cancel",
															 function()
															 	 ConfirmationPopupObject:Clear()
															 	 ConfirmationPopupObject = nil
																 floodFill(x,y,z)
																 ConfirmationPopupObject = nil
															 end,
															 function() 
																ConfirmationPopupObject:Clear()
																ConfirmationPopupObject = nil
																processing = false
															 end)
		end
	end
end

function mouseDown(mouse)
	if on and mouse.Target == game.Workspace.Terrain then
		startCell = mouseHighlighter:GetPosition()
	end
end

function mouseUp(mouse)
	if processing then return end

	local upCell = mouseHighlighter:GetPosition()
	if startCell == upCell then
		ConfirmFloodFill(upCell.x,upCell.y,upCell.z)
	end
end

function getMaterial( x,y,z )
	local material = GetCell(c,x,y,z)
	return material
end

function startLoadingFrame(  )
	
end

-- Load the progress bar to display when drawing a river.
-- text - Text to display.
function LoadProgressBar(text)
	processing = true

	-- Start the progress bar.
	progressBar, setProgressFunc, cancelEvent = RbxGui.CreateLoadingFrame(text)
	
	progressBar.Position = UDim2.new(.5, -progressBar.Size.X.Offset/2, 0, 15)
	progressBar.Parent = screenGui

	local loadingPercent = progressBar:FindFirstChild("LoadingPercent",true)
	if loadingPercent then
		loadingPercent.Parent = nil
	end
	local loadingBar = progressBar:FindFirstChild("LoadingBar",true)
	if loadingBar then
		loadingBar.Parent = nil
	end
	local cancelButton = progressBar:FindFirstChild("CancelButton",true)
	if cancelButton then
		cancelButton.Text = "Stop"
	end

	cancelEvent.Event:connect(function(arguments)
		processing = false
		spin = false
	end)

	local spinnerFrame = Instance.new("Frame",progressBar)
	spinnerFrame.Name = "Spinner"
	spinnerFrame.Size = UDim2.new(0, 80, 0, 80)
	spinnerFrame.Position = UDim2.new(0.5, -40, 0.5, -55)
	spinnerFrame.BackgroundTransparency = 1

	local spinnerIcons = {}
	local spinnerNum = 1
	while spinnerNum <= 8 do
		local spinnerImage = Instance.new("ImageLabel")
	   spinnerImage.Name = "Spinner"..spinnerNum
		spinnerImage.Size = UDim2.new(0, 16, 0, 16)
		spinnerImage.Position = UDim2.new(.5+.3*math.cos(math.rad(45*spinnerNum)), -8, .5+.3*math.sin(math.rad(45*spinnerNum)), -8)
		spinnerImage.BackgroundTransparency = 1
	   spinnerImage.Image = "http://www.roblox.com/Asset?id=45880710"
		spinnerImage.Parent = spinnerFrame

	   spinnerIcons[spinnerNum] = spinnerImage
	   spinnerNum = spinnerNum + 1
	end

	--Make it spin
	delay(0, function()
	  local spinPos = 0
		while processing do
			local pos = 0

			while pos < 8 do
				if pos == spinPos or pos == ((spinPos+1)%8) then
					spinnerIcons[pos+1].Image = "http://www.roblox.com/Asset?id=45880668"
				else
					spinnerIcons[pos+1].Image = "http://www.roblox.com/Asset?id=45880710"
				end
				
				pos = pos + 1
			end
			spinPos = (spinPos + 1) % 8
			wait(0.2)
		end
	end)
end

-- Unload the progress bar.
function UnloadProgressBar()
	processing = false
	
	if progressBar then
		progressBar.Parent = nil
		progressBar = nil
	end
	if setProgressFunc then
		setProgressFunc = nil
	end
	if cancelEvent then
		cancelEvent = nil
	end
end

function breadthFill( x,y,z )
	local yDepthChecks = doBreadthFill(x,y,z)
	while yDepthChecks and #yDepthChecks > 0 do
		local newYChecks = {}
		for i = 1, #yDepthChecks do
			local currYDepthChecks = doBreadthFill(yDepthChecks[i].xPos,yDepthChecks[i].yPos,yDepthChecks[i].zPos)

			if not processing then
				return
			end

			if currYDepthChecks and #currYDepthChecks > 0 then
				for i = 1, #currYDepthChecks do
					table.insert(newYChecks,{xPos = currYDepthChecks[i].xPos, yPos = currYDepthChecks[i].yPos, zPos = currYDepthChecks[i].zPos})
				end
			end
		end
		yDepthChecks = newYChecks
	end
end

function doBreadthFill(x,y,z)
	if getMaterial(x,y,z) ~= emptyMaterial then
		return
	end

	local yDepthChecks = {}
	local cellsToCheck = breadthFillHelper(x,y,z,yDepthChecks)
	local count = 0

	while cellsToCheck and #cellsToCheck > 0 do
		local cellCheckQueue = {}
		for i = 1, #cellsToCheck do
			if not processing then
				return
			end

			count = count + 1
			local newCellsToCheck = breadthFillHelper(cellsToCheck[i].xPos,cellsToCheck[i].yPos,cellsToCheck[i].zPos,yDepthChecks)
			if newCellsToCheck and #newCellsToCheck > 0 then
				for i = 1, #newCellsToCheck do
					table.insert(cellCheckQueue,{xPos = newCellsToCheck[i].xPos, yPos = newCellsToCheck[i].yPos, zPos = newCellsToCheck[i].zPos})
				end
			end
			if count >= 3000 then
				wait()
				count = 0
			end
		end
		cellsToCheck = cellCheckQueue
	end

	return yDepthChecks
end

function cellInTerrain( x,y,z )
	if x < c.MaxExtents.Min.X or x >= c.MaxExtents.Max.X then
		return false
	end

	if y < c.MaxExtents.Min.Y or y >= c.MaxExtents.Max.Y then
		return false
	end

	if z < c.MaxExtents.Min.Z or z >= c.MaxExtents.Max.Z then
		return false
	end

	return true
end

function breadthFillHelper(x,y,z,yDepthChecks)
	-- first, lets try and fill this cell
	if cellInTerrain( x,y,z ) and getMaterial( x, y, z) == emptyMaterial then
		SetCell(c,x,y,z,currentMaterial,0,0)
	end

	local cellsToFill = {}
	if cellInTerrain( x + 1,y,z ) and getMaterial( x + 1, y, z) == emptyMaterial then
		table.insert(cellsToFill,{xPos = x + 1, yPos = y, zPos = z})
	end
	if cellInTerrain( x - 1,y,z ) and getMaterial( x - 1, y, z) == emptyMaterial then
		table.insert(cellsToFill,{xPos = x - 1, yPos = y, zPos = z})
	end
	if cellInTerrain( x,y,z + 1) and getMaterial( x, y, z + 1) == emptyMaterial then
		table.insert(cellsToFill,{xPos = x, yPos = y, zPos = z + 1})
	end
	if cellInTerrain( x,y,z - 1) and getMaterial( x, y, z - 1) == emptyMaterial then
		table.insert(cellsToFill,{xPos = x, yPos = y, zPos = z - 1})
	end
	if cellInTerrain( x,y-1,z) and getMaterial( x, y-1, z) == emptyMaterial then
		table.insert(yDepthChecks,{xPos = x, yPos = y - 1, zPos = z})
	end

	for i = 1, #cellsToFill do
		SetCell(c,cellsToFill[i].xPos,cellsToFill[i].yPos,cellsToFill[i].zPos,currentMaterial,0,0)
	end

	if #cellsToFill <= 0 then
		return nil
	end

	return cellsToFill
end

function On()
	if self then
		self:Activate(true)
	end
	if toolbarbutton then
		toolbarbutton:SetActive(true)
	end
	if dragBar then
		dragBar.Visible = true
	end

	on = true
end

function Off()
	if toolbarbutton then
		toolbarbutton:SetActive(false)
	end
	if mouseHighlighter then
		mouseHighlighter:DisablePreview()
	end
	if dragBar then
		dragBar.Visible = false
	end

	on = false
end

mouseHighlighter.OnClicked = mouseUp

------
--GUI-
------
screenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
screenGui.Name = "FloodFillGui"

dragBar, containerFrame, helpFrame, closeEvent = RbxGui.CreatePluginFrame("Flood Fill",UDim2.new(0,163,0,195),UDim2.new(0,0,0,0),false,screenGui)
dragBar.Visible = false

helpFrame.Size = UDim2.new(0,200,0,190)
local textHelp = Instance.new("TextLabel",helpFrame)
textHelp.Name = "TextHelp"
textHelp.Font = Enum.Font.ArialBold
textHelp.FontSize = Enum.FontSize.Size12
textHelp.TextColor3 = Color3.new(1,1,1)
textHelp.Size = UDim2.new(1,-6,1,-6)
textHelp.Position = UDim2.new(0,3,0,3)
textHelp.TextXAlignment = Enum.TextXAlignment.Left
textHelp.TextYAlignment = Enum.TextYAlignment.Top
textHelp.BackgroundTransparency = 1
textHelp.TextWrap = true
textHelp.Text = 
[[
Quickly replace empty terrain cells with a selected material.  Clicking the mouse will cause any empty terrain cells around the point clicked to be filled with the current material, and will also spread to surrounding empty cells (including any empty cells below, but not above).

Simply click on a different material to fill with that material.  The floating paint bucket and cube indicate where filling will start.
]]

closeEvent.Event:connect(function() Off() end)

local terrainSelectorGui, terrainSelected, forceTerrainMaterialSelection = RbxGui.CreateTerrainMaterialSelector(UDim2.new(1, -10, 0, 184),UDim2.new(0, 5, 0, 5))
terrainSelectorGui.Parent = containerFrame
terrainSelectorGui.BackgroundTransparency = 1
terrainSelectorGui.BorderSizePixel = 0
terrainSelected.Event:connect(function ( newMaterial )
	currentMaterial = newMaterial
	if mouseHighlighter then
		mouseHighlighter:SetMaterial(currentMaterial)
	end
end)
forceTerrainMaterialSelection(Enum.CellMaterial.Water)

--------------------------
--SUCCESSFUL LOAD MESSAGE-
--------------------------
loaded = true
