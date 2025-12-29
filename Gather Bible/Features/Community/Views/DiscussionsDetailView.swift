//
//  DiscussionsDetailView.swift
//  Gather Bible
//

import SwiftUI

struct DiscussionsDetailView: View {
  @ObservedObject var viewModel: SessionViewModel
  @State private var showingCreateDiscussion = false

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
  }

  private var discussionsList: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        if let active = viewModel.activeDiscussion {
          DiscussionCard(discussion: active, style: .active, responseCount: viewModel.discussionResponses.count)
        }

        if !viewModel.draftDiscussions.isEmpty && viewModel.isHost {
          DiscussionListSection(title: "Drafts") {
            ForEach(viewModel.draftDiscussions) { draft in
              DiscussionCard(discussion: draft, style: .draft)
            }
          }
        }

        if !viewModel.completedDiscussions.isEmpty {
          DiscussionListSection(title: "Completed") {
            ForEach(viewModel.completedDiscussions) { completed in
              DiscussionCard(discussion: completed, responseCount: viewModel.discussionResponses.count)
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
