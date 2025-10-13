import { WebPlugin } from '@capacitor/core';

import type { 
  OukekCalendar as OukekCalendarPlugin,
  CalendarEvent,
  GetEventsOptions,
  CreateEventOptions,
  UpdateEventOptions,
  DeleteEventOptions,
  CalendarPermissionResult
} from './definitions';

export class OukekCalendarWeb extends WebPlugin implements OukekCalendarPlugin {

  constructor() {
    super();
  }

  async requestPermissions(): Promise<CalendarPermissionResult> {
    throw this.unimplemented('Not implemented on web.');
  }

  async checkPermissions(): Promise<CalendarPermissionResult> {
    throw this.unimplemented('Not implemented on web.');
  }

  async getEvents(options: GetEventsOptions): Promise<{ events: CalendarEvent[] }> {
    console.log('getEvents', options);
    throw this.unimplemented('Not implemented on web.');
  }

  async createEvent(options: CreateEventOptions): Promise<{ id: string }> {
    console.log('createEvent', options);
    throw this.unimplemented('Not implemented on web.');
  }

  async updateEvent(options: UpdateEventOptions): Promise<void> {
    console.log('updateEvent', options);
    throw this.unimplemented('Not implemented on web.');
  }

  async deleteEvent(options: DeleteEventOptions): Promise<void> {
    console.log('deleteEvent', options);
    throw this.unimplemented('Not implemented on web.');
  }

  async getCalendars(): Promise<{ calendars: Array<{ id: string; title: string; color?: string }> }> {
    throw this.unimplemented('Not implemented on web.');
  }
}