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
    NavigationStack {
      List {
        Section {
          ForEach(viewModel.participants) { participant in
            ParticipantRow(
              participant: participant,
              isCurrentUser: participant.id == viewModel.userId,
              showActiveIndicator: false
            )
          }
        } header: {
          Text("\(viewModel.activeParticipantCount) Active")
        } footer: {
          if let joinCode = viewModel.joinCode.isEmpty ? nil : viewModel.joinCode {
            HStack {
              Text("Session Code: \(joinCode)")
              CopyableCodeButton(code: joinCode, iconFont: .body)
            }
          }
        }
      }
      .navigationTitle("Participants")
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
