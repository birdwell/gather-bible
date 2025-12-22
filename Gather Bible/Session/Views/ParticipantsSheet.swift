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
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Text(participant.displayName)
                    .font(.headline)

                  if participant.isHost {
                    Image(systemName: "crown.fill")
                      .font(.caption)
                      .foregroundStyle(.orange)
                  }
                }

                if !participant.active {
                  Text("Inactive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }

              Spacer()

              if participant.id == viewModel.userId {
                Text("(You)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
        } header: {
          Text("\(viewModel.activeParticipantCount) Active")
        } footer: {
          if let joinCode = viewModel.joinCode.isEmpty ? nil : viewModel.joinCode {
            Text("Session Code: \(joinCode)")
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
