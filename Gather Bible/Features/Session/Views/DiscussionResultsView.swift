//
//  DiscussionResultsView.swift
//  Gather Bible
//
//  Full-screen view for host to see discussion responses
//

import SwiftUI

/// View for displaying discussion responses (host only)
struct DiscussionResultsView: View {
  @ObservedObject var viewModel: SessionViewModel
  @Environment(\.dismiss) private var dismiss

  let discussion: Discussion

  @State private var showingEndConfirmation = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          questionHeader

          if viewModel.discussionResponses.isEmpty {
            ContentUnavailableView(
              "No Responses Yet",
              systemImage: "person.2.slash",
              description: Text("Waiting for guests to submit their thoughts...")
            )
          } else {
            LazyVStack(spacing: 16) {
              ForEach(viewModel.discussionResponses) { response in
                ResponseCard(response: response)
              }
            }
          }
        }
        .padding()
      }
      .navigationTitle("Discussion")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
        if discussion.status == .active {
          ToolbarItem(placement: .bottomBar) {
            Button {
              showingEndConfirmation = true
            } label: {
              Label("End Discussion", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
            .disabled(viewModel.isLoading)
          }
        }
      }
      .confirmationDialog(
        "End This Discussion?",
        isPresented: $showingEndConfirmation,
        titleVisibility: .visible
      ) {
        Button("End Discussion") {
          Task {
            await viewModel.completeDiscussion()
            // Stay on the results sheet if ending failed (the error alert
            // explains why); the discussion may still be active.
            if viewModel.errorMessage == nil {
              dismiss()
            }
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Guests will no longer be able to respond to this question.")
      }
    }
  }

  private var questionHeader: some View {
    VStack(spacing: 16) {
      Image(systemName: "bubble.left.and.bubble.right.fill")
        .font(.system(size: 40))
        .foregroundStyle(.blue)

      Text(discussion.question)
        .font(.title2)
        .fontWeight(.semibold)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: 16) {
        Label("\(viewModel.discussionResponses.count) responses", systemImage: "text.bubble.fill")

        if discussion.status == .active {
          Label("Active", systemImage: "circle.fill").foregroundStyle(.green)
        } else if discussion.status == .completed {
          Label("Completed", systemImage: "checkmark.circle.fill").foregroundStyle(.secondary)
        }
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
    }
    .padding(.vertical, 8)
  }
}

private struct ResponseCard: View {
  let response: DiscussionResponse

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "person.circle.fill")
          .font(.title2)
          .foregroundStyle(.secondary)

        Text(response.participantName).font(.headline)

        Spacer()

        Text(response.submittedAt.relativeFormatted)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }

      Text(response.response)
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}



#Preview {
  DiscussionResultsView(
    viewModel: SessionViewModel(),
    discussion: Discussion(
      id: "preview",
      sessionId: "session1",
      question: "What stood out to you in this passage?",
      status: .active,
      createdAt: Date().timeIntervalSince1970 * 1000
    )
  )
}
