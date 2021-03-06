local Path = {}
-- Создает новый объект класса Path
function Path.new()
	local obj = { point = { [0] = {} }, state = 0 } 
	Path.__index = Path 
	return setmetatable( obj, Path )
end
-- Добавляет точку пути. Аргументы: x, y, z - координаты в метрах; func - ссылка на функцию, выполняемую после достижения точки (необязательный аргумент).
function Path:addWaypoint( _x, _y, _z, _func, bound )
	local point = { x = _x, y = _y, z = _z, waypoint = true, bound = bound }
	table.insert( self.point, point )
	if _func then
		self.point[#self.point].func = _func
	end
end
-- Добавляет взлет на высоту, указанную в параметрах (Flight_common_takeoffAltitude). Аргументы: func - ссылка на функцию, выполняемую после достижения высоты взлета (необязательный аргумент).
function Path:addTakeoff( _func )
	table.insert( self.point, { takeoff = true } )
	if _func then
		self.point[#self.point].func = _func
	end
end
-- Добавляет посадку. Аргументы: func - ссылка на функцию, выполняемую после приземления (необязательный аргумент).
function Path:addLanding( _func )
	table.insert( self.point, { landing = true } )
	if _func then
		self.point[#self.point].func = _func
	end
end
-- Запуск выполнения полетного задания
function Path:start()
	sleep(1)
	if self.point[1].takeoff then
		self.state = 1
		ap.push(Ev.MCE_PREFLIGHT) 
		sleep(1)
		ap.push(Ev.MCE_TAKEOFF)
	end
end
-- Обработчик событий объекта пути. Должен быть добавлен в function callback(event) с передачей аргумента event. Как в примере ниже.
function Path:eventHandler( e )
	local change_state = false
	local obj_state = self.point[self.state]
	if e == Ev.ALTITUDE_REACHED and obj_state.takeoff then
		change_state = true
	elseif e == Ev.POINT_DECELERATION and obj_state.waypoint and not obj_state.bound then
		change_state = true
	elseif e == Ev.POINT_REACHED and obj_state.waypoint and obj_state.bound then
		change_state = true
	elseif e == Ev.POINT_DECELERATION and obj_state.landing then
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
-- Управление светодиодами
local led_count = 29
local matrix_count = 25
local led_offset = 4
local leds = Ledbar.new(led_count)
local colors = {	purple = 	{r=1, g=0, b=1}, 
					cyan = 		{r=0, g=1, b=1}, 
					yellow = 	{r=1, g=1, b=0}, 
					blue = 		{r=0, g=0, b=1}, 
					red = 		{r=1, g=0, b=0}, 
					green = 	{r=0, g=1, b=0}, 
					white = 	{r=1, g=1, b=1}, 
					black = 	{r=0, g=0, b=0}	}
-- Управление светодиодами на плате
local function setSysLeds( color )
	for i = 0, led_offset - 1, 1 do
		leds:set(i, color)
	end
end
local function getPointerSleep( time )
	return function()
		sleep (time)
	end
end
-- Возвращает указатель на функцию включения матрицы заданным цветом
local function getPointerLedsMatrix( color )
	return function()
		for i = led_offset, led_count, 1 do
			leds:set(i, color)
		end
	end
end
-- Таблица с указателями 
local pColors = {}
for k, v in pairs(colors) do 
	pColors[k] = getPointerLedsMatrix(v)
end
-- Инициализация вспомогательных функций
local board_number = boardNumber
local start_formations = false
-- local start_init_pose = false
-- local time_delta = 0
-- local time_start_global = 0
-- local time_transition = 5
local unpack = table.unpack	
local delta = TimeInfo.new("TimeDelta")
local launch = TimeInfo.new("LaunchTime")
-- Таблица с координатами и цветом
local letters = {
	{	-- 1 "C"
		{-2, 0.5, 0.5, pColors.black, false},
		{-1.6, -1, 1.0, pColors.blue, true},
		{-1.7, -1, 1.1, pColors.blue, false},
		{-1.9, -1, 1.1, pColors.blue, false},
		{-2.0, -1, 1.0, pColors.blue, false},
		{-2.0, -1, 0.6, pColors.blue, false},
		{-1.9, -1, 0.5, pColors.blue, false},
		{-1.7, -1, 0.5, pColors.blue, false},
		{-1.6, -1, 0.6, pColors.black, true},

		-- 2 "8"
		
		{-1.3, -1, 0.6, pColors.red, true},
		{-1.2, -1, 0.5, pColors.red, false},
		{-0.9, -1, 0.5, pColors.red, false},
		{-0.8, -1, 0.6, pColors.red, false},
		{-0.8, -1, 0.8, pColors.red, false},

		{-1.05, -1, 1.0, pColors.red, false},

		{-1.3, -1, 1.2, pColors.red, false},
		{-1.3, -1, 1.4, pColors.red, false},
		{-1.2, -1, 1.5, pColors.red, false},
		{-0.9, -1, 1.5, pColors.red, false},
		{-0.8, -1, 1.4, pColors.red, false},
		{-0.8, -1, 1.2, pColors.red, false},

		{-1.05, -1, 1.0, pColors.red, false},

		{-1.3, -1, 0.8, pColors.red, false},
		{-1.3, -1, 0.6, pColors.black, true},
		-- 2 "М"
		{-0.5, -1, 0.5, pColors.yellow, true},
		{-0.5, -1, 1.1, pColors.yellow, false},
		{-0.3, -1, 0.9, pColors.yellow, false},
		{-0.1, -1, 1.1, pColors.yellow, false},
		{-0.1, -1, 0.5, pColors.black, true},
		-- 3 "А"
		{0.1, -1, 0.5, pColors.purple, true},
		{0.3, -1, 1.1, pColors.purple, false},
		{0.5, -1, 0.5, pColors.black, true},
		{0.4, -1, 0.7, pColors.purple, true},
		{0.2, -1, 0.7, pColors.black, true},

		-- 4 "Р"
		{0.7, -1, 0.5, pColors.cyan, true},
		{0.7, -1, 1.1, pColors.cyan, false},
		{0.9, -1, 1.1, pColors.cyan, false},
		{1.0, -1, 0.9, pColors.cyan, false},
		{0.9, -1, 0.7, pColors.cyan, false},
		{0.7, -1, 0.7, pColors.black, true},

		-- 5 "T"
		{1.2, -1, 1.1, pColors.green, true},
		{1.6, -1, 1.1, pColors.black, true},
		{1.4, -1, 1.1, pColors.green, true},
		{1.4, -1, 0.5, pColors.black, true},

		-- 6 "А"
		{1.8, -1, 0.5, pColors.blue, true},
		{2.0, -1, 1.1, pColors.blue, false},
		{2.2, -1, 0.5, pColors.black, true},
		{2.1, -1, 0.7, pColors.blue, true},
		{1.9, -1, 0.7, pColors.black, true},
	}
}
function callback ( event )
	if (event == Ev.SYNC_START) then
		setSysLeds(colors.cyan)
		sleep (2)
		setSysLeds(colors.black)
		-- setSysLeds(colors.cyan)
		if start_formations then
			start_formations = false
			ap.push(Ev.MCE_LANDING)
		else
			-- leds:setMatrix(colors.purple)
			start_formations = true
			letter_path:start()
			-- time_start_global = launch:retrieve() + 5
			-- ap.push(Ev.MCE_PREFLIGHT)
			-- sleep(1)
			-- ap.push(Ev.MCE_TAKEOFF)	
		end	
	end
	letter_path:eventHandler(event)
end
function loop()
end
-- Создание Path для коптера по номеру борта
letter_path = Path.new()
letter_path:addTakeoff()
for _, v in ipairs(letters[board_number]) do
	letter_path:addWaypoint(unpack(v))
end
letter_path:addLanding(function () start_formations = false end)
