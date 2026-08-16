--!nonstrict
-- Compact bar presentation; clicking it toggles the centered weather panel.

local weather = {
  status = "loading",
  status_text = "Waiting for Ecowitt data",
  outdoor = "—",
  humidity = "—",
  rain_active = false,
}

local function value(key)
  local result = weather[key]
  return type(result) == "string" and result ~= "" and result or "—"
end

local function render()
  local status = weather.status
  local outdoor = value("outdoor")
  local humidity = value("humidity")

  if status == "unavailable" then
    barWidget.setGlyph("cloud-off")
    barWidget.setColor("error")
    barWidget.setGlyphColor("error")
    barWidget.setText("Weather unavailable")
    barWidget.setTooltip(value("status_text"))
    return
  end

  barWidget.setGlyph(weather.rain_active == true and "cloud-rain" or "cloud-sun")
  barWidget.setColor(status == "partial" and "secondary" or "on_surface")
  barWidget.setGlyphColor(weather.rain_active == true and "primary" or "secondary")
  barWidget.setText(`{outdoor} · {humidity}`)
  barWidget.setTooltip(value("status_text"))
end

noctalia.state.watch("weather", function(valueFromService)
  if type(valueFromService) == "table" then
    weather = valueFromService
  end
  render()
end)

function update()
  render()
end

function onClick()
  noctalia.togglePanel("michael/ecowitt:panel")
end

render()
