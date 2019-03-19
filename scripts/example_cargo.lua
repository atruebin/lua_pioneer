-- Скрипт реализует управление магнитом на модуле груза

-- инициализируем управление модулем груза порт PC3 на плате версии 1.2
local magneto = Gpio.new(Gpio.C, 3, Gpio.OUTPUT)
-- инициализируем управление модулем груза порт PA1 на плате версии 1.1 (необходимо раскомментировать строчку ниже и закомментировать строчку выше)
-- local magneto = Gpio.new(Gpio.A, 1, Gpio.OUTPUT)
-- задаем количество светодиодов (4 на базовой плате и еще 4 на модуле груза)
local led_number = 8 
-- инициализируем светодиоды
local leds = Ledbar.new(led_number) 
-- состояние модуля груза (изначально он находится во включенном состоянии)
local cargo_state = 1 

-- обязательная функция обработки событий
function callback(event)
end

cargoTimer = Timer.new(1, function () -- создаем таймер, который будет вызывать нашу функцию каждую секунуду
    if(cargo_state == 1) then  -- если модуль груза включен, то выключаем
        cargo_state = 0
        magneto:reset()
    else -- если выключен, то включаем
        cargo_state = 1
        magneto:set()
    end
    for i = 4, led_number - 1, 1 do -- если модуль включен, то включаем светодиоды на модуле груза (цвет 1, 1, 1), если выключен, то выключаем (цвет 0, 0, 0)
	    leds:set(i, cargo_state, cargo_state, cargo_state)
	end
end)
-- запускаем наш таймер
cargoTimer:start() 
