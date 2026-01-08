//
//  SessionDetailView.swift
//  Gather Bible
//

import SwiftUI

struct SessionDetailView: View {
  @ObservedObject var viewModel: SessionViewModel
  @State private var showingJoinSheet = false
  @State private var showingCreateSheet = false

  var body: some View {
    ScrollView {
      if viewModel.isInSession {
        inSessionContent
      } else {
        notInSessionContent
      }
    }
    .navigationTitle("Session")
    .sheet(isPresented: $showingJoinSheet) {
      JoinSessionSheet(viewModel: viewModel, isPresented: $showingJoinSheet)
    }
    .sheet(isPresented: $showingCreateSheet) {
      CreateSessionSheet(viewModel: viewModel, isPresented: $showingCreateSheet)
    }
  }

  private var inSessionContent: some View {
    VStack(spacing: 24) {
      sessionInfoCard
      controlsSection
      Spacer()
    }
    .padding(32)
    .frame(maxWidth: 600)
    .frame(maxWidth: .infinity)
  }

  private var sessionInfoCard: some View {
    VStack(spacing: 16) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Session Code")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          HStack(spacing: 12) {
            Text(viewModel.joinCode)
              .font(.system(.largeTitle, design: .monospaced, weight: .bold))
            CopyableCodeButton(code: viewModel.joinCode)
          }
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Text("Reading")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Text("\(viewModel.currentBook) \(viewModel.currentChapter)")
            .font(.title2)
            .fontWeight(.medium)
        }
      }

      Divider()

      HStack {
        Label(
          "\(viewModel.activeParticipantCount) participant\(viewModel.activeParticipantCount == 1 ? "" : "s")",
          systemImage: "person.2.fill"
        )
        .foregroundStyle(.secondary)

        Spacer()

        if viewModel.isHost {
          Label("Host", systemImage: "crown.fill")
            .font(.caption)
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
        }
      }
      .font(.subheadline)
    }
    .padding(24)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private var controlsSection: some View {
    VStack(spacing: 16) {
      if !viewModel.isHost {
        Toggle("Follow Host", isOn: Binding(
          get: { viewModel.followHost },
          set: { _ in viewModel.toggleFollowHost() }
        ))
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }

      if !viewModel.isHost && viewModel.isCurrentHostInactive {
        Button {
          Task { await viewModel.claimHost() }
        } label: {
          Label("Claim Host", systemImage: "crown.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .controlSize(.large)
      }

      Button(role: .destructive) {
        Task { await viewModel.leaveSession() }
      } label: {
        Label("Leave Session", systemImage: "xmark.circle.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .controlSize(.large)
    }
  }

  private var notInSessionContent: some View {
    VStack(spacing: 32) {
      Spacer()

      VStack(spacing: 16) {
        Image(systemName: "person.2.fill")
          .font(.system(size: 64))
          .foregroundStyle(.secondary)

        Text("Read Together")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("Start a session and share the code with others to read the same passage in sync.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: 400)
      }

      VStack(spacing: 16) {
        Button {
          showingCreateSheet = true
        } label: {
          Label("Create Session", systemImage: "plus.circle.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        Button {
          showingJoinSheet = true
        } label: {
          Label("Join Session", systemImage: "person.badge.plus")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
      }
      .frame(maxWidth: 320)

      Spacer()
    }
    .padding(32)
  }
}

#Preview {
  SessionDetailView(viewModel: SessionViewModel())
}
