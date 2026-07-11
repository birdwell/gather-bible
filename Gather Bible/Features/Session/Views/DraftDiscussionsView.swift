//
//  DraftDiscussionsView.swift
//  Gather Bible
//
//  View for managing draft discussions (host only)
//

import SwiftUI

/// View for displaying and managing draft discussions
struct DraftDiscussionsView: View {
  @ObservedObject var viewModel: SessionViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.draftDiscussions.isEmpty {
          ContentUnavailableView(
            "No Drafts",
            systemImage: "doc.text",
            description: Text("Create a discussion and save it as a draft to send later")
          )
        } else {
          List {
            ForEach(viewModel.draftDiscussions) { discussion in
              DraftRow(discussion: discussion) {
                Task { await viewModel.publishDiscussion(discussion) }
              }
            }
            .onDelete { offsets in
              for index in offsets {
                let discussion = viewModel.draftDiscussions[index]
                Task { await viewModel.deleteDiscussion(discussion) }
              }
            }
          }
        }
      }
      .navigationTitle("Draft Discussions")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}

private struct DraftRow: View {
  let discussion: Discussion
  let onSend: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(discussion.question)
        .font(.body)
        .lineLimit(2)

      HStack {
        Text(discussion.createdAt.createdDateFormatted)
          .font(.caption)
          .foregroundStyle(.tertiary)

        Spacer()

        Button("Send", action: onSend)
          .buttonStyle(.borderedProminent)
          .controlSize(.regular)
      }
    }
    .padding(.vertical, 4)
  }
}



#Preview {
  DraftDiscussionsView(viewModel: SessionViewModel())
}
