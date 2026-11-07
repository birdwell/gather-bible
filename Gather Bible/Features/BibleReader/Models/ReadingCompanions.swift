import Foundation

enum ReadingCompanions {
  /// Short line naming who else is in the session, such as "with Sam and 2 others".
  static func text(names: [String]) -> String {
    switch names.count {
    case 0:
      return "Just you so far"
    case 1:
      return "with \(names[0])"
    case 2:
      return "with \(names[0]) and \(names[1])"
    default:
      return "with \(names[0]) and \(names.count - 1) others"
    }
  }
}
