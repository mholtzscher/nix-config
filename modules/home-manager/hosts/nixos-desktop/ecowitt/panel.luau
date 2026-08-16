--!nonstrict
-- Weather-first centered panel for the Ecowitt bar widget.

local weather = {
  status = "loading",
  status_text = "Waiting for Ecowitt data",
  detail = "",
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

local function value(key)
  local result = weather[key]
  return type(result) == "string" and result ~= "" and result or "—"
end

local function metric(glyph, label, reading)
  return ui.column({ gap = 4, flexGrow = 1, fill = "surface_variant/0.45", radius = 12, padding = 12 }, {
    ui.row({ gap = 6, align = "center" }, {
      ui.glyph({ name = glyph, size = 15, color = "on_surface_variant" }),
      ui.label({ text = label, fontSize = 12, color = "on_surface_variant" }),
    }),
    ui.label({ text = reading, fontSize = 18, fontWeight = "bold", color = "on_surface" }),
  })
end

local function render()
  local status = weather.status
  local statusColor = status == "unavailable" and "error" or status == "partial" and "secondary" or "on_surface_variant"
  local rainStatus = value("rain_status")
  local rainStatusAvailable = rainStatus ~= "—" and rainStatus ~= "Raining status unavailable"
  local rainAvailable = rainStatusAvailable or value("rain_event") ~= "—" or value("rain_rate") ~= "—"
  local rainColor = not rainAvailable and "error" or weather.rain_active == true and "primary" or "secondary"
  local rainFill = not rainAvailable and "error/0.12" or weather.rain_active == true and "primary/0.18" or "secondary/0.12"

  panel.render(ui.column({ flexGrow = 1, gap = 12, padding = 18 }, {
    ui.row({ align = "center", justify = "space_between", gap = 8 }, {
      ui.column({ gap = 2, flexGrow = 1 }, {
        ui.label({ text = "Ecowitt Weather", fontSize = 18, fontWeight = "bold", color = "on_surface" }),
        ui.label({ text = value("status_text"), fontSize = 12, color = statusColor }),
      }),
      ui.button({ glyph = "close", onClick = "onCloseClicked" }),
    }),

    ui.scroll({ flexGrow = 1, gap = 12, align = "stretch" }, {
      ui.column({ gap = 4, fill = "primary/0.14", radius = 16, padding = 16 }, {
        ui.label({ text = "Outdoor", fontSize = 13, fontWeight = "bold", color = "primary" }),
        ui.label({ text = value("outdoor"), fontSize = 42, fontWeight = "bold", color = status == "unavailable" and "error" or "primary" }),
        ui.label({ text = `Feels like {value("feels")}`, fontSize = 15, color = "on_surface_variant" }),
      }),

      ui.label({ text = value("detail"), fontSize = 12, color = statusColor, visible = value("detail") ~= "—" and value("detail") ~= "" }),

      ui.row({ gap = 10, align = "stretch" }, {
        metric("droplet", "Humidity", value("humidity")),
        metric("temperature", "Dew point", value("dewpoint")),
      }),
      ui.column({ gap = 8, fill = "surface_variant/0.25", radius = 14, padding = 12 }, {
        ui.label({ text = "Wind", fontSize = 13, fontWeight = "bold", color = "on_surface_variant" }),
        ui.row({ gap = 10, align = "stretch" }, {
          metric("wind", "Speed", value("wind")),
          metric("wind", "Gust", value("gust")),
        }),
        ui.row({ gap = 10, align = "stretch" }, {
          metric("wind", "Daily max gust", value("max_gust")),
          metric("compass", "Direction", value("direction")),
        }),
      }),

      ui.column({ gap = 8, fill = rainFill, radius = 14, padding = 14 }, {
        ui.row({ gap = 8, align = "center" }, {
          ui.glyph({ name = weather.rain_active == true and "cloud-rain" or "umbrella", size = 18, color = rainColor }),
          ui.label({ text = "Rain activity", fontSize = 13, fontWeight = "bold", color = rainColor }),
        }),
        ui.label({ text = value("rain_status"), fontSize = 24, fontWeight = "bold", color = rainColor }),
        ui.row({ gap = 10, align = "stretch" }, {
          metric("droplet", "Event", value("rain_event")),
          metric("gauge", "Rate", value("rain_rate")),
        }),
      }),

      ui.column({ gap = 8, fill = "surface_variant/0.25", radius = 14, padding = 12 }, {
        ui.label({ text = "Rain totals", fontSize = 13, fontWeight = "bold", color = "on_surface_variant" }),
        ui.row({ gap = 10, align = "stretch" }, {
          metric("calendar", "Hourly", value("rain_hourly")),
          metric("calendar", "Daily", value("rain_daily")),
        }),
        ui.row({ gap = 10, align = "stretch" }, {
          metric("calendar", "Weekly", value("rain_weekly")),
          metric("calendar", "Monthly", value("rain_monthly")),
        }),
        ui.row({ gap = 10, align = "stretch" }, {
          metric("calendar", "Yearly", value("rain_yearly")),
        }),
      }),

      ui.row({ gap = 10, align = "stretch" }, {
        metric("sun", "Solar radiation", value("solar")),
        metric("uv-index", "UV index", value("uv")),
      }),
    }),
  }))
end

function onOpen(_context)
  local current = noctalia.state.get("weather")
  if type(current) == "table" then
    weather = current
  end
  render()
end

noctalia.state.watch("weather", function(valueFromService)
  if type(valueFromService) == "table" then
    weather = valueFromService
    render()
  end
end)

function onCloseClicked()
  panel.close()
end
