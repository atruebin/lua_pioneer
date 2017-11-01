
local Path = {}

function Path.new()
	local obj = { point = { [0] = {} }, state = 0 } 
	Path.__index = Path 
	return setmetatable( obj, Path )
end


function Path:addWaypoint( _x, _y, _z )
	local point = {x = _x, y = _y, z = _z, waypoint = true}
	table.insert( self.point, point )
end


function Path:addTakeoff()
	table.insert( self.point, { takeoff = true } )
end


function Path:addLanding()
	table.insert( self.point, { landing = true } )
end


function Path:addFuncForPoint( _func, point_index )
	if self.point[point_index] then
		self.point[point_index].func = _func
	end
end


function Path:addFunc( _func )
	self.point[#self.point].func = _func
end


function Path:Start()
	sleep(1)
	if self.point[1].takeoff then
		self.state = 1
		ap.push(Ev.MCE_PREFLIGHT) 
		sleep(1)
		ap.push(Ev.MCE_TAKEOFF)
	end
end


function Path:eventHandler( e )

	local change_state = false
	local obj_state = self.point[self.state]

	if e == Ev.ALTITUDE_REACHED and obj_state.takeoff then
		change_state = true
	elseif e == Ev.POINT_REACHED and obj_state.waypoint then
		change_state = true
	elseif e == Ev.POINT_REACHED and obj_state.landing then
		change_state = true
	elseif e == Ev.COPTER_LANDED and ( obj_state.landing or obj_state.takeoff ) then
		change_state = true
	end

	if change_state then

		if obj_state.func then 
			obj_state.func()
		end

		if self.state < #self.point then
			self.state = self.state + 1
			obj_state = self.point[self.state]
		else 
			self.state = 0
		end

		if obj_state.waypoint then
			ap.goToLocalPoint( {x = self.point[self.state].x, y = self.point[self.state].y, z = self.point[self.state].z} )
		elseif obj_state.takeoff then
			ap.push(Ev.MCE_PREFLIGHT) 
			sleep(1)
			ap.push(Ev.MCE_TAKEOFF)
		elseif obj_state.landing then
			ap.push(Ev.MCE_LANDING)
		end

	end
end


function callback( event )
	pn:eventHandler(event)
end

function loop()
end

-- ###### ^ Module above ^ ######

--[[
local action = {
	["ACTION_1"] = function()
		-- Function block
	end
}

p:addFunc(action["ACTION_1"])
]]--

function func_1 ()
	local f = "Test function"
	print(f)
end

pn = Path.new()

pn:addTakeoff()
pn:addWaypoint(1, 2, 1.2)
pn:addWaypoint(2, 2, 1.2)
pn:addFunc(
	function()
		local f = "Test function 2"
		print(f)
	end
	)
pn:addWaypoint(2, 1, 1.2)
pn:addLanding()
pn:addTakeoff()
pn:addWaypoint(2, 2, 1.2)
pn:addLanding()

pn:addFuncForPoint(func_1, 8)

pn:Start()

