-- Данный скрипт реализует полет по заданным точкам в системе позиционирования

-- Упрощение вызова функции распаковки таблиц из модуля table
local unpack = table.unpack

-- Первый светодиод
local ledFirst = 4
-- Последний светодиод
local ledLast = 29
-- Создание порта управления светодиодами
local leds = Ledbar.new(ledLast)

-- Функция смены цвета светодиодов
local function changeColor(color)
    -- Поочередное изменение цвета каждого из 4-х светодиодов
    for i=ledFirst, ledLast, 1 do
        leds:set(i, unpack(color))
    end
end

-- Таблица цветов в формате RGB для передачи в функцию changeColor
local colors = {
        {0.5, 0,   0  }, -- красный
        {0,   0.5, 0  }, -- зеленый
        {0,   0,   0.5}, -- синий
        {0.5, 0.5, 0  }, -- желтый
        {0.5, 0,   0.5}, -- фиолетовый
        {0,   0.5, 0.5}, -- бирюзовый
        {0.5, 0.5, 0.5}, -- белый
        {0,   0,   0  }  -- черный/отключение светодиодов
}

-- Инициализация таблицы точек
local points = {}

--[[
     ________L______
    |____T____      |
    |         |     |
  __|  _      |  _  |
 A  | / \     | / \ |
  __|/   \    |/   \| -->Dir
          \   /
           \_/
--]]

-- Амплитуда синусоиды в метрах
local sinA = 0.5
-- Период синусоиды в метрах
local sinT = 1
-- Протяженность синусоиды в метрах
local sinL = 1.5
-- Высота полета по синусоиде
local sinH = 0.6
-- Количество точек на один период синусоиды
local sinNumPerT = 20
-- Направление синусоиды (Y -- вперёд (по-умолчанию), 'X','x' -- вправо)
local sinDir = 'Y'
-- Количество циклов
local sinCyclesNum = 3

----------------------------
-- Шаг точек вдоль синусоиды
local sinStep = sinT/sinNumPerT
-- Общее количество точек на синусоиду
local sinNum = math.floor(sinNumPerT * (sinL / sinT))

-- Генерация точек синусоиды
for i = 0, sinNum, 1 do
    if sinDir == 'X' or sinDir == 'x' then
        x = i * sinStep
        y = sinA * math.sin(2*math.pi/sinT * x)
    else
        y = i * sinStep
        x = sinA * math.sin(2*math.pi/sinT * y)
    end
    points[#points+1] = {x, y, sinH}
end

-- Генерация точек синусоиды
for i = sinNum, 0, -1 do
    if sinDir == 'X' or sinDir == 'x' then
        x = i * sinStep
        y = -sinA * math.sin(2*math.pi/sinT * x)
    else
        y = i * sinStep
        x = -sinA * math.sin(2*math.pi/sinT * y)
    end
    points[#points+1] = {x, y, sinH}
end

-- Счетчик точек
local currPoint = 1
-- Счетчик циклов
local currCycle = 1

-- Функция, изменяющая цвет светодиодов и выполняющая полет к следующей точке
local function nextPoint()
    -- Текущий цвет. % - остаток от деления, # - размер таблицы. Такая конструкция использована,
    -- чтобы цвета продолжали меняться, даже если точек больше, чем цветов в таблице
    currColor = ((currPoint - 1) % (#colors - 2)) + 1
    -- Изменение цвета светодиодов                                                         
    changeColor(colors[currColor])
    -- Полет к текущей точке, если её номер не больше количества заданных точек
    if (currPoint <= #points) and (currCycle <= sinCyclesNum) then
        -- Команда полета к точке в системе позиционирования
        ap.goToLocalPoint(unpack(points[currPoint]))
        -- Инкрементация переменной текущей точки
        currPoint = currPoint + 1
    -- Переход к следующему циклу, если в текущем цикле пройдены все точки
    elseif (currCycle <= sinCyclesNum) then
    	currPoint = 1
    	currCycle = currCycle + 1
    	nextPoint()
    -- Посадка, если номер текущего цикла больше заданного количества циклов
    else
        Timer.callLater(1, function()
            -- Команда на посадку
            ap.push(Ev.MCE_LANDING)
        end)
    end
end

-- Функция обработки событий, автоматически вызывается автопилотом
function callback(event)
    -- Когда коптер приближается к точке, переходим к следующей
    if (event == Ev.POINT_DECELERATION or event == Ev.TAKEOFF_COMPLETE) then
        if currPoint == 1 then
        	Timer.callLater(1, function() nextPoint() end)
        else
        	nextPoint()
        end
    end
    -- Когда коптер приземлился, выключаем светодиоды
    if (event == Ev.COPTER_LANDED) then
        changeColor(colors[8])
    end
end


-- Предстартовая подготовка
ap.push(Ev.MCE_PREFLIGHT)
-- Зажигание светодиодов белым цветом
changeColor(colors[7])
-- Таймер, через 2 секунды вызывающий функцию взлета
Timer.callLater(2, function() ap.push(Ev.MCE_TAKEOFF) end)
