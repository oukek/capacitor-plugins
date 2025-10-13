export interface CalendarEvent {
  id?: string;
  title: string;
  startDate: number; // 毫秒时间戳
  endDate: number; // 毫秒时间戳
  allDay?: boolean;
  location?: string;
  notes?: string;
  url?: string;
  calendarId?: string;
}

export interface GetEventsOptions {
  startDate: number; // 毫秒时间戳
  endDate: number; // 毫秒时间戳
  calendarIds?: string[]; // 可选的日历ID数组
}

export interface CreateEventOptions extends CalendarEvent {
  // 继承CalendarEvent的所有属性
}

export interface UpdateEventOptions extends CalendarEvent {
  id: string; // 更新时必须提供ID
}

export interface DeleteEventOptions {
  id: string;
}

export interface CalendarPermissionResult {
  granted: boolean;
}

export interface OukekCalendar {
  /**
   * 请求日历权限
   */
  requestPermissions(): Promise<CalendarPermissionResult>;

  /**
   * 检查日历权限状态
   */
  checkPermissions(): Promise<CalendarPermissionResult>;

  /**
   * 获取日历事件
   */
  getEvents(options: GetEventsOptions): Promise<{ events: CalendarEvent[] }>;

  /**
   * 创建日历事件
   */
  createEvent(options: CreateEventOptions): Promise<{ id: string }>;

  /**
   * 更新日历事件
   */
  updateEvent(options: UpdateEventOptions): Promise<void>;

  /**
   * 删除日历事件
   */
  deleteEvent(options: DeleteEventOptions): Promise<void>;

  /**
   * 获取可用的日历列表
   */
  getCalendars(): Promise<{ calendars: Array<{ id: string; title: string; color?: string }> }>;
}