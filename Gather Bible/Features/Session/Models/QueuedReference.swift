//
//  QueuedReference.swift
//  Gather Bible
//
//  Model for a queued scripture reference in a session
//

import Foundation

struct QueuedReference: Codable, Identifiable, Equatable {
  let id: String
  let book: String
  let chapter: Int
  let startVerse: Int?
  let endVerse: Int?

  var isWholeChapter: Bool {
    startVerse == nil && endVerse == nil
  }

  var isSingleVerse: Bool {
    guard let start = startVerse else { return false }
    return endVerse == nil || endVerse == start
  }

  var displayLabel: String {
    let bookName = BibleBookNames.fullName(for: book)
    if isWholeChapter {
      return "\(bookName) \(chapter)"
    } else if isSingleVerse, let verse = startVerse {
      return "\(bookName) \(chapter):\(verse)"
    } else if let start = startVerse, let end = endVerse {
      return "\(bookName) \(chapter):\(start)-\(end)"
    }
    return "\(bookName) \(chapter)"
  }

  init(
    id: String = UUID().uuidString,
    book: String,
    chapter: Int,
    startVerse: Int? = nil,
    endVerse: Int? = nil
  ) {
    self.id = id
    self.book = book
    self.chapter = chapter
    self.startVerse = startVerse
    self.endVerse = endVerse
  }

  init?(from dictionary: [String: Any]) {
    guard let id = dictionary["id"] as? String,
      let book = dictionary["book"] as? String,
      let chapter = dictionary["chapter"] as? Int
    else {
      return nil
    }

    self.id = id
    self.book = book
    self.chapter = chapter
    self.startVerse = dictionary["startVerse"] as? Int
    self.endVerse = dictionary["endVerse"] as? Int
  }

  func toDictionary() -> [String: Any] {
    var dict: [String: Any] = [
      "id": id,
      "book": book,
      "chapter": chapter,
    ]
    if let startVerse = startVerse {
      dict["startVerse"] = startVerse
    }
    if let endVerse = endVerse {
      dict["endVerse"] = endVerse
    }
    return dict
  }
}

enum BibleBookNames {
  static func fullName(for usfm: String) -> String {
    bookNames[usfm] ?? usfm
  }

  private static let bookNames: [String: String] = [
    "GEN": "Genesis",
    "EXO": "Exodus",
    "LEV": "Leviticus",
    "NUM": "Numbers",
    "DEU": "Deuteronomy",
    "JOS": "Joshua",
    "JDG": "Judges",
    "RUT": "Ruth",
    "1SA": "1 Samuel",
    "2SA": "2 Samuel",
    "1KI": "1 Kings",
    "2KI": "2 Kings",
    "1CH": "1 Chronicles",
    "2CH": "2 Chronicles",
    "EZR": "Ezra",
    "NEH": "Nehemiah",
    "EST": "Esther",
    "JOB": "Job",
    "PSA": "Psalms",
    "PRO": "Proverbs",
    "ECC": "Ecclesiastes",
    "SNG": "Song of Solomon",
    "ISA": "Isaiah",
    "JER": "Jeremiah",
    "LAM": "Lamentations",
    "EZK": "Ezekiel",
    "DAN": "Daniel",
    "HOS": "Hosea",
    "JOL": "Joel",
    "AMO": "Amos",
    "OBA": "Obadiah",
    "JON": "Jonah",
    "MIC": "Micah",
    "NAM": "Nahum",
    "HAB": "Habakkuk",
    "ZEP": "Zephaniah",
    "HAG": "Haggai",
    "ZEC": "Zechariah",
    "MAL": "Malachi",
    "MAT": "Matthew",
    "MRK": "Mark",
    "LUK": "Luke",
    "JHN": "John",
    "ACT": "Acts",
    "ROM": "Romans",
    "1CO": "1 Corinthians",
    "2CO": "2 Corinthians",
    "GAL": "Galatians",
    "EPH": "Ephesians",
    "PHP": "Philippians",
    "COL": "Colossians",
    "1TH": "1 Thessalonians",
    "2TH": "2 Thessalonians",
    "1TI": "1 Timothy",
    "2TI": "2 Timothy",
    "TIT": "Titus",
    "PHM": "Philemon",
    "HEB": "Hebrews",
    "JAS": "James",
    "1PE": "1 Peter",
    "2PE": "2 Peter",
    "1JN": "1 John",
    "2JN": "2 John",
    "3JN": "3 John",
    "JUD": "Jude",
    "REV": "Revelation",
  ]
}
