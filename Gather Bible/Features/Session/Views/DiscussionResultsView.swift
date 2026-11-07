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

  private var responseSummary: String {
    let count = viewModel.discussionResponses.count
    let noun = count == 1 ? "response" : "responses"
    return discussion.status == .active ? "\(count) \(noun) so far" : "\(count) \(noun)"
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 32) {
          VStack(alignment: .leading, spacing: 8) {
            Text(discussion.question)
              .font(AppFont.display)
              .foregroundStyle(AppColor.ink)
              .fixedSize(horizontal: false, vertical: true)
              .accessibilityAddTraits(.isHeader)

            Text(responseSummary)
              .font(AppFont.caption)
              .foregroundStyle(AppColor.muted)
          }

          if viewModel.discussionResponses.isEmpty {
            Text("Answers appear here as people respond.")
              .font(AppFont.body)
              .foregroundStyle(AppColor.muted)
          } else {
            LazyVStack(alignment: .leading, spacing: 24) {
              ForEach(viewModel.discussionResponses) { response in
                ResponseRow(response: response)
              }
            }
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if discussion.status == .active {
          Button {
            showingEndConfirmation = true
          } label: {
            Text("End discussion")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.appSecondary)
          .disabled(viewModel.isLoading)
          .confirmationDialog(
            "End this discussion?",
            isPresented: $showingEndConfirmation,
            titleVisibility: .visible
          ) {
            Button("End discussion") {
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
          .padding(16)
          .background(AppColor.ground)
        }
      }
      .appNavigationTitle("Discussion")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
    }
    .appSheet()
  }
}

private struct ResponseRow: View {
  let response: DiscussionResponse

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Text(response.participantName)
          .font(AppFont.label)
          .foregroundStyle(AppColor.ink)

        Spacer(minLength: 8)

        Text(response.submittedAt.relativeFormatted)
          .font(AppFont.caption)
          .foregroundStyle(AppColor.muted)
      }

      Text(response.response)
        .font(AppFont.body)
        .foregroundStyle(AppColor.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
    .accessibilityElement(children: .combine)
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
