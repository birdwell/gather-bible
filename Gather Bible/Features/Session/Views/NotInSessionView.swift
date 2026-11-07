//
//  NotInSessionView.swift
//  Gather Bible
//
//  View shown when user is not currently in a session
//

import SwiftUI

/// The Community home when you aren't in a session. Scripture carries the screen,
/// and the two actions sit where a thumb reaches them.
struct NotInSessionView: View {
  @ObservedObject var viewModel: SessionViewModel
  @Binding var showingJoinSheet: Bool
  @State private var showingCreateSheet = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 12) {
        Text("“For where two or three gather in my name, there am I with them.”")
          .font(AppFont.display)
          .foregroundStyle(AppColor.ink)
          .lineSpacing(2)
          .accessibilityAddTraits(.isHeader)

        Text("Matthew 18:20")
          .font(AppFont.caption)
          .foregroundStyle(AppColor.muted)
      }
      .padding(.top, 32)

      Spacer(minLength: 48)

      Text("Read the same passage together, in sync.")
        .font(AppFont.body)
        .foregroundStyle(AppColor.muted)
        .padding(.bottom, 16)

      VStack(spacing: 8) {
        Button {
          showingCreateSheet = true
        } label: {
          Text("Start a session")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.appPrimary)
        .accessibilityHint("Starts a new reading session")

        Button {
          showingJoinSheet = true
        } label: {
          Text("Join a session")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.appSecondary)
        .accessibilityHint("Joins an existing session with a code")
      }
      .disabled(viewModel.isLoading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
