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

  @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 10

  var body: some View {
    HStack {
      if showActiveIndicator {
        Circle()
          .fill(participant.active ? Color.green : Color.secondary)
          .frame(width: dotSize, height: dotSize)
          .accessibilityHidden(true)
      }

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(participant.displayName)
            .font(.headline)

          if participant.isHost {
            Image(systemName: "crown.fill")
              .font(.caption)
              .foregroundStyle(.orange)
              .accessibilityHidden(true)
          }
        }

        // Textual (non-color) status cue: shown for any inactive participant so
        // status is never conveyed by the colored dot alone.
        if !participant.active {
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
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
  }

  /// Composes a single spoken label from the row's visible state, e.g.
  /// "Sarah, Host, Active, You".
  private var accessibilityLabel: String {
    var parts: [String] = [participant.displayName]

    if participant.isHost {
      parts.append("Host")
    }

    if showActiveIndicator {
      parts.append(participant.active ? "Active" : "Inactive")
    } else if !participant.active {
      parts.append("Inactive")
    }

    if isCurrentUser {
      parts.append("You")
    }

    return parts.joined(separator: ", ")
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
