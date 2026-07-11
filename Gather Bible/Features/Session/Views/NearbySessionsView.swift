import SwiftUI

struct NearbySessionsView: View {
  @ObservedObject var viewModel: SessionViewModel
  let onSelectSession: (DiscoveredSession) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      header

      if viewModel.isBrowsingNearby {
        if viewModel.nearbySessions.isEmpty {
          scanningView
        } else {
          sessionsList
        }
      }
    }
    .onAppear {
      viewModel.startBrowsingForNearbySessions()
    }
  }

  private var header: some View {
    HStack {
      Label("Nearby Sessions", systemImage: "antenna.radiowaves.left.and.right")
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      Spacer()

      if viewModel.isBrowsingNearby {
        Button("Stop") {
          viewModel.stopBrowsingForNearbySessions()
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .frame(minHeight: 44)
      } else {
        Button("Search") {
          viewModel.startBrowsingForNearbySessions()
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .frame(minHeight: 44)
      }
    }
  }

  private var scanningView: some View {
    HStack(spacing: 12) {
      ProgressView()
        .scaleEffect(0.8)

      Text("Scanning for nearby sessions...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private var sessionsList: some View {
    VStack(spacing: 8) {
      ForEach(viewModel.nearbySessions) { session in
        NearbySessionRow(session: session) {
          onSelectSession(session)
        }
      }
    }
  }
}

struct NearbySessionRow: View {
  let session: DiscoveredSession
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        Image(systemName: "iphone.radiowaves.left.and.right")
          .font(.title3)
          .foregroundStyle(.blue)
          .frame(width: 32)

        VStack(alignment: .leading, spacing: 2) {
          Text(session.hostName)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)

          Text("Code: \(session.joinCode)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Image(systemName: "arrow.right.circle.fill")
          .font(.title3)
          .foregroundStyle(.blue.opacity(0.8))
      }
      .padding()
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Join \(session.hostName)'s session, code \(spokenCode)")
    .accessibilityAddTraits(.isButton)
  }

  private var spokenCode: String {
    session.joinCode.map { String($0) }.joined(separator: " ")
  }
}

#Preview {
  NearbySessionsView(viewModel: SessionViewModel()) { _ in }
    .padding()
}
