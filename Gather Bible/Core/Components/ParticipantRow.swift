//
//  ParticipantRow.swift
//  Gather Bible
//
//  Reusable row component for displaying a session participant
//

import SwiftUI

/// A row component for displaying a session participant with status and host indicators
struct ParticipantRow: View {
  let participant: SessionParticipant
  var isCurrentUser: Bool = false
  var showActiveIndicator: Bool = true

  var body: some View {
    HStack {
      if showActiveIndicator {
        Circle()
          .fill(participant.active ? .green : .gray)
          .frame(width: 10, height: 10)
      }

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

        if !participant.active && !showActiveIndicator {
          Text("Inactive")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      if isCurrentUser {
        Text("(You)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  List {
    ParticipantRow(
      participant: SessionParticipant(
        userId: "1",
        from: ["displayName": "John", "isHost": true, "active": true]
      )!,
      isCurrentUser: true
    )
    ParticipantRow(
      participant: SessionParticipant(
        userId: "2",
        from: ["displayName": "Jane", "isHost": false, "active": true]
      )!
    )
    ParticipantRow(
      participant: SessionParticipant(
        userId: "3",
        from: ["displayName": "Bob", "isHost": false, "active": false]
      )!
    )
  }
}
