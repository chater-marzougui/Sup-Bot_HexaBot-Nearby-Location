// index.plugin.ts
import { Block } from '@/chat/schemas/block.schema';
import { Context } from '@/chat/schemas/types/context';
import {
  OutgoingMessageFormat,
  StdOutgoingEnvelope,
  StdOutgoingTextEnvelope,
} from '@/chat/schemas/types/message';
import { BlockService } from '@/chat/services/block.service';
import { BaseBlockPlugin } from '@/plugins/base-block-plugin';
import { PluginService } from '@/plugins/plugins.service';
import { PluginBlockTemplate } from '@/plugins/types';
import { SettingService } from '@/setting/services/setting.service';
import { Injectable } from '@nestjs/common';
import axios from 'axios';

import SETTINGS from './settings';

interface LocationData {
  latitude: number;
  longitude: number;
  accuracy?: number;
  timestamp: number;
}

interface Place {
  name: string;
  distance: number;
  address: string;
  type: string;
  coordinates: [number, number];
}

@Injectable()
export class NearbyPlacesPlugin extends BaseBlockPlugin<typeof SETTINGS> {
  template: PluginBlockTemplate = {
    patterns: ['find nearest', 'nearby', 'where is', 'find'],
    starts_conversation: true,
    name: 'Nearby Places Plugin',
  };

  constructor(
    pluginService: PluginService,
    private readonly blockService: BlockService,
    private readonly settingService: SettingService,
  ) {
    super('nearby-places-plugin', pluginService);
  }

  getPath(): string {
    return __dirname;
  }

  private async queryOverpass(
    lat: number,
    lon: number,
    keyword: string,
    radius: number = 1000,
  ): Promise<Place[]> {
    try {
      console.log('Querying Overpass API for:', keyword);
      const query = `
        [out:json][timeout:25];
        (
          // Search in amenity
          node["amenity"="${keyword}"](around:${radius},${lat},${lon});
          
          // Search in leisure
          node["leisure"="${keyword}"](around:${radius},${lat},${lon});
          
          // Search in natural
          node["natural"="${keyword}"](around:${radius},${lat},${lon});
          
          // Search in landuse
          way["landuse"="${keyword}"](around:${radius},${lat},${lon});
          
          // Search in tourism
          node["tourism"="${keyword}"](around:${radius},${lat},${lon});
          
          // Search in historic
          node["historic"="${keyword}"](around:${radius},${lat},${lon});
          
          // Search in shop
          node["shop"="${keyword}"](around:${radius},${lat},${lon});
          
          // Search in building
          way["building"="${keyword}"](around:${radius},${lat},${lon});
          
          // Search in public services
          node["emergency"="${keyword}"](around:${radius},${lat},${lon});
        );
        out body;
        >;
        out skel qt;
    `;

      const response = await axios.post(
        'https://overpass-api.de/api/interpreter',
        query,
        {
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        },
      );

      const places = response.data.elements
        .filter((element) => element.tags)
        .map((element) => ({
          name: element.tags.name || 'Unnamed',
          type:
            element.tags.amenity ||
            element.tags.leisure ||
            element.tags.natural ||
            'Unknown',
          address: '',
          coordinates: [element.lat, element.lon],
          distance: this.calculateDistance(lat, lon, element.lat, element.lon),
        }))
        .sort((a, b) => a.distance - b.distance)
        .slice(0, 5);

      for (const place of places) {
        place.address = await this.getExactLocation(
          place.coordinates[0],
          place.coordinates[1],
        );
      }

      return places;
    } catch (error) {
      console.error('Overpass API error:', error);
      throw new Error('Failed to fetch nearby places');
    }
  }

  private async getExactLocation(lat: number, long: number): Promise<string> {
    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${long}`,
        {
          method: 'GET',
          headers: {
            Accept: 'application/json',
            'User-Agent': 'hexa-bot/0.1.0',
          },
        },
      );

      if (response.ok) {
        const jsonData = await response.json();
        return jsonData.display_name;
      } else {
        throw new Error(`Failed to load location data: ${response.status}`);
      }
    } catch (e) {
      return 'Address unavailable';
    }
  }

  private calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371e3; // Earth's radius in meters
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  private extractAmenityFromMessage(message: string): string {
    const keywords = ['find nearest', 'nearby', 'where is', 'find'];
    let amenity = message.toLowerCase();

    for (const keyword of keywords) {
      amenity = amenity.replace(keyword, '').trim();
    }

    // Map common terms to OSM amenity tags
    const amenityMap: { [key: string]: string } = {
      restaurant: 'restaurant',
      hospital: 'hospital',
      pharmacy: 'pharmacy',
      atm: 'atm',
      bank: 'bank',
      cafe: 'cafe',
      school: 'school',
      'gas station': 'fuel',
      police: 'police',
      parking: 'parking',
    };

    return amenityMap[amenity] || amenity;
  }

  private formatPlacesResponse(places: Place[]): string {
    if (places.length === 0) {
      return "I couldn't find any places matching your request nearby.";
    }

    let response = 'Here are the nearest places I found:\n\n';
    places.forEach((place, index) => {
      response += `${index + 1}. ${place.name}\n`;
      response += `   Distance: ${(place.distance / 1000).toFixed(2)} km\n`;
      response += `   Address: ${place.address}\n`;
      response += `   Map: https://www.openstreetmap.org/?mlat=${place.coordinates[0]}&mlon=${place.coordinates[1]}&zoom=16\n\n`;
    });

    return response;
  }

  async process(
    block: Block,
    context: Context,
    _convId: string,
  ): Promise<StdOutgoingEnvelope> {
    const settings = await this.settingService.getSettings();
    const args = this.getArguments(block);

    console.log('args:', settings);

    // Check if location data exists in context
    const x = {
      latitude: context.user_location.lat,
      longitude: context.user_location.lon,
      accuracy: 0,
      timestamp: 0,
    };

    let locationData: LocationData = x as LocationData;

    if (!locationData) {
      const msg: StdOutgoingTextEnvelope = {
        format: OutgoingMessageFormat.text,
        message: {
          text: this.blockService.processText(
            args.request_location_message,
            context,
            {},
            settings,
          ),
        },
      };
      return msg;
    }

    try {
      const amenity = this.extractAmenityFromMessage(context.text || '');
      const searchRadius = args.search_radius || 1000;

      const places = await this.queryOverpass(
        locationData.latitude,
        locationData.longitude,
        amenity,
        searchRadius,
      );

      const response = this.formatPlacesResponse(places);

      const msg: StdOutgoingTextEnvelope = {
        format: OutgoingMessageFormat.text,
        message: {
          text: this.blockService.processText(response, context, {}, settings),
        },
      };

      console.log('msg:', msg);
      return msg;
    } catch (error) {
      const errorMsg: StdOutgoingTextEnvelope = {
        format: OutgoingMessageFormat.text,
        message: {
          text: this.blockService.processText(
            args.error_message,
            context,
            {},
            settings,
          ),
        },
      };
      return errorMsg;
    }
  }
}
