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
    sheetContent.appSheet()
  }

  private var sheetContent: some View {
    NavigationStack {
      Group {
        if viewModel.draftDiscussions.isEmpty {
          EmptyState(
            title: "No drafts",
            message: "Questions you save for later appear here."
          )
          .frame(maxHeight: .infinity, alignment: .top)
        } else {
          List {
            ForEach(viewModel.draftDiscussions) { discussion in
              DraftRow(discussion: discussion) {
                Task { await viewModel.publishDiscussion(discussion) }
              }
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
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
      .listStyle(.plain)
      .appNavigationTitle("Drafts")
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
        .font(AppFont.body)
        .lineLimit(2)

      HStack {
        Text(discussion.createdAt.createdDateFormatted)
          .font(AppFont.caption)
          .foregroundStyle(AppColor.muted)

        Spacer()

        Button("Send", action: onSend)
          .buttonStyle(.appSecondary)
      }
    }
    .padding(.vertical, 4)
  }
}



#Preview {
  DraftDiscussionsView(viewModel: SessionViewModel())
}
