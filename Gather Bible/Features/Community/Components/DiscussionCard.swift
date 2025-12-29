//
//  DiscussionCard.swift
//  Gather Bible
//

import SwiftUI

struct DiscussionCard: View {
  let discussion: Discussion
  var style: Style = .normal
  var responseCount: Int = 0

  enum Style {
    case normal, active, draft
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        if style == .active {
          Circle()
            .fill(.blue)
            .frame(width: 8, height: 8)
        }

        Text(discussion.question)
          .font(.headline)
          .lineLimit(2)

        Spacer()

        if style == .draft {
          DraftBadge()
        }
      }

      if style != .draft {
        Label("\(responseCount) responses", systemImage: "text.bubble")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}
