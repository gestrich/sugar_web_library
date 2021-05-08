//
//  SugarEvent.swift
//  
//
//  Created by Bill Gestrich on 12/20/20.
//

import Foundation

protocol SugarEvent {
    var date: Date { get }
    func inlineDescription() -> String
    
}

extension SugarEvent {
    func dateDescription() -> String {
        // *** create calendar object ***
        var calendar = Calendar.current
        // *** define calendar components to use as well Timezone to UTC ***
        calendar.timeZone = TimeZone(identifier: "UTC")!

        // *** Get Individual components from date ***
        let month = calendar.component(.month, from: self.date)
        let day = calendar.component(.day, from: self.date)
        let hour = calendar.component(.hour, from: self.date)
        let minutes = calendar.component(.minute, from: self.date)
        let seconds = calendar.component(.second, from: self.date)
        let time = "\(month)-\(day) \(hour):\(minutes):\(seconds)"
        
        return time
    }

}

extension Array where Element: SugarEvent {
    
    func sortDescending() -> [Element] {
        
        return self.sorted { (event1, event2) -> Bool in
            return event1.date > event2.date
        }
    }
    
    func sortAscending() -> [Element] {
        
        return self.sorted { (event1, event2) -> Bool in
            return event1.date < event2.date
        }
    }
    
    func eventsSince(_ oldestDate: Date, referenceDate: Date) -> [Element] {
        return self.filter { (event) -> Bool in
            return event.date < referenceDate && event.date >= oldestDate
        }
    }
    
    func eventsInPastMinutes(_ minutes: Int, referenceDate: Date) -> [Element] {
        
        return self.filter { (event) -> Bool in
            let interval = referenceDate.timeIntervalSince(event.date)
            if interval < 0 {
                return false
            }
            return interval <= TimeInterval(minutes * 60)
        }
    }
    
    func eventsWithinUpcomingMinutes(_ minutes: Int, referenceDate: Date) -> [Element] {
        return self.filter { (event) -> Bool in
            let interval = event.date.timeIntervalSince(referenceDate)
            return interval > 0 && interval <= TimeInterval(minutes * 60)
        }
    }
    
    func eventsAfterUpcomingMinutes(_ minutes: Int, referenceDate: Date) -> [Element] {
        return self.filter { (event) -> Bool in
            let interval = event.date.timeIntervalSince(referenceDate)
            return interval >= TimeInterval(minutes * 60)
        }
    }
}
