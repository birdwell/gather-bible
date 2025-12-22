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

  var body: some View {
    VStack(spacing: 16) {
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

      Divider()

      leaveButton

      if viewModel.isLoading {
        ProgressView()
      }
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
  }

  // MARK: - Follow Host Toggle

  private var followHostToggle: some View {
    Toggle("Follow Host", isOn: $viewModel.followHost)
      .onChange(of: viewModel.followHost) { _, _ in
        viewModel.toggleFollowHost()
      }
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
  }

  // MARK: - Leave Button

  private var leaveButton: some View {
    Button(role: .destructive) {
      Task { await viewModel.leaveSession() }
    } label: {
      Label("Leave Session", systemImage: "xmark.circle.fill")
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.bordered)
    .disabled(viewModel.isLoading)
  }
}

#Preview {
  InSessionView(viewModel: SessionViewModel())
    .padding()
}
