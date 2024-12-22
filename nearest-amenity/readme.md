# Hexabot Nearby Places Plugin

A powerful Hexabot plugin that helps users find nearby places using OpenStreetMap and Overpass API. This plugin enables your chatbot to provide location-based recommendations for various amenities like cafes, restaurants, pharmacies, hospitals, and more.

## Features

- 🔍 Find nearby places based on user location
- 📍 Integration with OpenStreetMap and Overpass API
- 📏 Configurable search radius
- 🗺️ Direct links to OpenStreetMap locations
- 📱 Mobile-friendly implementation
- 🌐 Support for various amenity types
- 📊 Distance calculations in kilometers
- 🔄 Automatic sorting by distance

## Prerequisites

- Node.js and npm/yarn
- Hexabot project
- Internet connection (for API access)
- Mobile app with location services capability

## Installation

1. Navigate to your Hexabot project's plugins directory:

```bash
cd your-hexabot-project/extensions/plugins
```

2. Clone or copy the plugin files:

```bash
git clone https://github.com/yourusername/hexabot-plugin-nearby-places.git
# or manually copy the files into hexabot-plugin-nearby-places directory
```

## Configuration

The plugin can be configured through the `settings.ts` file. Available settings:

- `request_location_message`: Message shown when requesting user location
- `error_message`: Message shown when an error occurs
- `search_radius`: Search radius in meters (default: 1000)

## Supported Amenity Types

The plugin supports various OpenStreetMap amenity types, including:

- restaurant
- hospital
- pharmacy
- atm
- bank
- cafe
- school
- gas station (fuel)
- police
- parking

Custom amenity types are also supported as long as they match OpenStreetMap tags.

## Usage

### Basic Commands

Users can trigger the plugin using these patterns:

- "find nearest [amenity]"
- "nearby [amenity]"
- "where is [amenity]"
- "find [amenity]"

Examples:

```
User: "find nearest hospital"
User: "nearby restaurant"
User: "where is pharmacy"
User: "find atm"
```

### Response Format

The plugin returns up to 5 nearest places, sorted by distance. Each result includes:

- Place name
- Distance in kilometers
- Address (Using OSM)
- Link to OpenStreetMap location

Example response:

```
Here are the nearest places I found:

1. Central Hospital
   Distance: 0.75 km
   Address: 123 Medical Drive
   Map: https://www.openstreetmap.org/?mlat=...

2. Medical Center
   Distance: 1.20 km
   Address: 456 Health Avenue
   Map: https://www.openstreetmap.org/?mlat=...
```

## Mobile Integration

### Location Permissions

Ensure your mobile app:

1. Requests location permissions from the user
2. Handles permission states appropriately
3. Provides accurate location data to the chatbot

### Location Data Format

Location data should be provided in the context metadata:

```typescript
{
  metadata: {
    location: {
      latitude: number;
      longitude: number;
      accuracy?: number;
      timestamp: number;
    }
  }
}
```

### Map Links

The plugin generates OpenStreetMap links that can be:

- Opened in a web browser
- Handled by a native map application
- Displayed in an in-app map view

## Error Handling

The plugin handles various error cases:

- Missing location data
- API failures
- Invalid amenity types
- No results found

## API Credits

This plugin uses:

- OpenStreetMap data © OpenStreetMap contributors
- Overpass API
