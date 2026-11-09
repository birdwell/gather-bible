//
//  DiscussionsDetailView.swift
//  Gather Bible
//

import SwiftUI

struct DiscussionsDetailView: View {
  @ObservedObject var viewModel: SessionViewModel
  @State private var showingCreateDiscussion = false
  @State private var resultsDiscussion: Discussion?

  var body: some View {
    Group {
      if viewModel.isInSession {
        discussionsList
      } else {
        EmptyState(
          title: "No active session",
          message: "Join or start a session to see discussions."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
    }
    .background(AppColor.ground.ignoresSafeArea())
    .appNavigationTitle("Discussions")
    .toolbar {
      if viewModel.isHost && viewModel.isInSession {
        ToolbarItem(placement: .primaryAction) {
          Button {
            showingCreateDiscussion = true
          } label: {
            AppIconView(.plus)
          }
          .disabled(viewModel.activeDiscussion != nil)
          .accessibilityLabel("Ask a question")
        }
      }
    }
    .sheet(isPresented: $showingCreateDiscussion) {
      CreateDiscussionSheet(viewModel: viewModel)
    }
    .sheet(item: $resultsDiscussion) { discussion in
      DiscussionResultsView(viewModel: viewModel, discussion: discussion)
    }
  }

  private var discussionsList: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        if let active = viewModel.activeDiscussion {
          DiscussionCard(
            discussion: active,
            style: .active,
            responseCount: viewModel.discussionResponses.count
          ) {
            resultsDiscussion = active
          }
        }

        if !viewModel.draftDiscussions.isEmpty && viewModel.isHost {
          DiscussionListSection(title: "Drafts") {
            ForEach(viewModel.draftDiscussions) { draft in
              DiscussionCard(discussion: draft, style: .draft)
                .contextMenu {
                  Button {
                    Task { await viewModel.publishDiscussion(draft) }
                  } label: {
                    Text("Send to group")
                  }
                  .disabled(viewModel.activeDiscussion != nil)

                  Button(role: .destructive) {
                    Task { await viewModel.deleteDiscussion(draft) }
                  } label: {
                    Text("Delete")
                  }
                }
            }
          }
        }

        if !viewModel.completedDiscussions.isEmpty {
          DiscussionListSection(title: "Completed") {
            ForEach(viewModel.completedDiscussions) { completed in
              // Per-discussion response counts aren't available from the VM,
              // so omit the count on completed cards rather than showing the
              // active discussion's count (which would be wrong data).
              DiscussionCard(discussion: completed)
            }
          }
        }

        if viewModel.activeDiscussion == nil
          && viewModel.draftDiscussions.isEmpty
          && viewModel.completedDiscussions.isEmpty
        {
          EmptyState(
            title: "No discussions yet",
            message: viewModel.isHost
              ? "Ask the group a question to get started."
              : "Questions from the host appear here."
          )
        }
      }
      .padding(24)
    }
  }
}

#Preview {
  DiscussionsDetailView(viewModel: SessionViewModel())
}
