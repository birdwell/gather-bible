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
    .sheet(isPresented: $showingJoinSheet) {
      JoinSessionSheet(
        viewModel: viewModel,
        isPresented: $showingJoinSheet,
        initialCode: pendingCodeForSheet
      )
    }
    .onChange(of: viewModel.pendingJoinCode) { _, newCode in
      if let code = newCode, !viewModel.isInSession {
        pendingCodeForSheet = code
        showingJoinSheet = true
        viewModel.pendingJoinCode = nil
      }
    }
    .onAppear {
      if let code = viewModel.pendingJoinCode, !viewModel.isInSession {
        pendingCodeForSheet = code
        showingJoinSheet = true
        viewModel.pendingJoinCode = nil
      }
    }
  }
}

#Preview("Not in Session") {
  SessionManagementView(viewModel: SessionViewModel())
    .padding()
}
