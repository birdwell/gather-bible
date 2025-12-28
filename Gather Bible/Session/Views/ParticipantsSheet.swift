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
  @State private var codeCopied = false

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
            HStack {
              Text("Session Code: \(joinCode)")
              Button {
                UIPasteboard.general.string = joinCode
                codeCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                  codeCopied = false
                }
              } label: {
                Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc")
                  .foregroundStyle(codeCopied ? .green : .accentColor)
              }
              .buttonStyle(.plain)
              .accessibilityLabel(codeCopied ? "Code copied" : "Copy code")
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
