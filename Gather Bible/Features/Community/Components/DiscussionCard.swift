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
    VStack(alignment: .leading, spacing: 4) {
      Text(discussion.question)
        .font(style == .active ? AppFont.heading : AppFont.label)
        .foregroundStyle(AppColor.ink)
        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
        .multilineTextAlignment(.leading)

      if let responseCount, style != .draft {
        Text("\(responseCount) response\(responseCount == 1 ? "" : "s")")
          .font(AppFont.caption)
          .foregroundStyle(AppColor.muted)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(AppColor.surface)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .contentShape(RoundedRectangle(cornerRadius: 12))
  }
}
