local TEMPERATURE_SENSOR_ID = 104
local G_MIN = 18
local G_MAX = 30
local FREQUENCY_MINS = 0.5

local value
local range


local cooling
local zoneOpen
local firstTime = true

local sliderVal

local obj

function QuickApp:iZone_zoneControl(mode)
    local iZoneCommandBody =  {ZoneMode = {Index = 1, Mode = mode}} -- Open Zone 2
    local url_iZoneCommand = "http://10.1.5.104/iZoneCommandV2"
    
    net.HTTPClient():request(url_iZoneCommand, {
        options={
            headers = { Accept = "application/json" },
            data =  json.encode(iZoneCommandBody),
            method = 'POST'
        },
        success = function(response)
            self:debug("response status:", response.status) 
            self:debug("headers:", response.headers["Connection"])
                self:debug("iZone response data:", json.encode(response.data)) 
        end,
        error = function(error)
            self:debug('error: ' .. error)
        end,
    })
end

function QuickApp:turnOn()
self:updateProperty("value", true)
self:iZone_zoneControl(1)
zoneOpen = true
-- self:debug("Switch was turned on")
end

function QuickApp:turnOff()
self:updateProperty("value", false)
self:iZone_zoneControl(2)
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
    fibaro.setGlobalVariable("zoneControlSettings", json.encode(obj))
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
    -- range = tonumber(string.sub(event.elementName, -1))
    range = tonumber(event.elementName)
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

    -- obj = json.decode(fibaro.getGlobalVariable("zoneControlSettings"))
    obj = json.decode(fibaro.getGlobalVariable("zoneControlSettings").."")
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


