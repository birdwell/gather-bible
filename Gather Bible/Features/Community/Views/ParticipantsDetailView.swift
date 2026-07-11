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
        ParticipantRow(
          participant: participant,
          isCurrentUser: participant.id == viewModel.userId
        )
      }
    }
    .listStyle(.insetGrouped)
  }
}

#Preview {
  ParticipantsDetailView(viewModel: SessionViewModel())
}
