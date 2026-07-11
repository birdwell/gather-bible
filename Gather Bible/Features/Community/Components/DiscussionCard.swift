//
//  DiscussionCard.swift
//  Gather Bible
//

import SwiftUI

struct DiscussionCard: View {
  let discussion: Discussion
  var style: Style = .normal
  /// Number of responses to display. Pass `nil` to omit the count entirely
  /// (per-discussion counts aren't available for completed discussions).
  var responseCount: Int? = nil
  /// Optional tap action. When provided, the card renders as a `Button`.
  var action: (() -> Void)? = nil

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  enum Style {
    case normal, active, draft
  }

  private var statusDescription: String {
    switch style {
    case .active: return "Active discussion"
    case .draft: return "Draft"
    case .normal: return "Completed"
    }
  }

  private var accessibilityLabelText: String {
    var label = "\(statusDescription). \(discussion.question)"
    if let responseCount {
      label += ". \(responseCount) response\(responseCount == 1 ? "" : "s")"
    }
    return label
  }

  var body: some View {
    if let action {
      Button(action: action) {
        cardContent
      }
      .buttonStyle(.plain)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(accessibilityLabelText)
      .accessibilityAddTraits(.isButton)
    } else {
      cardContent
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }
  }

  private var cardContent: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        if style == .active {
          Circle()
            .fill(Color.accentColor)
            .frame(width: 8, height: 8)
            .accessibilityHidden(true)
        }

        Text(discussion.question)
          .font(.headline)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
          .multilineTextAlignment(.leading)

        Spacer()

        if style == .draft {
          DraftBadge()
        }
      }

      if let responseCount, style != .draft {
        Label(
          "\(responseCount) response\(responseCount == 1 ? "" : "s")",
          systemImage: "text.bubble"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .contentShape(RoundedRectangle(cornerRadius: 12))
  }
}
