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
        ContentUnavailableView(
          "No Active Session",
          systemImage: "bubble.left.and.bubble.right",
          description: Text("Join or create a session to view discussions")
        )
      }
    }
    .navigationTitle("Discussions")
    .toolbar {
      if viewModel.isHost && viewModel.isInSession {
        ToolbarItem(placement: .primaryAction) {
          Button {
            showingCreateDiscussion = true
          } label: {
            Label("New Discussion", systemImage: "plus")
          }
          .disabled(viewModel.activeDiscussion != nil)
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
                    Label("Activate", systemImage: "paperplane.fill")
                  }
                  .disabled(viewModel.activeDiscussion != nil)

                  Button(role: .destructive) {
                    Task { await viewModel.deleteDiscussion(draft) }
                  } label: {
                    Label("Delete", systemImage: "trash")
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
          ContentUnavailableView(
            "No Discussions",
            systemImage: "bubble.left.and.bubble.right",
            description: Text(
              viewModel.isHost ? "Create a discussion to get started" : "Waiting for host to start a discussion")
          )
          .padding(.top, 60)
        }
      }
      .padding(24)
    }
  }
}

#Preview {
  DiscussionsDetailView(viewModel: SessionViewModel())
}
