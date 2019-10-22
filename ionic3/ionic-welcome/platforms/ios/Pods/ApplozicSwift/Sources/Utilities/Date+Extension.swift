//
//  Date+Extension.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

extension Date {
    /**
     @abstract Example - Assuming today is Friday 20 September 2017, we would show:
     Today, Yesterday, Wednesday, Tuesday, Monday, Sunday, Fri, Feb 24, Jun 3, 2016 (for previous year), Etc.
     */
    func stringCompareCurrentDate(showTodayTime: Bool = false) -> String {
        let calendar: Calendar = Calendar.current
        let toDate: Date = calendar.startOfDay(for: Date())
        let fromDate: Date = calendar.startOfDay(for: self)
        let unitFlags: Set<Calendar.Component> = [.day]
        let differenceDateComponent: DateComponents = calendar.dateComponents(unitFlags, from: fromDate, to: toDate)

        guard let day = differenceDateComponent.day else {
            return ""
        }

        let dateFormatter = DateFormatter()

        if showTodayTime, day == 0 {
            let dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm", options: 0, locale: Locale.current)
            dateFormatter.dateFormat = dateFormat
        } else if day < 2 {
            dateFormatter.dateStyle = .medium
            dateFormatter.doesRelativeDateFormatting = true
        } else {
            let fromTemplate = (day < 7 ? "EEEE" : "EdMMM")
            let dateFormat = DateFormatter.dateFormat(fromTemplate: fromTemplate, options: 0, locale: Locale.current)
            dateFormatter.dateFormat = dateFormat
        }

        return dateFormatter.string(from: self)
    }
}
