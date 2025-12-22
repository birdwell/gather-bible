import Foundation
import YouVersionPlatformCore

extension BibleBook {
  /// Shared mock books for Swift previews
  public static var mockBooks: [BibleBook] {
    let json = """
      [
        {
          "id": "GEN",
          "title": "Genesis",
          "chapters": [
            {"id": "GEN.1"}, {"id": "GEN.2"}, {"id": "GEN.3"}, {"id": "GEN.4"}, {"id": "GEN.5"}
          ]
        },
        {
          "id": "EXO",
          "title": "Exodus",
          "chapters": [
            {"id": "EXO.1"}, {"id": "EXO.2"}, {"id": "EXO.3"}
          ]
        },
        {
          "id": "MAT",
          "title": "Matthew",
          "chapters": [
            {"id": "MAT.1"}, {"id": "MAT.2"}
          ]
        }
      ]
      """.data(using: .utf8)!

    do {
      return try JSONDecoder().decode([BibleBook].self, from: json)
    } catch {
      print("❌ Error decoding shared mock books: \(error)")
      return []
    }
  }
}
