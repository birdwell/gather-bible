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
        EmptyState(
          title: "No active session",
          message: "Join or start a session to see who’s here."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
    }
    .background(AppColor.ground.ignoresSafeArea())
    .appNavigationTitle("Participants")
  }

  private var participantsList: some View {
    List {
      ForEach(viewModel.participants) { participant in
        ParticipantRow(
          participant: participant,
          isCurrentUser: participant.id == viewModel.userId
        )
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }
}

#Preview {
  ParticipantsDetailView(viewModel: SessionViewModel())
}
