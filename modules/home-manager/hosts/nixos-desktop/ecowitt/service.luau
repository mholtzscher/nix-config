--!nonstrict
-- Poll the local Ecowitt gateway and publish one shared weather snapshot.

local ENDPOINT = "http://10.69.69.113/get_livedata_info"
local POLL_INTERVAL_MS = 15000
local inFlight = false

local function emptyState(status, statusText, detail)
  return {
    status = status,
    status_text = statusText,
    detail = detail or "",
    outdoor = "—",
    feels = "—",
    humidity = "—",
    dewpoint = "—",
    wind = "—",
    gust = "—",
    max_gust = "—",
    direction = "—",
    rain_status = "Raining status unavailable",
    rain_active = false,
    rain_event = "—",
    rain_rate = "—",
    rain_hourly = "—",
    rain_daily = "—",
    rain_weekly = "—",
    rain_monthly = "—",
    rain_yearly = "—",
    solar = "—",
    uv = "—",
  }
end

local function publish(state)
  noctalia.state.set("weather", state)
end

local function numberFromValue(value)
  if type(value) == "number" then
    return value
  end
  if type(value) ~= "string" then
    return nil
  end
  local number = string.match(value, "[-+]?%d*%.?%d+")
  return number and tonumber(number) or nil
end

local function reading(list, id)
  if type(list) ~= "table" then
    return nil
  end
  for _, item in list do
    if type(item) == "table" and tostring(item.id) == id then
      return item
    end
  end
  return nil
end

local function hasReading(item)
  return item ~= nil and numberFromValue(item.val) ~= nil
end

local function formatTemperature(item)
  local value = item and numberFromValue(item.val)
  return value and string.format("%.1f°F", value) or "—"
end

local function formatHumidity(item)
  local value = item and numberFromValue(item.val)
  return value and string.format("%.0f%%", value) or "—"
end

local function formatSpeed(item)
  local value = item and numberFromValue(item.val)
  return value and string.format("%.1f mph", value) or "—"
end

local function rainStatus(item)
  if item == nil or item.val == nil then
    return "Raining status unavailable", false, false
  end

  local normalized = string.lower(tostring(item.val))
  if normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "rain" or normalized == "raining" or normalized == "on" then
    return "Raining", true, true
  end
  if normalized == "0" or normalized == "false" or normalized == "no" or normalized == "none" or normalized == "off" or normalized == "not raining" then
    return "Not raining", false, true
  end
  return "Raining status unavailable", false, false
end

local function formatRainRate(item)
  local value = item and numberFromValue(item.val)
  return value and string.format("%.2f in/hr", value) or "—"
end

local function formatRainAmount(item)
  local value = item and numberFromValue(item.val)
  return value and string.format("%.2f in", value) or "—"
end

local function formatDirection(item)
  local value = item and numberFromValue(item.val)
  return value and string.format("%.0f°", value) or "—"
end

local function formatSolar(item)
  local value = item and numberFromValue(item.val)
  return value and string.format("%.1f W/m²", value) or "—"
end

local function formatUv(item)
  local value = item and numberFromValue(item.val)
  return value and string.format("%.1f", value) or "—"
end

local function publishUnavailable(message)
  publish(emptyState("unavailable", "Weather unavailable", message))
end

local function poll()
  if inFlight then
    return
  end
  inFlight = true

  local accepted = noctalia.http({ url = ENDPOINT }, function(response)
    inFlight = false

    if not response.ok then
      publishUnavailable("Could not reach the Ecowitt gateway.")
      return
    end
    if response.status < 200 or response.status >= 300 then
      publishUnavailable(`Ecowitt gateway returned HTTP {response.status}.`)
      return
    end

    local data, decodeError = noctalia.json.decode(response.body)
    if type(data) ~= "table" then
      publishUnavailable(decodeError and "Ecowitt returned invalid JSON." or "Ecowitt returned no data.")
      return
    end

    local outdoor = reading(data.common_list, "0x02")
    local feels = reading(data.common_list, "3")
    local humidity = reading(data.common_list, "0x07")
    local dewpoint = reading(data.common_list, "0x03")
    local wind = reading(data.common_list, "0x0B")
    local gust = reading(data.common_list, "0x0C")
    local maxGust = reading(data.common_list, "0x19")
    local direction = reading(data.common_list, "0x0A")
    local solar = reading(data.common_list, "0x15")
    local uv = reading(data.common_list, "0x17")
    local rainStatusReading = reading(data.piezoRain, "srain_piezo")
    local rainEvent = reading(data.piezoRain, "0x0D")
    local rainRate = reading(data.piezoRain, "0x0E")
    local rainHourly = reading(data.piezoRain, "0x7D")
    local rainDaily = reading(data.piezoRain, "0x7C")
    local rainWeekly = reading(data.piezoRain, "0x10")
    local rainMonthly = reading(data.piezoRain, "0x11")
    local rainYearly = reading(data.piezoRain, "0x12")
    local rainStatusText, rainActive, rainStatusAvailable = rainStatus(rainStatusReading)

    local state = {
      status = "ok",
      status_text = "Live Ecowitt data",
      detail = "",
      outdoor = formatTemperature(outdoor),
      feels = formatTemperature(feels),
      humidity = formatHumidity(humidity),
      dewpoint = formatTemperature(dewpoint),
      wind = formatSpeed(wind),
      gust = formatSpeed(gust),
      max_gust = formatSpeed(maxGust),
      direction = formatDirection(direction),
      rain_status = rainStatusText,
      rain_active = rainActive,
      rain_event = formatRainAmount(rainEvent),
      rain_rate = formatRainRate(rainRate),
      rain_hourly = formatRainAmount(rainHourly),
      rain_daily = formatRainAmount(rainDaily),
      rain_weekly = formatRainAmount(rainWeekly),
      rain_monthly = formatRainAmount(rainMonthly),
      rain_yearly = formatRainAmount(rainYearly),
      solar = formatSolar(solar),
      uv = formatUv(uv),
    }

    local complete = hasReading(outdoor) and hasReading(feels) and hasReading(humidity) and hasReading(dewpoint)
      and hasReading(wind) and hasReading(gust) and hasReading(maxGust) and hasReading(direction)
      and hasReading(solar) and hasReading(uv) and rainStatusAvailable and hasReading(rainEvent)
      and hasReading(rainRate) and hasReading(rainHourly) and hasReading(rainDaily)
      and hasReading(rainWeekly) and hasReading(rainMonthly) and hasReading(rainYearly)
    if not hasReading(outdoor) then
      state.status = "unavailable"
      state.status_text = "Weather unavailable"
      state.detail = "Outdoor temperature was not present in the response."
    elseif not complete then
      state.status = "partial"
      state.status_text = "Some readings unavailable"
      state.detail = "The Ecowitt gateway returned incomplete data."
    end

    publish(state)
  end)

  if not accepted then
    inFlight = false
    publishUnavailable("The weather request could not be started.")
  end
end

noctalia.setUpdateInterval(POLL_INTERVAL_MS)
publish(emptyState("loading", "Waiting for Ecowitt data", "Polling the local gateway every 15 seconds."))
poll()

function update()
  poll()
end
