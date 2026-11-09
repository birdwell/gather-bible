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
  @State private var showingParticipants = false

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  private var otherNames: [String] {
    viewModel.participants
      .filter { $0.active && $0.id != viewModel.userId }
      .sorted { $0.isHost && !$1.isHost }
      .map(\.displayName)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 32) {
      passageHeader
      SessionCodeBanner(code: viewModel.joinCode, isHost: viewModel.isHost)

      if !viewModel.isHost {
        followHostToggle
      }

      if !viewModel.isHost && viewModel.isCurrentHostInactive {
        claimHostButton
      }

      if viewModel.isHost {
        discussionSection
      }

      Spacer(minLength: 0)

      leaveButton
    }
    .frame(maxWidth: isRegularWidth ? 560 : .infinity, maxHeight: .infinity, alignment: .topLeading)
    .sheet(isPresented: $showingParticipants) {
      ParticipantsSheet(viewModel: viewModel)
        .presentationDetents([.medium, .large])
    }
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
      viewModel.isHost ? "End session for everyone?" : "Leave session?",
      isPresented: $showingLeaveConfirmation,
      titleVisibility: .visible
    ) {
      Button(viewModel.isHost ? "End session" : "Leave session", role: .destructive) {
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

  private var responseSummary: String {
    let count = viewModel.discussionResponses.count
    return "\(count) \(count == 1 ? "response" : "responses") so far"
  }

  // MARK: - Passage Header

  private var passageHeader: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(viewModel.isHost ? "You’re hosting" : "Reading now")
        .font(AppFont.caption)
        .foregroundStyle(AppColor.muted)

      Text("\(BibleBookNames.title(for: viewModel.currentBook)) \(viewModel.currentChapter)")
        .font(AppFont.display)
        .foregroundStyle(AppColor.ink)
        .accessibilityAddTraits(.isHeader)

      Button {
        showingParticipants = true
      } label: {
        HStack(spacing: 4) {
          Text(ReadingCompanions.text(names: otherNames))
          AppIconView(.caretRight, size: 14)
        }
        .font(AppFont.body)
        .foregroundStyle(AppColor.muted)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint("Shows who's in this session")
    }
    .padding(.top, 32)
  }

  // MARK: - Follow Host Toggle

  private var followHostToggle: some View {
    Toggle(isOn: Binding(
      get: { viewModel.followHost },
      set: { _ in viewModel.toggleFollowHost() }
    )) {
      Text("Follow host")
        .font(AppFont.label)
        .foregroundStyle(AppColor.ink)
    }
  }

  // MARK: - Claim Host Button

  private var claimHostButton: some View {
    Button {
      Task { await viewModel.claimHost() }
    } label: {
      Text("Claim host")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.appPrimary)
    .disabled(viewModel.isLoading)
    .accessibilityHint("Becomes the session host")
  }

  // MARK: - Discussion Section

  private var discussionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let discussion = viewModel.activeDiscussion {
        Button {
          showingDiscussionResults = true
        } label: {
          VStack(alignment: .leading, spacing: 4) {
            Text(discussion.question)
              .font(AppFont.heading)
              .foregroundStyle(AppColor.ink)
              .multilineTextAlignment(.leading)

            Text(responseSummary)
              .font(AppFont.caption)
              .foregroundStyle(AppColor.muted)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the discussion responses")
      } else {
        Button {
          showingCreateDiscussion = true
        } label: {
          Text("Ask the group a question")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.appPrimary)
      }

      if !viewModel.draftDiscussions.isEmpty {
        Button {
          showingDraftDiscussions = true
        } label: {
          Text("\(viewModel.draftDiscussions.count) drafts")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.appSecondary)
        .accessibilityHint("Opens your saved draft discussions")
      }
    }
  }

  // MARK: - Leave Button

  private var leaveButton: some View {
    Button(role: .destructive) {
      showingLeaveConfirmation = true
    } label: {
      Text(viewModel.isHost ? "End session" : "Leave session")
    }
    .buttonStyle(.appQuiet)
    .disabled(viewModel.isLoading)
    .accessibilityHint(viewModel.isHost ? "Ends the session for everyone" : "Leaves this reading session")
  }
}

#Preview {
  InSessionView(viewModel: SessionViewModel())
    .padding()
}
