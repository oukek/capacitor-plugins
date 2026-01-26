<template>
  <q-page class="q-pa-md">
    <h1 class="text-h4 q-mb-md">日历功能测试</h1>

    <div class="row q-col-gutter-md">
      <!-- 权限检查区域 -->
      <div class="col-12">
        <q-card>
          <q-card-section>
            <div class="text-h6">权限管理</div>
          </q-card-section>

          <q-separator />

          <q-card-section>
            <div class="q-mb-md">
              <q-btn
                color="primary"
                @click="checkPermissions"
                :loading="loading.checkPermissions"
              >
                检查权限
              </q-btn>
              <q-btn
                color="secondary"
                @click="requestPermissions"
                class="q-ml-sm"
                :loading="loading.requestPermissions"
              >
                请求权限
              </q-btn>
            </div>
            <div v-if="permissionStatus !== null" class="q-mt-md">
              <q-chip
                :color="permissionStatus ? 'green' : 'red'"
                text-color="white"
                :icon="permissionStatus ? 'check' : 'close'"
              >
                权限状态: {{ permissionStatus ? '已授权' : '未授权' }}
              </q-chip>
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- 获取日历列表 -->
      <div class="col-12 col-md-6">
        <q-card>
          <q-card-section>
            <div class="text-h6">日历列表</div>
          </q-card-section>

          <q-separator />

          <q-card-section>
            <q-btn
              color="primary"
              @click="getCalendars"
              :loading="loading.getCalendars"
              :disable="!permissionStatus"
            >
              获取日历列表
            </q-btn>

            <div v-if="calendars.length > 0" class="q-mt-md">
              <q-list bordered separator>
                <q-item v-for="calendar in calendars" :key="calendar.id">
                  <q-item-section>
                    <q-item-label>{{ calendar.title }}</q-item-label>
                    <q-item-label caption>ID: {{ calendar.id }}</q-item-label>
                  </q-item-section>
                  <q-item-section side v-if="calendar.color">
                    <q-avatar :style="{ backgroundColor: calendar.color }" size="20px" />
                  </q-item-section>
                </q-item>
              </q-list>
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- 获取事件 -->
      <div class="col-12 col-md-6">
        <q-card>
          <q-card-section>
            <div class="text-h6">获取事件</div>
          </q-card-section>

          <q-separator />

          <q-card-section>
            <q-input
              v-model="getEventsForm.startDate"
              label="开始日期"
              type="date"
              outlined
              class="q-mb-md"
            />

            <q-input
              v-model="getEventsForm.endDate"
              label="结束日期"
              type="date"
              outlined
              class="q-mb-md"
            />

            <q-btn
              color="primary"
              @click="getEvents"
              :loading="loading.getEvents"
              :disable="!permissionStatus"
            >
              获取事件
            </q-btn>

            <div v-if="events.length > 0" class="q-mt-md">
              <q-list bordered separator>
                <q-item v-for="event in events" :key="event.id || Math.random().toString()">
                  <q-item-section>
                    <q-item-label>{{ event.title }}</q-item-label>
                    <q-item-label caption>
                      {{ formatDate(event.startDate) }} - {{ formatDate(event.endDate) }}
                    </q-item-label>
                    <q-item-label caption v-if="event.location">
                      📍 {{ event.location }}
                    </q-item-label>
                  </q-item-section>
                  <q-item-section side>
                    <q-btn
                      flat
                      round
                      color="red"
                      icon="delete"
                      @click="deleteEvent(event.id!)"
                      size="sm"
                    />
                  </q-item-section>
                </q-item>
              </q-list>
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- 创建事件 -->
      <div class="col-12">
        <q-card>
          <q-card-section>
            <div class="text-h6">创建事件</div>
          </q-card-section>

          <q-separator />

          <q-card-section>
            <div class="row q-col-gutter-md">
              <div class="col-12 col-md-6">
                <q-input
                  v-model="createEventForm.title"
                  label="事件标题"
                  outlined
                  required
                />
              </div>

              <div class="col-12 col-md-6">
                <q-input
                  v-model="createEventForm.location"
                  label="地点"
                  outlined
                />
              </div>

              <div class="col-12 col-md-3">
                <q-input
                  v-model="createEventForm.startDate"
                  label="开始日期"
                  type="date"
                  outlined
                  required
                />
              </div>

              <div class="col-12 col-md-3">
                <q-input
                  v-model="createEventForm.startTime"
                  label="开始时间"
                  type="time"
                  outlined
                  :disable="createEventForm.allDay"
                />
              </div>

              <div class="col-12 col-md-3">
                <q-input
                  v-model="createEventForm.endDate"
                  label="结束日期"
                  type="date"
                  outlined
                  required
                />
              </div>

              <div class="col-12 col-md-3">
                <q-input
                  v-model="createEventForm.endTime"
                  label="结束时间"
                  type="time"
                  outlined
                  :disable="createEventForm.allDay"
                />
              </div>

              <div class="col-12">
                <q-checkbox
                  v-model="createEventForm.allDay"
                  label="全天事件"
                />
              </div>

              <div class="col-12">
                <q-input
                  v-model="createEventForm.notes"
                  label="备注"
                  type="textarea"
                  outlined
                />
              </div>

              <div class="col-12">
                <q-input
                  v-model="createEventForm.url"
                  label="相关链接"
                  outlined
                />
              </div>

              <div class="col-12">
                <q-select
                  v-model="createEventForm.calendarId"
                  :options="calendarOptions"
                  label="选择日历"
                  outlined
                  emit-value
                  map-options
                />
              </div>

              <div class="col-12">
                <q-btn
                  color="primary"
                  @click="createEvent"
                  :loading="loading.createEvent"
                  :disable="!permissionStatus || !createEventForm.title"
                >
                  创建事件
                </q-btn>
              </div>
            </div>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <!-- 消息显示 -->
    <div v-if="message" class="q-mt-md">
      <q-banner :class="messageType === 'error' ? 'bg-red text-white' : 'bg-green text-white'">
        {{ message }}
      </q-banner>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { OukekCalendar } from '@oukek/capacitor-calendar';
import type { CalendarEvent } from '@oukek/capacitor-calendar';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';

// 扩展 dayjs 插件
dayjs.extend(utc);

// 响应式数据
const permissionStatus = ref<boolean | null>(null);
const calendars = ref<Array<{ id: string; title: string; color?: string }>>([]);
const events = ref<CalendarEvent[]>([]);
const message = ref('');
const messageType = ref<'success' | 'error'>('success');

// 加载状态
const loading = ref({
  checkPermissions: false,
  requestPermissions: false,
  getCalendars: false,
  getEvents: false,
  createEvent: false
});

// 获取事件表单
const getEventsForm = ref({
  startDate: new Date().toISOString().split('T')[0],
  endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] // 30天后
});

// 创建事件表单
const createEventForm = ref({
  title: '',
  location: '',
  startDate: new Date().toISOString().split('T')[0],
  startTime: '09:00',
  endDate: new Date().toISOString().split('T')[0],
  endTime: '10:00',
  allDay: false,
  notes: '',
  url: '',
  calendarId: ''
});

// 计算属性
const calendarOptions = computed(() =>
  calendars.value.map(cal => ({
    label: cal.title,
    value: cal.id
  }))
);

// 方法
const showMessage = (msg: string, type: 'success' | 'error' = 'success') => {
  message.value = msg;
  messageType.value = type;
  setTimeout(() => {
    message.value = '';
  }, 3000);
};

const checkPermissions = async () => {
  loading.value.checkPermissions = true;
  try {
    const result = await OukekCalendar.checkPermissions();
    permissionStatus.value = result.granted;
    showMessage(`权限状态: ${result.granted ? '已授权' : '未授权'}`);
  } catch (error) {
    showMessage(`检查权限失败: ${String(error)}`, 'error');
  } finally {
    loading.value.checkPermissions = false;
  }
};

const requestPermissions = async () => {
  loading.value.requestPermissions = true;
  try {
    const result = await OukekCalendar.requestPermissions();
    permissionStatus.value = result.granted;
    showMessage(`权限请求${result.granted ? '成功' : '失败'}`);
  } catch (error) {
    showMessage(`请求权限失败: ${String(error)}`, 'error');
  } finally {
    loading.value.requestPermissions = false;
  }
};

const getCalendars = async () => {
  loading.value.getCalendars = true;
  try {
    const result = await OukekCalendar.getCalendars();
    calendars.value = result.calendars;
    showMessage(`获取到 ${result.calendars.length} 个日历`);

    // 自动选择第一个日历
    if (result.calendars.length > 0 && !createEventForm.value.calendarId) {
      createEventForm.value.calendarId = result.calendars[0]?.id || '';
    }
  } catch (error) {
    showMessage(`获取日历列表失败: ${String(error)}`, 'error');
  } finally {
    loading.value.getCalendars = false;
  }
};

const getEvents = async () => {
  loading.value.getEvents = true;
  try {
    // 验证日期格式
    if (!getEventsForm.value.startDate || !getEventsForm.value.endDate) {
      showMessage('请选择开始日期和结束日期', 'error');
      return;
    }

    // 将日期转换为毫秒时间戳
    const startTimestamp = dayjs(getEventsForm.value.startDate).startOf('day').valueOf();
    const endTimestamp = dayjs(getEventsForm.value.endDate).endOf('day').valueOf();

    console.log('发送的时间戳:', { startDate: startTimestamp, endDate: endTimestamp });

    const result = await OukekCalendar.getEvents({
      startDate: startTimestamp,
      endDate: endTimestamp
    });

    events.value = result.events;
    showMessage(`获取到 ${result.events.length} 个事件`);
    console.log('获取到的事件:', result.events);
  } catch (error) {
    console.error('获取事件错误:', error);
    showMessage(`获取事件失败: ${String(error)}`, 'error');
  } finally {
    loading.value.getEvents = false;
  }
};

const createEvent = async () => {
  loading.value.createEvent = true;
  try {
    const form = createEventForm.value;

    // 验证必填字段
    if (!form.title || !form.startDate || !form.endDate) {
      showMessage('请填写必填字段：标题、开始日期、结束日期', 'error');
      return;
    }

    let startTimestamp: number;
    let endTimestamp: number;

    if (form.allDay) {
      // 全天事件：使用 dayjs 处理
      startTimestamp = dayjs(form.startDate).startOf('day').valueOf();
      endTimestamp = dayjs(form.endDate).endOf('day').valueOf();
    } else {
      // 非全天事件：需要时间
      if (!form.startTime || !form.endTime) {
        showMessage('非全天事件需要设置开始时间和结束时间', 'error');
        return;
      }

      // 使用 dayjs 构建完整的日期时间
      startTimestamp = dayjs(`${form.startDate} ${form.startTime}`).valueOf();
      endTimestamp = dayjs(`${form.endDate} ${form.endTime}`).valueOf();
    }

    console.log('创建事件的时间戳:', { startDate: startTimestamp, endDate: endTimestamp });

    const eventData = {
      title: form.title,
      startDate: startTimestamp,
      endDate: endTimestamp,
      allDay: form.allDay,
      ...(form.location && { location: form.location }),
      ...(form.notes && { notes: form.notes }),
      ...(form.url && { url: form.url }),
      ...(form.calendarId && { calendarId: form.calendarId })
    };

    const result = await OukekCalendar.createEvent(eventData);
    showMessage(`事件创建成功，ID: ${result.id || '未知'}`);

    // 重置表单
    createEventForm.value = {
      title: '',
      location: '',
      startDate: new Date().toISOString().split('T')[0],
      startTime: '09:00',
      endDate: new Date().toISOString().split('T')[0],
      endTime: '10:00',
      allDay: false,
      notes: '',
      url: '',
      calendarId: createEventForm.value.calendarId // 保持选中的日历
    };

    // 刷新事件列表
    void getEvents();
  } catch (error) {
    console.error('创建事件错误:', error);
    showMessage(`创建事件失败: ${String(error)}`, 'error');
  } finally {
    loading.value.createEvent = false;
  }
};

const deleteEvent = async (eventId: string) => {
  try {
    await OukekCalendar.deleteEvent({ id: eventId });
    showMessage('事件删除成功');

    // 刷新事件列表
    await getEvents();
  } catch (error) {
    showMessage(`删除事件失败: ${String(error)}`, 'error');
  }
};

const formatDate = (dateValue: string | number) => {
  // 如果是时间戳（数字），直接使用；如果是字符串，先解析
  const timestamp = typeof dateValue === 'number' ? dateValue : new Date(dateValue).getTime();
  return dayjs(timestamp).format('YYYY-MM-DD HH:mm:ss');
};

// 组件挂载时检查权限
onMounted(async () => {
  await checkPermissions();
});
</script>
