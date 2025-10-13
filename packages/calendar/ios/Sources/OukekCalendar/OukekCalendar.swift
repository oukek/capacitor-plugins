import Foundation
import Capacitor
import UIKit
import EventKit

/**
 * OukekCalendar for handling calendar operations
 */
@objc(OukekCalendar)
public class OukekCalendar: CAPPlugin {
    private let eventStore = EKEventStore()
    
    override public func load() {
        // 插件加载时的初始化
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleAppLaunch),
                                            name: UIApplication.didFinishLaunchingNotification,
                                            object: nil)
    }
    
    @objc private func handleAppLaunch(_ notification: Notification) {
        // 应用启动时的处理
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 权限管理
    
    @objc public override func requestPermissions(_ call: CAPPluginCall) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        call.reject("Permission request failed", error.localizedDescription)
                        return
                    }
                    call.resolve(["granted": granted])
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if let error = error {
                        call.reject("Permission request failed", error.localizedDescription)
                        return
                    }
                    call.resolve(["granted": granted])
                }
            }
        }
    }
    
    @objc public override func checkPermissions(_ call: CAPPluginCall) {
        let status = EKEventStore.authorizationStatus(for: .event)
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = status == .authorized || status == .fullAccess
        } else {
            granted = status == .authorized
        }
        call.resolve(["granted": granted])
    }
    
    // MARK: - 日历事件操作
    
    @objc func getEvents(_ call: CAPPluginCall) {
        // 检查权限
        let status = EKEventStore.authorizationStatus(for: .event)
        let hasPermission: Bool
        if #available(iOS 17.0, *) {
            hasPermission = status == .authorized || status == .fullAccess
        } else {
            hasPermission = status == .authorized
        }
        guard hasPermission else {
            call.reject("Calendar permission not granted")
            return
        }
        
        guard let startTimestamp = call.getDouble("startDate"),
              let endTimestamp = call.getDouble("endDate") else {
            call.reject("Must provide startDate and endDate as timestamps (milliseconds)")
            return
        }
        
        // 将毫秒时间戳转换为 Date
        let startDate = Date(timeIntervalSince1970: startTimestamp / 1000.0)
        let endDate = Date(timeIntervalSince1970: endTimestamp / 1000.0)
        
        let calendarIds = call.getArray("calendarIds", String.self)
        
        // 创建谓词
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // 过滤指定的日历
        let filteredEvents = calendarIds?.isEmpty == false ? 
            events.filter { event in
                calendarIds!.contains(event.calendar.calendarIdentifier)
            } : events
        
        // 转换为字典数组
        let eventDicts = filteredEvents.map { event in
            eventToDict(event)
        }
        
        call.resolve(["events": eventDicts])
    }
    
    @objc func createEvent(_ call: CAPPluginCall) {
        // 检查权限
        let status = EKEventStore.authorizationStatus(for: .event)
        let hasPermission: Bool
        if #available(iOS 17.0, *) {
            hasPermission = status == .authorized || status == .fullAccess
        } else {
            hasPermission = status == .authorized
        }
        guard hasPermission else {
            call.reject("Calendar permission not granted")
            return
        }
        
        guard let title = call.getString("title"),
              let startTimestamp = call.getDouble("startDate"),
              let endTimestamp = call.getDouble("endDate") else {
            call.reject("Must provide title, startDate and endDate as timestamps (milliseconds)")
            return
        }
        
        // 将毫秒时间戳转换为 Date
        let startDate = Date(timeIntervalSince1970: startTimestamp / 1000.0)
        let endDate = Date(timeIntervalSince1970: endTimestamp / 1000.0)
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = call.getBool("allDay", false)
        
        if let location = call.getString("location") {
            event.location = location
        }
        
        if let notes = call.getString("notes") {
            event.notes = notes
        }
        
        if let urlString = call.getString("url"), let url = URL(string: urlString) {
            event.url = url
        }
        
        // 选择日历
        if let calendarId = call.getString("calendarId") {
            if let calendar = eventStore.calendar(withIdentifier: calendarId) {
                event.calendar = calendar
            } else {
                call.reject("Calendar with specified ID not found")
                return
            }
        } else {
            event.calendar = eventStore.defaultCalendarForNewEvents
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            call.resolve(["id": event.eventIdentifier ?? ""])
        } catch {
            call.reject("Failed to create event", error.localizedDescription)
        }
    }
    
    @objc func updateEvent(_ call: CAPPluginCall) {
        // 检查权限
        let status = EKEventStore.authorizationStatus(for: .event)
        let hasPermission: Bool
        if #available(iOS 17.0, *) {
            hasPermission = status == .authorized || status == .fullAccess
        } else {
            hasPermission = status == .authorized
        }
        guard hasPermission else {
            call.reject("Calendar permission not granted")
            return
        }
        
        guard let eventId = call.getString("id") else {
            call.reject("Must provide event id")
            return
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            call.reject("Event not found")
            return
        }
        
        // 更新事件属性
        if let title = call.getString("title") {
            event.title = title
        }
        
        if let startTimestamp = call.getDouble("startDate") {
            let startDate = Date(timeIntervalSince1970: startTimestamp / 1000.0)
            event.startDate = startDate
        }
        
        if let endTimestamp = call.getDouble("endDate") {
            let endDate = Date(timeIntervalSince1970: endTimestamp / 1000.0)
            event.endDate = endDate
        }
        
        if call.hasOption("allDay") {
            event.isAllDay = call.getBool("allDay", false)
        }
        
        if let location = call.getString("location") {
            event.location = location
        }
        
        if let notes = call.getString("notes") {
            event.notes = notes
        }
        
        if let urlString = call.getString("url") {
            event.url = URL(string: urlString)
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            call.resolve()
        } catch {
            call.reject("Failed to update event", error.localizedDescription)
        }
    }
    
    @objc func deleteEvent(_ call: CAPPluginCall) {
        // 检查权限
        let status = EKEventStore.authorizationStatus(for: .event)
        let hasPermission: Bool
        if #available(iOS 17.0, *) {
            hasPermission = status == .authorized || status == .fullAccess
        } else {
            hasPermission = status == .authorized
        }
        guard hasPermission else {
            call.reject("Calendar permission not granted")
            return
        }
        
        guard let eventId = call.getString("id") else {
            call.reject("Must provide event id")
            return
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            call.reject("Event not found")
            return
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            call.resolve()
        } catch {
            call.reject("Failed to delete event", error.localizedDescription)
        }
    }
    
    @objc func getCalendars(_ call: CAPPluginCall) {
        // 检查权限
        let status = EKEventStore.authorizationStatus(for: .event)
        let hasPermission: Bool
        if #available(iOS 17.0, *) {
            hasPermission = status == .authorized || status == .fullAccess
        } else {
            hasPermission = status == .authorized
        }
        guard hasPermission else {
            call.reject("Calendar permission not granted")
            return
        }
        
        let calendars = eventStore.calendars(for: .event)
        let calendarDicts = calendars.map { calendar in
            var dict: [String: Any] = [
                "id": calendar.calendarIdentifier,
                "title": calendar.title
            ]
            
            if let cgColor = calendar.cgColor {
                let uiColor = UIColor(cgColor: cgColor)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                
                if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    let hexColor = String(format: "#%02X%02X%02X", 
                                        Int(red * 255), 
                                        Int(green * 255), 
                                        Int(blue * 255))
                    dict["color"] = hexColor
                }
            }
            
            return dict
        }
        
        call.resolve(["calendars": calendarDicts])
    }
    
    // MARK: - 辅助方法
    
    private func eventToDict(_ event: EKEvent) -> [String: Any] {
        // 将日期转换为毫秒时间戳
        let startTimestamp = Int64(event.startDate.timeIntervalSince1970 * 1000)
        let endTimestamp = Int64(event.endDate.timeIntervalSince1970 * 1000)
        
        var dict: [String: Any] = [
            "id": event.eventIdentifier ?? "",
            "title": event.title ?? "",
            "startDate": startTimestamp,
            "endDate": endTimestamp,
            "allDay": event.isAllDay,
            "calendarId": event.calendar.calendarIdentifier
        ]
        
        if let location = event.location {
            dict["location"] = location
        }
        
        if let notes = event.notes {
            dict["notes"] = notes
        }
        
        if let url = event.url {
            dict["url"] = url.absoluteString
        }
        
        return dict
    }
}
