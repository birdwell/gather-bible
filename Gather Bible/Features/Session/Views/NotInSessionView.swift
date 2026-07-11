//
//  NotInSessionView.swift
//  Gather Bible
//
//  View shown when user is not currently in a session
//

import SwiftUI

/// View displayed when the user is not in an active session
struct NotInSessionView: View {
  @ObservedObject var viewModel: SessionViewModel
  @Binding var showingJoinSheet: Bool
  @State private var showingCreateSheet = false
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  var body: some View {
    VStack(spacing: isRegularWidth ? 32 : 20) {
      headerSection
      actionButtons

      if viewModel.isLoading {
        ProgressView()
      }
    }
    .padding(isRegularWidth ? 40 : 24)
    .frame(maxWidth: isRegularWidth ? 480 : .infinity)
  }

  // MARK: - Header Section

  private var headerSection: some View {
    VStack(spacing: isRegularWidth ? 12 : 8) {
      Image(systemName: "person.2.fill")
        .font(.system(size: isRegularWidth ? 56 : 40))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      Text("Read Together")
        .font(isRegularWidth ? .title : .title2)
        .fontWeight(.semibold)
        .accessibilityAddTraits(.isHeader)

      Text("Start a session and share the code with others to read the same passage in sync.")
        .font(isRegularWidth ? .body : .subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(.vertical, isRegularWidth ? 16 : 8)
  }

  // MARK: - Action Buttons

  private var actionButtons: some View {
    VStack(spacing: isRegularWidth ? 16 : 12) {
      Button {
        showingCreateSheet = true
      } label: {
        Label("Create Session", systemImage: "plus.circle.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(isRegularWidth ? .large : .regular)
      .disabled(viewModel.isLoading)
      .accessibilityHint("Starts a new reading session")

      Button {
        showingJoinSheet = true
      } label: {
        Label("Join Session", systemImage: "person.badge.plus")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .controlSize(isRegularWidth ? .large : .regular)
      .disabled(viewModel.isLoading)
      .accessibilityHint("Joins an existing session with a code")
    }
    .sheet(isPresented: $showingCreateSheet) {
      CreateSessionSheet(viewModel: viewModel, isPresented: $showingCreateSheet)
    }
  }
}

#Preview {
    NotInSessionView(
        viewModel: SessionViewModel(),
        showingJoinSheet: .constant(false)
    )
    .padding()
}
