//
//  CommunityViewiPad.swift
//  Gather Bible
//
//  iPad-optimized Community view using NavigationSplitView
//

import SwiftUI

enum CommunitySection: String, CaseIterable, Identifiable {
  case session = "Session"
  case discussions = "Discussions"
  case participants = "Participants"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .session: return "person.2.fill"
    case .discussions: return "bubble.left.and.bubble.right.fill"
    case .participants: return "person.3.fill"
    }
  }
}

struct CommunityViewiPad: View {
  @EnvironmentObject var sessionViewModel: SessionViewModel
  @State private var selectedSection: CommunitySection? = .session
  @State private var columnVisibility: NavigationSplitViewVisibility = .all

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      sidebar
        .navigationTitle("Community")
    } detail: {
      detailView
    }
    .navigationSplitViewStyle(.balanced)
  }

  // MARK: - Sidebar

  private var sidebar: some View {
    List(selection: $selectedSection) {
      Section {
        ForEach(CommunitySection.allCases) { section in
          sidebarRow(for: section)
            .tag(section)
        }
      } header: {
        if sessionViewModel.isInSession {
          sessionStatusHeader
        }
      }

      if !sessionViewModel.isInSession {
        Section {
          quickActions
        }
      }
    }
    .listStyle(.sidebar)
  }

  private func sidebarRow(for section: CommunitySection) -> some View {
    Label {
      HStack {
        Text(section.rawValue)
        Spacer()
        if section == .participants && sessionViewModel.isInSession {
          Text("\(sessionViewModel.activeParticipantCount)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
        }
        if section == .discussions && sessionViewModel.activeDiscussion != nil {
          Circle()
            .fill(.blue)
            .frame(width: 8, height: 8)
        }
      }
    } icon: {
      Image(systemName: section.icon)
    }
  }

  private var sessionStatusHeader: some View {
    HStack {
      Circle()
        .fill(.green)
        .frame(width: 8, height: 8)
      Text("In Session")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
      Text(sessionViewModel.joinCode)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
  }

  private var quickActions: some View {
    VStack(spacing: 12) {
      Button {
        Task { await sessionViewModel.createSession() }
      } label: {
        Label("Create Session", systemImage: "plus.circle.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(sessionViewModel.isLoading)
    }
    .padding(.vertical, 8)
  }

  // MARK: - Detail View

  @ViewBuilder
  private var detailView: some View {
    switch selectedSection {
    case .session:
      SessionDetailView(viewModel: sessionViewModel)
    case .discussions:
      DiscussionsDetailView(viewModel: sessionViewModel)
    case .participants:
      ParticipantsDetailView(viewModel: sessionViewModel)
    case .none:
      ContentUnavailableView(
        "Select a Section",
        systemImage: "sidebar.left",
        description: Text("Choose a section from the sidebar")
      )
    }
  }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
  @ObservedObject var viewModel: SessionViewModel
  @State private var showingJoinSheet = false

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
          Text(viewModel.joinCode)
            .font(.system(.largeTitle, design: .monospaced, weight: .bold))
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
          Task { await viewModel.createSession() }
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

// MARK: - Discussions Detail View

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
          discussionCard(active, isActive: true)
        }

        if !viewModel.draftDiscussions.isEmpty && viewModel.isHost {
          Section {
            ForEach(viewModel.draftDiscussions) { draft in
              discussionCard(draft, isDraft: true)
            }
          } header: {
            Text("Drafts")
              .font(.headline)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }

        if !viewModel.completedDiscussions.isEmpty {
          Section {
            ForEach(viewModel.completedDiscussions) { completed in
              discussionCard(completed)
            }
          } header: {
            Text("Completed")
              .font(.headline)
              .frame(maxWidth: .infinity, alignment: .leading)
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

  private func discussionCard(_ discussion: Discussion, isActive: Bool = false, isDraft: Bool = false) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        if isActive {
          Circle()
            .fill(.blue)
            .frame(width: 8, height: 8)
        }

        Text(discussion.question)
          .font(.headline)
          .lineLimit(2)

        Spacer()

        if isDraft {
          Text("Draft")
            .font(.caption)
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
        }
      }

      if !isDraft {
        HStack {
          Label("\(viewModel.discussionResponses.count) responses", systemImage: "text.bubble")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - Participants Detail View

struct ParticipantsDetailView: View {
  @ObservedObject var viewModel: SessionViewModel

  var body: some View {
    Group {
      if viewModel.isInSession {
        participantsList
      } else {
        ContentUnavailableView(
          "No Active Session",
          systemImage: "person.3",
          description: Text("Join or create a session to view participants")
        )
      }
    }
    .navigationTitle("Participants")
  }

  private var participantsList: some View {
    List {
      ForEach(viewModel.participants) { participant in
        HStack {
          Circle()
            .fill(participant.active ? .green : .gray)
            .frame(width: 10, height: 10)

          Text(participant.displayName)
            .font(.body)

          Spacer()

          if participant.isHost {
            Label("Host", systemImage: "crown.fill")
              .font(.caption)
              .foregroundStyle(.orange)
          }
        }
        .padding(.vertical, 4)
      }
    }
    .listStyle(.insetGrouped)
  }
}

#Preview {
  CommunityViewiPad()
    .environmentObject(SessionViewModel())
}
