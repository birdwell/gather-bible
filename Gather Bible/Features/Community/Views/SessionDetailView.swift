//
//  SessionDetailView.swift
//  Gather Bible
//

import SwiftUI

/// The iPad session pane. It shares the phone's screens in a comfortable column.
struct SessionDetailView: View {
  @ObservedObject var viewModel: SessionViewModel
  @State private var showingJoinSheet = false

  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        Group {
          if viewModel.isInSession {
            InSessionView(viewModel: viewModel)
          } else {
            NotInSessionView(viewModel: viewModel, showingJoinSheet: $showingJoinSheet)
          }
        }
        .frame(maxWidth: 560)
        .padding(32)
        .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
      }
    }
    .background(AppColor.ground.ignoresSafeArea())
    .appNavigationTitle("Session")
    .sheet(isPresented: $showingJoinSheet) {
      JoinSessionSheet(viewModel: viewModel, isPresented: $showingJoinSheet, initialCode: nil)
    }
  }
}

#Preview {
  SessionDetailView(viewModel: SessionViewModel())
}
