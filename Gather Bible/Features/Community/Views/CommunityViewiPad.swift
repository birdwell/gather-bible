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
  @State private var showingCreateSheet = false
  @State private var showingJoinSheet = false
  @State private var pendingCodeForSheet: String?
  @State private var conflictingJoinCode: String?

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      sidebar
        .navigationTitle("Community")
    } detail: {
      detailView
    }
    .navigationSplitViewStyle(.balanced)
    .sheet(isPresented: $showingCreateSheet) {
      CreateSessionSheet(viewModel: sessionViewModel, isPresented: $showingCreateSheet)
    }
    // Clear the deep-link code once the sheet closes so a later manual Join
    // doesn't reuse a stale session code.
    .sheet(isPresented: $showingJoinSheet, onDismiss: { pendingCodeForSheet = nil }) {
      JoinSessionSheet(
        viewModel: sessionViewModel,
        isPresented: $showingJoinSheet,
        initialCode: pendingCodeForSheet
      )
    }
    .alert(
      "Something Went Wrong",
      isPresented: Binding(
        get: {
          sessionViewModel.errorMessage != nil
            && !sessionViewModel.isInlineErrorSheetPresented
        },
        set: { presenting in
          if !presenting { sessionViewModel.errorMessage = nil }
        }
      ),
      actions: {
        Button("OK", role: .cancel) { sessionViewModel.errorMessage = nil }
      },
      message: {
        if let error = sessionViewModel.errorMessage {
          Text(error)
        }
      }
    )
    // Deep-link into a join code while already in a session: offer to switch.
    .alert(
      "Join a Different Session?",
      isPresented: Binding(
        get: { conflictingJoinCode != nil },
        set: { presenting in
          if !presenting { conflictingJoinCode = nil }
        }
      )
    ) {
      Button("Leave & Join") {
        if let code = conflictingJoinCode {
          conflictingJoinCode = nil
          Task {
            await sessionViewModel.leaveSession()
            // Leaving can fail (error surfaced via the alert); only offer the
            // join sheet once we're actually out of the current session.
            guard !sessionViewModel.isInSession else { return }
            pendingCodeForSheet = code
            showingJoinSheet = true
          }
        }
      }
      Button("Cancel", role: .cancel) { conflictingJoinCode = nil }
    } message: {
      if let code = conflictingJoinCode {
        Text("You're already in a session. Leave it to join session \(code)?")
      }
    }
    .onChange(of: sessionViewModel.pendingJoinCode) { _, newCode in
      handlePendingJoinCode(newCode)
    }
    .onAppear {
      handlePendingJoinCode(sessionViewModel.pendingJoinCode)
    }
  }

  /// Consumes a deep-link join code, mirroring `SessionManagementView`'s logic
  /// for the iPhone (compact) path: open the Join sheet, or offer to switch
  /// sessions when one is already active.
  private func handlePendingJoinCode(_ code: String?) {
    guard let code else { return }
    // Consume the pending code regardless of outcome.
    sessionViewModel.pendingJoinCode = nil

    if sessionViewModel.isInSession {
      conflictingJoinCode = code
    } else {
      pendingCodeForSheet = code
      showingJoinSheet = true
    }
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
        if section == .discussions && sessionViewModel.activeDiscussion != nil {
          Circle()
            .fill(Color.accentColor)
            .frame(width: 8, height: 8)
            .accessibilityHidden(true)
        }
      }
    } icon: {
      Image(systemName: section.icon)
    }
    // List-native badge reads correctly on the grouped sidebar background
    // (unlike a custom capsule) and is hidden automatically when the count is 0.
    .badge(
      section == .participants && sessionViewModel.isInSession
        ? sessionViewModel.activeParticipantCount : 0
    )
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
        showingCreateSheet = true
      } label: {
        if sessionViewModel.isLoading {
          ProgressView()
            .frame(maxWidth: .infinity)
        } else {
          Label("Create Session", systemImage: "plus.circle.fill")
            .frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(sessionViewModel.isLoading)

      Button {
        showingJoinSheet = true
      } label: {
        Label("Join Session", systemImage: "person.badge.plus")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
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

#Preview {
  CommunityViewiPad()
    .environmentObject(SessionViewModel())
}
