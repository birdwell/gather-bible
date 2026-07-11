//
//  InSessionView.swift
//  Gather Bible
//
//  View shown when user is currently in a session
//

import SwiftUI

/// View displayed when the user is in an active session
struct InSessionView: View {
  @ObservedObject var viewModel: SessionViewModel
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @State private var showingCreateDiscussion = false
  @State private var showingDraftDiscussions = false
  @State private var showingDiscussionResults = false
  @State private var showingLeaveConfirmation = false

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  var body: some View {
    VStack(spacing: isRegularWidth ? 20 : 16) {
      SessionCodeBanner(
        code: viewModel.joinCode,
        isHost: viewModel.isHost
      )

      participantsRow

      if !viewModel.isHost {
        followHostToggle
      }

      if !viewModel.isHost && viewModel.isCurrentHostInactive {
        claimHostButton
      }

      if viewModel.isHost {
        Divider()
        discussionSection
      }

      Divider()

      leaveButton

      if viewModel.isLoading {
        ProgressView()
      }
    }
    .frame(maxWidth: isRegularWidth ? 560 : .infinity)
    .sheet(isPresented: $showingCreateDiscussion) {
      CreateDiscussionSheet(viewModel: viewModel)
    }
    .sheet(isPresented: $showingDraftDiscussions) {
      DraftDiscussionsView(viewModel: viewModel)
    }
    .sheet(isPresented: $showingDiscussionResults) {
      if let discussion = viewModel.activeDiscussion ?? viewModel.completedDiscussions.first {
        DiscussionResultsView(viewModel: viewModel, discussion: discussion)
      }
    }
    .sheet(
      isPresented: Binding(
        get: { viewModel.showDiscussionPrompt },
        set: { viewModel.showDiscussionPrompt = $0 }
      )
    ) {
      DiscussionPromptSheet(viewModel: viewModel)
    }
    .confirmationDialog(
      viewModel.isHost ? "End Session for Everyone?" : "Leave Session?",
      isPresented: $showingLeaveConfirmation,
      titleVisibility: .visible
    ) {
      Button(viewModel.isHost ? "End Session" : "Leave Session", role: .destructive) {
        Task { await viewModel.leaveSession() }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text(
        viewModel.isHost
          ? "This ends the session for all participants and can't be undone."
          : "You'll leave this reading session and stop following the host."
      )
    }
    // Notification-style haptic when a discussion prompt arrives for a guest.
    .sensoryFeedback(trigger: viewModel.showDiscussionPrompt) { _, isShowing in
      isShowing ? .success : nil
    }
  }

  // MARK: - Participants Row

  private var participantsRow: some View {
    HStack {
      Image(systemName: "person.2.fill")
        .foregroundStyle(.secondary)
      Text(
        "\(viewModel.activeParticipantCount) participant\(viewModel.activeParticipantCount == 1 ? "" : "s")"
      )
      .foregroundStyle(.secondary)

      Spacer()

      // Current position
      Text("\(viewModel.currentBook) \(viewModel.currentChapter)")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .font(.subheadline)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      "\(viewModel.activeParticipantCount) participant\(viewModel.activeParticipantCount == 1 ? "" : "s"), currently reading \(viewModel.currentBook) chapter \(viewModel.currentChapter)"
    )
  }

  // MARK: - Follow Host Toggle

  private var followHostToggle: some View {
    Toggle("Follow Host", isOn: Binding(
      get: { viewModel.followHost },
      set: { _ in viewModel.toggleFollowHost() }
    ))
  }

  // MARK: - Claim Host Button

  private var claimHostButton: some View {
    Button {
      Task { await viewModel.claimHost() }
    } label: {
      Label("Claim Host", systemImage: "crown.fill")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .tint(.orange)
    .disabled(viewModel.isLoading)
    .accessibilityHint("Becomes the session host")
  }

  // MARK: - Discussion Section

  private var discussionSection: some View {
    VStack(spacing: 12) {
      // Active discussion indicator
      if let discussion = viewModel.activeDiscussion {
        Button {
          showingDiscussionResults = true
        } label: {
          HStack {
            Image(systemName: "bubble.left.and.bubble.right.fill")
              .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
              Text("Active Discussion")
                .font(.subheadline)
                .fontWeight(.medium)

              Text(discussion.question)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Text("\(viewModel.discussionResponses.count)")
              .font(.caption)
              .fontWeight(.medium)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.blue.opacity(0.2))
              .clipShape(Capsule())

            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundStyle(.tertiary)
          }
          .padding(12)
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Active discussion: \(discussion.question)")
        .accessibilityValue("\(viewModel.discussionResponses.count) responses")
        .accessibilityHint("Opens the discussion responses")
      }

      // Discussion action buttons
      HStack(spacing: 12) {
        Button {
          showingCreateDiscussion = true
        } label: {
          Label("New Discussion", systemImage: "plus.bubble.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.activeDiscussion != nil)
        .accessibilityHint("Creates a new discussion question")

        if !viewModel.draftDiscussions.isEmpty {
          Button {
            showingDraftDiscussions = true
          } label: {
            Label("\(viewModel.draftDiscussions.count) Drafts", systemImage: "doc.text")
          }
          .buttonStyle(.bordered)
          .accessibilityLabel("\(viewModel.draftDiscussions.count) draft discussions")
          .accessibilityHint("Opens your saved draft discussions")
        }
      }
    }
  }

  // MARK: - Leave Button

  private var leaveButton: some View {
    Button(role: .destructive) {
      showingLeaveConfirmation = true
    } label: {
      Label("Leave Session", systemImage: "xmark.circle.fill")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.bordered)
    .disabled(viewModel.isLoading)
    .accessibilityHint(viewModel.isHost ? "Ends the session for everyone" : "Leaves this reading session")
  }
}

#Preview {
  InSessionView(viewModel: SessionViewModel())
    .padding()
}
