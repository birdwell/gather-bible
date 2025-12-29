//
//  TimeInterval+Formatting.swift
//  Gather Bible
//
//  Consolidated TimeInterval formatting utilities for millisecond-based timestamps
//

import Foundation

extension TimeInterval {
  /// Interprets the TimeInterval as milliseconds-since-epoch and returns a Date
  var asDateFromMillis: Date {
    Date(timeIntervalSince1970: self / 1000)
  }

  /// Returns a relative time string (e.g., "2h ago") from a millisecond timestamp
  var relativeFormatted: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: asDateFromMillis, relativeTo: Date())
  }

  /// Returns a formatted creation date string (e.g., "Created Jan 15, 2024 at 3:30 PM")
  var createdDateFormatted: String {
    "Created \(asDateFromMillis.formatted(date: .abbreviated, time: .shortened))"
  }
}
