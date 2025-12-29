//
//  ParticipantsDetailView.swift
//  Gather Bible
//

import SwiftUI

struct ParticipantsDetailView: View {
  @ObservedObject var viewModel: SessionViewModel

  var body: some View {
    Group {
      if viewModel.isInSession {
        participantsList
      } else {
        ContentUnavailableView(
          "No Active Session",
          systemImage: "person.3",
          description: Text("Join or create a session to view participants")
        )
      }
    }
    .navigationTitle("Participants")
  }

  private var participantsList: some View {
    List {
      ForEach(viewModel.participants) { participant in
        HStack {
          Circle()
            .fill(participant.active ? .green : .gray)
            .frame(width: 10, height: 10)

          Text(participant.displayName)
            .font(.body)

          Spacer()

          if participant.isHost {
            Label("Host", systemImage: "crown.fill")
              .font(.caption)
              .foregroundStyle(.orange)
          }
        }
        .padding(.vertical, 4)
      }
    }
    .listStyle(.insetGrouped)
  }
}

#Preview {
  ParticipantsDetailView(viewModel: SessionViewModel())
}
