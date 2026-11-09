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
}

struct CommunityViewiPad: View {
  @EnvironmentObject var sessionViewModel: SessionViewModel
  @State private var selectedSection: CommunitySection? = .session
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var showingJoinSheet = false
  @State private var pendingCodeForSheet: String?
  @State private var conflictingJoinCode: String?

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      sidebar
        .appNavigationTitle("Community")
    } detail: {
      detailView
    }
    .navigationSplitViewStyle(.balanced)
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
      "Something went wrong",
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
      "Join a different session?",
      isPresented: Binding(
        get: { conflictingJoinCode != nil },
        set: { presenting in
          if !presenting { conflictingJoinCode = nil }
        }
      )
    ) {
      Button("Leave and join") {
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
          Text(section.rawValue)
            .font(AppFont.body)
            .foregroundStyle(AppColor.ink)
            .badge(
              section == .participants && sessionViewModel.isInSession
                ? sessionViewModel.activeParticipantCount : 0
            )
            .tag(section)
        }
      } header: {
        if sessionViewModel.isInSession {
          Text("In session · \(sessionViewModel.joinCode)")
            .font(AppFont.caption)
            .foregroundStyle(AppColor.muted)
        }
      }
    }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .background(AppColor.surface.ignoresSafeArea())
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
      EmptyState(title: "Choose a section", message: "Pick one from the sidebar.")
    }
  }
}

#Preview {
  CommunityViewiPad()
    .environmentObject(SessionViewModel())
}
