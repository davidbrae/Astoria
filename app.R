
#rsconnect::deployApp('~/Desktop/Astoria')

library(tidyverse)
library(sf)
library(leaflet)
library(shiny)
library(readxl)
library(units)

# First read mapdata to get the correct paddler-route associations
mapdata <- read_excel('mapdata.xlsx')

# Function to get paddler from mapdata based on year
get_paddler <- function(year) {
  paddler <- mapdata %>% 
    filter(Year == year) %>% 
    pull(Who) %>% 
    unique() %>% 
    paste(collapse = ", ")
  if(length(paddler) == 0) return("Unknown")
  return(paddler)
}

# Read and prepare route data with paddler information

kayak2009 <- st_read('Year 1.kmz') %>%
  mutate(Year = "2009",
         Who = get_paddler("2009"))
kayak2010 <- st_read('kay2010.kml') %>%
  mutate(Year = "2010",
         Who = get_paddler("2010"))
kayak2011 <- st_read('kay2011.kml') %>%
  mutate(Year = "2011",
         Who = get_paddler("2011"))
kayak2012 <- st_read('Trip 4.kmz') %>%
  mutate(Year = "2012",
         Who = get_paddler("2012"))
kayak2013 <- st_read('Trip 5 2013.kmz') %>%
  mutate(Year = "2013",
         Who = get_paddler("2013"))
kayak2014 <- st_read('trip 6 2014.kmz') %>%
  mutate(Year = "2014",
         Who = get_paddler("2014"))
kayak2015 <- st_read('Year 7.kmz') %>%
  mutate(Year = "2015",
         Who = get_paddler("2015"))
kayak2016 <- st_read('2016 Trip 8 .kml') %>%
  mutate(Year = "2016",
         Who = get_paddler("2016"))
kayak2017 <- st_read('kay2017.kml') %>%
  mutate(Year = "2017",
         Who = get_paddler("2017"))
kayak2018 <- st_read('kay2018.kml') %>%
  mutate(Year = "2018",
         Who = get_paddler("2018"))
kayak2019 <- st_read('Trip 11 2019.kmz') %>%
  mutate(Year = "2019",
         Who = get_paddler("2019"))
kayak2020 <- st_read('2020 trip 12.kmz') %>%
  mutate(Year = "2020",
         Who = get_paddler("2020"))
kayak2021 <- st_read('kay2021.kml') %>%
  mutate(Year = "2021",
         Who = "David,Adam,Evan")
kayak2021Ayal <- st_read('kay2021Ayal.kml') %>%
  mutate(Year = "2021",
         Who = "Ayal")
kayak2022 <- st_read('2022 Paddle trip.kmz') %>%
  mutate(Year = "2022",
         Who = get_paddler("2022"))
kayak2023 <- st_read('kay2023.kml') %>%
  mutate(Year = "2023",
         Who = get_paddler("2023"))
kayak2024 <- st_read('kay2024.kml') %>%
  mutate(Year = "2024",
         Who = get_paddler("2024"))
kayak2025 <- st_read('2025 Astoria final.kmz') %>%
  mutate(Year = "2025",
         Who = get_paddler("2025"))



# Combine routes and calculate distances
routes <- bind_rows(kayak2009,kayak2010,kayak2011, kayak2012,kayak2013,kayak2014,kayak2015,kayak2016,kayak2017,kayak2018,kayak2019,kayak2020, kayak2021,kayak2022, kayak2023, kayak2024,kayak2025 ) %>%
  select(Year, Who, geometry) %>%
  st_transform(crs = 4326) %>%
  mutate(
    distance_m = st_length(geometry),
    distance_mi = set_units(distance_m, "miles") %>% 
      drop_units() %>% 
      round(2)
  )

partialroutes <- kayak2021Ayal %>%
  select(Year, Who, geometry) %>%
  st_transform(crs = 4326) %>%
  mutate(
    distance_m = st_length(geometry),
    distance_mi = set_units(distance_m, "miles") %>% 
      drop_units() %>% 
      round(2)
  )

routes <- bind_rows(
  routes,
  partialroutes %>%
    st_transform(crs = 4326) %>%
    mutate(
      distance_m = st_length(geometry),
      distance_mi = set_units(distance_m, "miles") %>% 
        drop_units() %>% 
        round(2)
    )
)

# Starting GPS locations
StartingGPS <- data.frame(
  Start = c("Hawthorne Bridge", "Steel Bridge", "Swan Island Beach", "Swan Island Ramp", 
            "Kelly Point/Slough", "Vancouver Lake", "Vancouver", "Cathedral Park", 
            "North Side Hayden island", "South side Hayden Island", "Slough"),
  StartingLat = c(45.511417, 45.527467, 45.553331, 45.562384, 45.640222, 
                  45.678251, 45.619808, 45.586358, 45.624556, 45.607596, 45.585287),
  StartingLon = c(-122.668218, -122.670832, -122.698367, -122.706539, -122.763282, 
                  -122.741494, -122.667693, -122.761999, -122.697636, -122.674100, -122.667754)
)

campGPS <- data.frame(Camp = c("Deer Island South", "Lord Island South", "Lord Island Camp", "Crescent Island",
                               "Sandy Island", "Eureka Bar","Crims Island East", "Tenasillahe Island",
                               "Skamokawa", "Welch Island","St Helens","Deer Island North","Welch Island Middle","Sauvie Island", "Crims Island West",
                               "Goat Island"),
StartingLat = c(45.959806, 46.125887, 46.130979, 46.061292, 46.001866,46.164706, 46.172667, 46.206906, 46.269131,46.250800,45.866063,45.982428,46.231848,45.789885,46.183503,45.9282703),
StartingLon = c( -122.823294, -123.002234, -123.008939, -122.879766, -122.856665,-123.227184, -123.121533, -123.432986, -123.463218,-123.460140,-122.793066,-122.844789,-123.437523, -122.787754,-123.163179,-122.8140194))





# Merge and prepare data
mapdata <- mapdata %>% 
  left_join(StartingGPS, by = c("Start" = "Start")) %>%
  mutate(Year = as.character(Year))

camp_years <- mapdata %>%
  pivot_longer(
    cols = starts_with("Camp"),
    names_to = "camp_number",
    values_to = "Camp"
  ) %>%
  filter(!is.na(Camp)) %>%
  group_by(Camp) %>%
  summarise(Years = paste(sort(unique(Year)), collapse = ", "))
campGPS <- campGPS %>%
  left_join(camp_years, by = c( "Camp"))

# Create color palettes
paddler_palette <- colorFactor(palette = "Set3", 
                               domain = unique(unlist(strsplit(routes$Who, ", "))),
                               na.color = "gray")

# UI
ui <- fluidPage(
  tags$style(type = "text/css", "
    #map.leaflet-container {
      height: calc(100vh - 80px) !important;
    }
    .sidebar {
      background-color: white;
      padding: 10px;
      position: absolute;
      z-index: 1000;
      top: 10px;
      left: 10px;
      border-radius: 4px;
      box-shadow: 0 1px 5px rgba(0,0,0,0.2);
      max-width: 200px;
    }
  "),
  
  # Remove titlePanel to save space
  div(class = "sidebar",
      selectInput("paddler_filter", 
                  label = 'Who?', 
                  choices = c("", str_trim(unique(strsplit(paste(mapdata$Who, collapse = ","), ",")[[1]]))), 
                  selected = '', 
                  multiple = TRUE),
      selectInput("year_filter", 
                  label = 'Year?', 
                  choices = c("", sort(unique(mapdata$Year))), 
                  selected = '', 
                  multiple = TRUE)
  ),
  
  # Full-width map
  leafletOutput("map", width = "100%", height = "100vh")
)

# Server
server <- function(input, output, session) {
  
  # Filter data based on selected inputs
  filtered_data <- reactive({
    data <- mapdata
    
    if (length(input$paddler_filter) > 0) {
      data <- data %>% 
        filter(Reduce(`|`, lapply(input$paddler_filter, function(x) {
          grepl(x, Who, ignore.case = TRUE)
        })))
    }
    
    if (length(input$year_filter) > 0) {
      data <- data %>% 
        filter(Year %in% input$year_filter)
    }
    
    data %>%
      filter(!is.na(StartingLat) & !is.na(StartingLon)) %>%
      mutate(
        StartingLat = jitter(StartingLat, amount = 0.0001),
        StartingLon = jitter(StartingLon, amount = 0.0001)
      )
  })
  
  filtered_camps <- reactive({
    camps_data <- campGPS
    
    if (length(input$year_filter) > 0) {
      # Filter camps that were used in selected years
      camps_data <- camps_data %>%
        filter(map_lgl(Years, function(year_str) {
          any(input$year_filter %in% strsplit(year_str, ", ")[[1]])
        }))
    }
    
    if (length(input$paddler_filter) > 0) {
      # Get years associated with selected paddlers
      paddler_years <- mapdata %>%
        filter(Reduce(`|`, lapply(input$paddler_filter, function(x) {
          grepl(x, Who, ignore.case = TRUE)
        }))) %>%
        pull(Year)
      
      # Filter camps used in those years
      camps_data <- camps_data %>%
        filter(map_lgl(Years, function(year_str) {
          any(paddler_years %in% strsplit(year_str, ", ")[[1]])
        }))
    }
    
    camps_data
  })
  
  # Updated routes filtering to include paddler filter
  filtered_routes <- reactive({
    route_data <- routes
    
    if (length(input$paddler_filter) > 0) {
      route_data <- route_data %>% 
        filter(Reduce(`|`, lapply(input$paddler_filter, function(x) {
          grepl(paste0("\\b", x, "\\b"), Who, ignore.case = TRUE)  # Use word boundaries to match exact names
        })))
    }
    
    if (length(input$year_filter) > 0) {
      route_data <- route_data %>% 
        filter(Year %in% input$year_filter)
    }
    
    route_data %>%
      filter(!st_is_empty(geometry))
  })
  
  # Create base map
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addWMSTiles(
        "https://gis.charttools.noaa.gov/arcgis/rest/services/MCS/NOAAChartDisplay/MapServer/exts/MaritimeChartService/WMSServer",
        layers = "0",
        options = WMSTileOptions(
          format = "image/png",
          transparent = TRUE
        ),
        group = "NOAA ENC"
      ) %>%
      addWMSTiles(
        "https://gis.charttools.noaa.gov/arcgis/rest/services/MCS/ENC/MapServer/exts/MaritimeChartService/WMSServer",
        layers = "0",
        options = WMSTileOptions(
          format = "image/png",
          transparent = TRUE
        ),
        group = "NOAA RNC Charts"
      ) %>%
      addWMSTiles(
        "https://gis.charttools.noaa.gov/arcgis/rest/services/MarineNavigation/MapServer/WMSServer",
        layers = "0",
        options = WMSTileOptions(
          format = "image/png",
          transparent = TRUE
        ),
        group = "Marine Navigation"
      ) %>%
      addWMSTiles(
        "https://gis.charttools.noaa.gov/arcgis/rest/services/hydro/HydroSurvey/MapServer/WMSServer",
        layers = "0",
        options = WMSTileOptions(
          format = "image/png",
          transparent = TRUE
        ),
        group = "Hydro Survey"
      ) %>%
      addProviderTiles(providers$USGS.USTopo, group = "USGS.USTopo") %>%
      addLayersControl(
        baseGroups = c(
          "NOAA RNC Charts",
          "NOAA ENC",
          "Marine Navigation",
          "Hydro Survey",
          "USGS.USTopo"
        ),
        overlayGroups = c("Camp"),  # Add camps as an overlay
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      fitBounds(
        lng1 = min(c(-123.8313, mapdata$StartingLon, campGPS$StartingLon), na.rm = TRUE) - 0.02,
        lat1 = min(c(46.1879, mapdata$StartingLat, campGPS$StartingLat), na.rm = TRUE) - 0.02,
        lng2 = max(c(-123.8313, mapdata$StartingLon, campGPS$StartingLon), na.rm = TRUE) + 0.06,
        lat2 = max(c(46.1879, mapdata$StartingLat, campGPS$StartingLat), na.rm = TRUE) + 0.06
      )
  })
  # Update markers
  observe({
    req(filtered_data())
    
    leafletProxy("map", data = filtered_data()) %>%
      clearMarkers() %>%
      addCircleMarkers(
        ~StartingLon, ~StartingLat,
        popup = ~paste("Year:", Year, "<br>Who:", Who),
        color = 'blue',
        radius = 6,
        stroke = FALSE, 
        fillOpacity = 0.9
      ) %>%
      addCircleMarkers(
        -123.824906,46.190355, 
        popup = ~paste('Astoria'),
        color = 'blue',
        radius = 6,
        stroke = FALSE, 
        fillOpacity = 0.9
      ) 
      
      
  })
  
  # Single observe block for routes with both paddler and distance information
  observe({
    req(filtered_routes())
    
    route_data <- filtered_routes()
    
    leafletProxy("map") %>% clearShapes()
    
    for(i in 1:nrow(route_data)) {
      single_route <- route_data[i,]
      coords <- st_coordinates(single_route)
      
      # Determine if this is a partial route based on distance
      is_partial <- single_route$distance_mi < 20  # Adjust threshold as needed
      
      leafletProxy("map") %>%
        addPolylines(
          lng = coords[, "X"],
          lat = coords[, "Y"],
          color =  "black",
          weight = 3,
          opacity = 0.8,
          #dashArray = if(is_partial) "5,10" else NULL,
          layerId = paste0("route_", single_route$Year, "_", i),
          popup = paste(
            "<strong>Year:</strong>", single_route$Year,
            "<br><strong>Paddler(s):</strong>", single_route$Who,
            "<br><strong>Distance:</strong>", 
            single_route$distance_mi, "miles",
            if(is_partial) "<br><strong>(Partial Route)</strong>" else ""
          )
        )
    }
  })
  
  observe({
    req(filtered_camps())
    
    leafletProxy("map") %>%
      clearGroup("Camp") %>%  # Clear existing camp markers
      addCircleMarkers(
        data = filtered_camps(),  # Use filtered_camps() instead of campGPS
        lng = ~StartingLon,
        lat = ~StartingLat,
        group = "Camp",
        color = 'red',
        radius = 4,
        stroke = TRUE,
        weight = 2,
        fillOpacity = 0.7,
        popup = ~ifelse(
          !is.na(Years),
          paste0("<strong>", Camp, "</strong><br>Years: ", Years),
          paste0("<strong>", Camp, "</strong>")
        ),
        label = ~Camp
      )
  })
}

# Run the app
shinyApp(ui, server)