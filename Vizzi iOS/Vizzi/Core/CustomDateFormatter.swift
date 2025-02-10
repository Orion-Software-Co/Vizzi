

import Foundation


struct CustomDateFormatter {
    
    // Function to format dates in a custom string format
    static func toCustomStringFormat(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        let day = Calendar.current.component(.day, from: date)
        let daySuffix = ordinalSuffix(for: day)
        
        dateFormatter.dateFormat = "yyyy"
        let year = dateFormatter.string(from: date)
        
        let month = dateFormatter.monthSymbols[Calendar.current.component(.month, from: date) - 1] // Get full month name
        
        return "\(month) \(day)\(daySuffix), \(year)"
    }
    
    // Function to get a relative time ago string
    static func formatTimeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .month, .year], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "Last year" : "\(years)y ago"
        }
        if let months = components.month, months > 0 {
            return months == 1 ? "Last month" : "\(months)mo ago"
        }
        if let days = components.day, days > 0 {
            return days == 1 ? "Yesterday" : "\(days)d ago"
        }
        if let hours = components.hour, hours > 0 {
            return "\(hours)hrs ago"
        }
        if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        }
        
        return "Just now"
    }
    
    // Helper function to determine the ordinal suffix for a day
    private static func ordinalSuffix(for day: Int) -> String {
        let ones = day % 10
        let tens = (day / 10) % 10
        if tens == 1 {
            return "th"
        } else {
            switch ones {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
    
    static func formatDateJoined(_ date: Date?) -> String {
        guard let date = date else {
            return "Unknown"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        return dateFormatter.string(from: date)
    }
}
