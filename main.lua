-- local THIS_QUICKAPP_ID = 24
local TEMPERATURE_SENSOR_ID = 44
local G_MIN = 18
local G_MAX = 30
local FREQUENCY_MINS = 0.1
local GLOBAL_OBJ = "zoneControlSettings"

local value
local range


local cooling
local zoneOpen
local firstTime = true

local sliderVal

local obj

function QuickApp:turnOn()
self:updateProperty("value", true)
zoneOpen = true
-- self:debug("Switch was turned on")
end

function QuickApp:turnOff()
self:updateProperty("value", false)
zoneOpen = false
-- self:debug("Switch was turned off")
end

function QuickApp:increase()
    value = value + 0.5
    self:updateView("button3_2","text", value.."")
    self:updateView("T_label","text","Zone Thermostat, Desired Temp: " ..value)
    firstTime = true

    obj.sliderVal = value
    self:setGlobal()
end

function QuickApp:doNothing()
    self:debug("I am designed to do nothing")
end

function QuickApp:decrease()
    value = value - 0.5
    self:updateView("button3_2","text",  value.."")
    self:updateView("T_label","text","Zone Thermostat, Desired Temp: " ..value)
    firstTime = true

    obj.sliderVal = value
    self:setGlobal()
end

function QuickApp:checkOnOFF()
    local function loop()
        local tmpSensor, sStatus = api.get('/devices/' ..TEMPERATURE_SENSOR_ID)
        -- if (tmpSensor.properties.value < value - 1) then
        --     if cooling then zoneOpen = false else zoneOpen = true end
        -- elseif (tmpSensor.properties.value > value + 1) then
        --     if cooling then zoneOpen = true else zoneOpen = false end
        -- end
        -- self:debug("range ",range)
        -- self:debug("value ", value)

        if firstTime then
            if (tmpSensor.properties.value > value and cooling) then
                zoneOpen = true
                -- self:debug("Here")
            elseif (tmpSensor.properties.value < value and not cooling) then
                zoneOpen = true
            else
                zoneOpen = false
                firstTime = false
            end
            goto next
        end

        if (tmpSensor.properties.value <= (value + range) and cooling) then
            zoneOpen = false
        elseif (tmpSensor.properties.value >= (value - range) and not cooling) then
            zoneOpen = false
        else
            zoneOpen = true
            firstTime = true
        end

        ::next::

        self:debug("Should the zone be opened?", zoneOpen)
        self:debug("Desired value:", value, "Actual temp:", tmpSensor.properties.value)
        if zoneOpen then self:turnOn() else self:turnOff() end

        setTimeout(loop, FREQUENCY_MINS * 60 * 1000)
    end

    setTimeout(loop, 0)
end

function QuickApp:setGlobal()
    -- self:debug(obj.foo)
    fibaro.setGlobalVariable(GLOBAL_OBJ, json.encode(obj))
end

function QuickApp:onButtonClicked(event)
    -- self:debug("Clicked")
    cooling = not cooling
    if cooling then self:updateView("button1", "text", "Currently Cooling") else self:updateView("button1", "text", "Currently Heating") end

    obj.cooling = cooling
    self:setGlobal()
    -- self:checkOnOFF()
    -- self:setGlobal()
end


-- This function is here to help with debugging, can get rid of it later
-- function QuickApp:dump(o)
--    if type(o) == 'table' then
--       local s = '{ '
--       for k,v in pairs(o) do
--          if type(k) ~= 'number' then k = '"'..k..'"' end
--          s = s .. '['..k..'] = ' .. dump(v) .. ','
--       end
--       return s .. '} '
--    else
--       return tostring(o)
--    end
-- end

function QuickApp:onRangeChanged(event)
    range = tonumber(string.sub(event.elementName, -1))
    self:updateView("Range_label","text", "Temperature Range: " ..range)
    self:debug("The range has been changed to: " ..range)
    -- self:checkOnOFF()
    firstTime = true
    obj.range = range
    self:setGlobal()
end

-- function QuickApp:onSliderChanged(event)
--     sliderVal = event.values[1]
--     value = self:map(event.values[1], G_MIN, G_MAX)
--     self:updateView("T_label","text", "Zone Thermostat, Desired Temp: " ..value)
--     firstTime = true

--     obj.sliderVal = sliderVal
--     self:setGlobal()
--     -- self:checkOnOFF()
-- end

function QuickApp:onInit()

    -- obj = json.decode(fibaro.getGlobalVariable(GLOBAL_OBJ))
    obj = json.decode(fibaro.getGlobalVariable(GLOBAL_OBJ).."")
    -- self:debug(obj.foo)
    value = obj.sliderVal
    range = obj.range
    cooling = obj.cooling

    local tmpSensor, sStatus = api.get('/devices/' ..TEMPERATURE_SENSOR_ID)
    local T_lbl = "Zone Thermostat, Desired Temp: " ..value
    self:updateView("T_label","text",T_lbl)
    self:updateView("Range_label","text", "Temperature Range: " ..range)
    self:updateView("button3_1","text","-")
    self:updateView("button3","text","+")
    self:updateView("button3_2","text", value.."")
    if cooling then self:updateView("button1", "text", "Currently Cooling") else self:updateView("button1", "text", "Currently Heating") end
    -- self:updateView("button1", "text", "Currently Cooling")
    self:checkOnOFF()
end


