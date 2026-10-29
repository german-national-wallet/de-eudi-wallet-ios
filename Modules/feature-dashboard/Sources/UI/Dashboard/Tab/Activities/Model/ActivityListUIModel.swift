//
//  ActivityListUIModel.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 10.10.26.
//

import Foundation
import logic_resources

struct ActivityListItemUIModel: Identifiable, Equatable {
  let id: String
  let leading: ActivityLeadingUIModel
  let title: String
  let subtitle: String
  let time: Date
  let isCompleted: Bool
}

enum ActivityLeadingUIModel: Equatable {
  case pidLogo
  case logo(ActivityListLogo, initials: String)
  case initials(String)
}

struct ActivityListLogo: Equatable {
  let url: URL
  // The credential's brand colour; nil for the issuer's logo
  let backgroundHex: String?
}

struct ActivitySectionUIModel: Identifiable, Equatable {
  let category: ActivityCategory
  let items: [ActivityListItemUIModel]

  var id: ActivityCategory { category }
}

enum ActivityCategory: Hashable, Comparable {
  case today
  case yesterday
  case previous7Days
  case previous30Days
  case month(year: Int, month: Int)

  init(date: Date, now: Date, calendar: Calendar = .current) {
    let days = calendar.dateComponents(
      [.day],
      from: calendar.startOfDay(for: date),
      to: calendar.startOfDay(for: now)
    ).day ?? 0
    switch days {
    case ...0: self = .today
    case 1: self = .yesterday
    case 2...7: self = .previous7Days
    case 8...30: self = .previous30Days
    default:
      let components = calendar.dateComponents([.year, .month], from: date)
      self = .month(year: components.year ?? 0, month: components.month ?? 0)
    }
  }

  func title(calendar: Calendar = .current) -> LocalizableStringKey {
    switch self {
    case .today: .activitiesOverviewToday
    case .yesterday: .activitiesOverviewYesterday
    case .previous7Days: .activitiesOverviewLastWeek
    case .previous30Days: .activitiesOverviewLastMonth
    case .month(let year, let month):
      .custom(
        calendar.date(from: DateComponents(year: year, month: month, day: 1))?
          .formatted(Date.FormatStyle(calendar: calendar).month(.wide).year().locale(ActivityDateFormatter.appLocale)) ?? ""
      )
    }
  }

  // Newest first: the fixed ranges, then the months from the latest
  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.sortKey < rhs.sortKey
  }

  private var sortKey: (Int, Int) {
    switch self {
    case .today: (0, 0)
    case .yesterday: (1, 0)
    case .previous7Days: (2, 0)
    case .previous30Days: (3, 0)
    case .month(let year, let month): (4, -(year * 12 + month))
    }
  }
}
