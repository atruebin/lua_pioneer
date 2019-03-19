-- Скрипт реализует вывод показаний лазерного дальномера

-- Упрощение вызова функции получения расстояния с лазерного дальномера
local range = Sensors.range
-- Количество светодиодов на базовой плате
local ledNumber = 4
-- Создание порта управления светодиодами
local leds = Ledbar.new(ledNumber)

-- Функция смены цвета светодиодов
local function changeColor(red, green, blue)
	-- Поочередное изменение цвета каждого из 4-х светодиодов
    for i = 0, ledNumber - 1, 1 do
        leds:set(i, red, green, blue)
    end
end

-- Функция, считывающая показание дальномера
local function getRange()
    -- Считываем показания в метрах с лазерного дальномера
    distance = range()
    -- Если показние не равно 8.19 м (величина, которую выдает датчик, когда расстояние больше, чем может определить дальномер)
    if (distance ~= 8.19) then
        -- Изменение яркости зеленого светодиода в зависимости от расстояния
        -- (~1.5 - максимальное расстояние для лазерного дальномера на плате адаптере и модуле оптического потока)
        r, g, b = 0, math.abs(distance / 1.5), 0
    else -- Зажигание красного светодиода в случае невозможности определить расстояние
        r, g, b = 1, 0, 0
    end
    -- Изменение цвета светодиодов на полученное значение
    changeColor(r, g, b)
end)

-- Обязательная функция обработки событий
function callback(event)
end

-- Создание таймера, вызывающего функцию каждую 0.1 секунды
getRangeTimer = Timer.new(0.1, function() getRange() end)
-- Запуск таймера
getRangeTimer:start()
