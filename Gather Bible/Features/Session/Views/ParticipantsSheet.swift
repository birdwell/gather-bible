//
//  ParticipantsSheet.swift
//  Gather Bible
//
//  Half-sheet view to display session participants
//

import SwiftUI

struct ParticipantsSheet: View {
  @ObservedObject var viewModel: SessionViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    sheetContent.appSheet()
  }

  private var sheetContent: some View {
    NavigationStack {
      List {
        Section {
          ForEach(viewModel.participants) { participant in
            ParticipantRow(
              participant: participant,
              isCurrentUser: participant.id == viewModel.userId,
              showActiveIndicator: false
            )
            .listRowBackground(Color.clear)
          }
        } header: {
          Text("\(viewModel.activeParticipantCount) here")
        }
      }
      .listStyle(.plain)
      .appNavigationTitle("Participants")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  ParticipantsSheet(viewModel: SessionViewModel())
}
