//
//  SessionManagementView.swift
//  Gather Bible
//
//  Session management UI - simplified to follow Apple HIG
//

import SwiftUI

/// Session management UI component
struct SessionManagementView: View {
  @ObservedObject var viewModel: SessionViewModel
  @State private var showingJoinSheet = false
  @State private var pendingCodeForSheet: String?
  @State private var conflictingJoinCode: String?

  var body: some View {
    VStack(spacing: 16) {
      if !viewModel.isInSession {
        NotInSessionView(
          viewModel: viewModel,
          showingJoinSheet: $showingJoinSheet
        )
      } else {
        InSessionView(viewModel: viewModel)
      }
    }
    // Success haptic when a session is successfully joined or created.
    .sensoryFeedback(trigger: viewModel.isInSession) { _, isIn in
      isIn ? .success : nil
    }
    .sheet(isPresented: $showingJoinSheet) {
      JoinSessionSheet(
        viewModel: viewModel,
        isPresented: $showingJoinSheet,
        initialCode: pendingCodeForSheet
      )
    }
    // Surface repository/view-model failures that aren't already shown inline in a sheet.
    .alert(
      "Something Went Wrong",
      isPresented: Binding(
        get: { viewModel.errorMessage != nil && !viewModel.isInlineErrorSheetPresented },
        set: { presenting in
          if !presenting { viewModel.errorMessage = nil }
        }
      )
    ) {
      Button("OK", role: .cancel) { viewModel.errorMessage = nil }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
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
            await viewModel.leaveSession()
            // Leaving can fail (error surfaced via the alert); only offer the
            // join sheet once we're actually out of the current session.
            guard !viewModel.isInSession else { return }
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
    .onChange(of: viewModel.pendingJoinCode) { _, newCode in
      handlePendingJoinCode(newCode)
    }
    .onAppear {
      handlePendingJoinCode(viewModel.pendingJoinCode)
    }
  }

  private func handlePendingJoinCode(_ newCode: String?) {
    guard let code = newCode else { return }
    // Consume the pending code regardless of outcome.
    viewModel.pendingJoinCode = nil

    if viewModel.isInSession {
      conflictingJoinCode = code
    } else {
      pendingCodeForSheet = code
      showingJoinSheet = true
    }
  }
}

#Preview("Not in Session") {
  SessionManagementView(viewModel: SessionViewModel())
    .padding()
}
