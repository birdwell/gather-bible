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
        isPresented: $showingJoinSheet
      )
    }
  }
}

#Preview("Not in Session") {
  SessionManagementView(viewModel: SessionViewModel())
    .padding()
}
