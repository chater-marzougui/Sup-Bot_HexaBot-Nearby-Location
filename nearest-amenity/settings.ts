// settings.ts
import { PluginSetting } from '@/plugins/types';
import { SettingType } from '@/setting/schemas/types';

export default [
  {
    label: 'request_location_message',
    group: 'default',
    type: SettingType.text,
    value: 'Please share your location to find places nearby.',
  },
  {
    label: 'error_message',
    group: 'default',
    type: SettingType.text,
    value:
      'Sorry, I encountered an error while searching for nearby places. Please try again.',
  },
  {
    label: 'search_radius',
    group: 'default',
    type: SettingType.number,
    value: 1000,
    // description: 'Search radius in meters (default: 1000)',
  },
] as const satisfies PluginSetting[];
