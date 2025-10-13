# @oukek/capacitor-calendar

日历相关插件，提供获取和设置日历事件的功能。

## Install

```bash
npm install @oukek/capacitor-calendar
npx cap sync
```

## 权限配置

### iOS

在 `Info.plist` 中添加以下权限描述：

```xml
<key>NSCalendarsUsageDescription</key>
<string>此应用需要访问日历来管理您的事件</string>
```

## API

<docgen-index>

* [`requestPermissions()`](#requestpermissions)
* [`checkPermissions()`](#checkpermissions)
* [`getEvents(...)`](#getevents)
* [`createEvent(...)`](#createevent)
* [`updateEvent(...)`](#updateevent)
* [`deleteEvent(...)`](#deleteevent)
* [`getCalendars()`](#getcalendars)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### requestPermissions()

```typescript
requestPermissions() => Promise<CalendarPermissionResult>
```

请求日历权限

**Returns:** <code>Promise&lt;<a href="#calendarpermissionresult">CalendarPermissionResult</a>&gt;</code>

--------------------


### checkPermissions()

```typescript
checkPermissions() => Promise<CalendarPermissionResult>
```

检查日历权限状态

**Returns:** <code>Promise&lt;<a href="#calendarpermissionresult">CalendarPermissionResult</a>&gt;</code>

--------------------


### getEvents(...)

```typescript
getEvents(options: GetEventsOptions) => Promise<{ events: CalendarEvent[]; }>
```

获取日历事件

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`options`** | <code><a href="#geteventsoptions">GetEventsOptions</a></code> |

**Returns:** <code>Promise&lt;{ events: CalendarEvent[]; }&gt;</code>

--------------------


### createEvent(...)

```typescript
createEvent(options: CreateEventOptions) => Promise<{ id: string; }>
```

创建日历事件

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`options`** | <code><a href="#createeventoptions">CreateEventOptions</a></code> |

**Returns:** <code>Promise&lt;{ id: string; }&gt;</code>

--------------------


### updateEvent(...)

```typescript
updateEvent(options: UpdateEventOptions) => Promise<void>
```

更新日历事件

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`options`** | <code><a href="#updateeventoptions">UpdateEventOptions</a></code> |

--------------------


### deleteEvent(...)

```typescript
deleteEvent(options: DeleteEventOptions) => Promise<void>
```

删除日历事件

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`options`** | <code><a href="#deleteeventoptions">DeleteEventOptions</a></code> |

--------------------


### getCalendars()

```typescript
getCalendars() => Promise<{ calendars: Array<{ id: string; title: string; color?: string; }>; }>
```

获取可用的日历列表

**Returns:** <code>Promise&lt;{ calendars: { id: string; title: string; color?: string; }[]; }&gt;</code>

--------------------


### Interfaces


#### CalendarPermissionResult

| Prop          | Type                 |
| ------------- | -------------------- |
| **`granted`** | <code>boolean</code> |


#### CalendarEvent

| Prop             | Type                 |
| ---------------- | -------------------- |
| **`id`**         | <code>string</code>  |
| **`title`**      | <code>string</code>  |
| **`startDate`**  | <code>number</code>  |
| **`endDate`**    | <code>number</code>  |
| **`allDay`**     | <code>boolean</code> |
| **`location`**   | <code>string</code>  |
| **`notes`**      | <code>string</code>  |
| **`url`**        | <code>string</code>  |
| **`calendarId`** | <code>string</code>  |


#### GetEventsOptions

| Prop              | Type                  |
| ----------------- | --------------------- |
| **`startDate`**   | <code>number</code>   |
| **`endDate`**     | <code>number</code>   |
| **`calendarIds`** | <code>string[]</code> |


#### CreateEventOptions


#### UpdateEventOptions

| Prop     | Type                |
| -------- | ------------------- |
| **`id`** | <code>string</code> |


#### DeleteEventOptions

| Prop     | Type                |
| -------- | ------------------- |
| **`id`** | <code>string</code> |


#### Array

| Prop         | Type                | Description                                                                                            |
| ------------ | ------------------- | ------------------------------------------------------------------------------------------------------ |
| **`length`** | <code>number</code> | Gets or sets the length of the array. This is a number one higher than the highest index in the array. |

| Method             | Signature                                                                                                                     | Description                                                                                                                                                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **toString**       | () =&gt; string                                                                                                               | Returns a string representation of an array.                                                                                                                                                                                                |
| **toLocaleString** | () =&gt; string                                                                                                               | Returns a string representation of an array. The elements are converted to string using their toLocalString methods.                                                                                                                        |
| **pop**            | () =&gt; T \| undefined                                                                                                       | Removes the last element from an array and returns it. If the array is empty, undefined is returned and the array is not modified.                                                                                                          |
| **push**           | (...items: T[]) =&gt; number                                                                                                  | Appends new elements to the end of an array, and returns the new length of the array.                                                                                                                                                       |
| **concat**         | (...items: <a href="#concatarray">ConcatArray</a>&lt;T&gt;[]) =&gt; T[]                                                       | Combines two or more arrays. This method returns a new array without modifying any existing arrays.                                                                                                                                         |
| **concat**         | (...items: (T \| <a href="#concatarray">ConcatArray</a>&lt;T&gt;)[]) =&gt; T[]                                                | Combines two or more arrays. This method returns a new array without modifying any existing arrays.                                                                                                                                         |
| **join**           | (separator?: string \| undefined) =&gt; string                                                                                | Adds all the elements of an array into a string, separated by the specified separator string.                                                                                                                                               |
| **reverse**        | () =&gt; T[]                                                                                                                  | Reverses the elements in an array in place. This method mutates the array and returns a reference to the same array.                                                                                                                        |
| **shift**          | () =&gt; T \| undefined                                                                                                       | Removes the first element from an array and returns it. If the array is empty, undefined is returned and the array is not modified.                                                                                                         |
| **slice**          | (start?: number \| undefined, end?: number \| undefined) =&gt; T[]                                                            | Returns a copy of a section of an array. For both start and end, a negative index can be used to indicate an offset from the end of the array. For example, -2 refers to the second to last element of the array.                           |
| **sort**           | (compareFn?: ((a: T, b: T) =&gt; number) \| undefined) =&gt; this                                                             | Sorts an array in place. This method mutates the array and returns a reference to the same array.                                                                                                                                           |
| **splice**         | (start: number, deleteCount?: number \| undefined) =&gt; T[]                                                                  | Removes elements from an array and, if necessary, inserts new elements in their place, returning the deleted elements.                                                                                                                      |
| **splice**         | (start: number, deleteCount: number, ...items: T[]) =&gt; T[]                                                                 | Removes elements from an array and, if necessary, inserts new elements in their place, returning the deleted elements.                                                                                                                      |
| **unshift**        | (...items: T[]) =&gt; number                                                                                                  | Inserts new elements at the start of an array, and returns the new length of the array.                                                                                                                                                     |
| **indexOf**        | (searchElement: T, fromIndex?: number \| undefined) =&gt; number                                                              | Returns the index of the first occurrence of a value in an array, or -1 if it is not present.                                                                                                                                               |
| **lastIndexOf**    | (searchElement: T, fromIndex?: number \| undefined) =&gt; number                                                              | Returns the index of the last occurrence of a specified value in an array, or -1 if it is not present.                                                                                                                                      |
| **every**          | &lt;S extends T&gt;(predicate: (value: T, index: number, array: T[]) =&gt; value is S, thisArg?: any) =&gt; this is S[]       | Determines whether all the members of an array satisfy the specified test.                                                                                                                                                                  |
| **every**          | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; boolean                                 | Determines whether all the members of an array satisfy the specified test.                                                                                                                                                                  |
| **some**           | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; boolean                                 | Determines whether the specified callback function returns true for any element of an array.                                                                                                                                                |
| **forEach**        | (callbackfn: (value: T, index: number, array: T[]) =&gt; void, thisArg?: any) =&gt; void                                      | Performs the specified action for each element in an array.                                                                                                                                                                                 |
| **map**            | &lt;U&gt;(callbackfn: (value: T, index: number, array: T[]) =&gt; U, thisArg?: any) =&gt; U[]                                 | Calls a defined callback function on each element of an array, and returns an array that contains the results.                                                                                                                              |
| **filter**         | &lt;S extends T&gt;(predicate: (value: T, index: number, array: T[]) =&gt; value is S, thisArg?: any) =&gt; S[]               | Returns the elements of an array that meet the condition specified in a callback function.                                                                                                                                                  |
| **filter**         | (predicate: (value: T, index: number, array: T[]) =&gt; unknown, thisArg?: any) =&gt; T[]                                     | Returns the elements of an array that meet the condition specified in a callback function.                                                                                                                                                  |
| **reduce**         | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T) =&gt; T                           | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduce**         | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T, initialValue: T) =&gt; T          |                                                                                                                                                                                                                                             |
| **reduce**         | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: T, currentIndex: number, array: T[]) =&gt; U, initialValue: U) =&gt; U | Calls the specified callback function for all the elements in an array. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function.                      |
| **reduceRight**    | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T) =&gt; T                           | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |
| **reduceRight**    | (callbackfn: (previousValue: T, currentValue: T, currentIndex: number, array: T[]) =&gt; T, initialValue: T) =&gt; T          |                                                                                                                                                                                                                                             |
| **reduceRight**    | &lt;U&gt;(callbackfn: (previousValue: U, currentValue: T, currentIndex: number, array: T[]) =&gt; U, initialValue: U) =&gt; U | Calls the specified callback function for all the elements in an array, in descending order. The return value of the callback function is the accumulated result, and is provided as an argument in the next call to the callback function. |


#### ConcatArray

| Prop         | Type                |
| ------------ | ------------------- |
| **`length`** | <code>number</code> |

| Method    | Signature                                                          |
| --------- | ------------------------------------------------------------------ |
| **join**  | (separator?: string \| undefined) =&gt; string                     |
| **slice** | (start?: number \| undefined, end?: number \| undefined) =&gt; T[] |

</docgen-api>

## 使用示例

```typescript
import { OukekCalendar } from '@oukek/capacitor-calendar';

// 请求权限
const permission = await OukekCalendar.requestPermissions();
if (!permission.granted) {
  console.log('日历权限未授权');
  return;
}

// 获取事件
const events = await OukekCalendar.getEvents({
  startDate: '2024-01-01T00:00:00.000Z',
  endDate: '2024-01-31T23:59:59.999Z'
});

// 创建事件
const newEvent = await OukekCalendar.createEvent({
  title: '会议',
  startDate: '2024-01-15T10:00:00.000Z',
  endDate: '2024-01-15T11:00:00.000Z',
  location: '会议室A',
  notes: '重要会议'
});

// 更新事件
await OukekCalendar.updateEvent({
  id: newEvent.id,
  title: '重要会议',
  location: '会议室B'
});

// 删除事件
await OukekCalendar.deleteEvent({
  id: newEvent.id
});

// 获取日历列表
const calendars = await OukekCalendar.getCalendars();
```

**Returns:** <code>Promise&lt;<a href="#calendarreadresult">CalendarReadResult</a>&gt;</code>

--------------------


### write(...)

```typescript
write(options: CalendarWriteOptions) => Promise<CalendarWriteResult>
```

写入内容到剪切板

| Param         | Type                                                                    | Description |
| ------------- | ----------------------------------------------------------------------- | ----------- |
| **`options`** | <code><a href="#calendarwriteoptions">CalendarWriteOptions</a></code> | 写入选项        |

**Returns:** <code>Promise&lt;<a href="#calendarwriteresult">CalendarWriteResult</a>&gt;</code>

--------------------


### clear()

```typescript
clear() => Promise<CalendarWriteResult>
```

清空剪切板

**Returns:** <code>Promise&lt;<a href="#calendarwriteresult">CalendarWriteResult</a>&gt;</code>

--------------------


### Interfaces


#### CalendarReadResult

| Prop              | Type                | Description            |
| ----------------- | ------------------- | ---------------------- |
| **`changeCount`** | <code>number</code> | 剪切板变更计数                |
| **`text`**        | <code>string</code> | 剪切板中的文本（如果有）           |
| **`url`**         | <code>string</code> | 剪切板中的URL（如果有）          |
| **`image`**       | <code>string</code> | 剪切板中的图片，以Base64编码（如果有） |
| **`items`**       | <code>any[]</code>  | 剪切板中的所有项目，包含所有类型       |


#### CalendarReadOptions

| Prop         | Type                | Description                                                   |
| ------------ | ------------------- | ------------------------------------------------------------- |
| **`format`** | <code>string</code> | 指定要读取的数据格式: 'string', 'url', 'image', 'all' 如果不指定，会尝试读取所有可用格式 |


#### CalendarWriteResult

| Prop              | Type                 | Description |
| ----------------- | -------------------- | ----------- |
| **`success`**     | <code>boolean</code> | 操作是否成功      |
| **`message`**     | <code>string</code>  | 操作结果消息      |
| **`changeCount`** | <code>number</code>  | 剪切板变更计数     |


#### CalendarWriteOptions

| Prop        | Type                | Description         |
| ----------- | ------------------- | ------------------- |
| **`text`**  | <code>string</code> | 要写入剪切板的文本           |
| **`url`**   | <code>string</code> | 要写入剪切板的URL          |
| **`image`** | <code>string</code> | 要写入剪切板的图片（Base64编码） |

</docgen-api>
