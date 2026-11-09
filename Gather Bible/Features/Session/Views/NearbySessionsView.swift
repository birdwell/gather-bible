import SwiftUI

struct NearbySessionsView: View {
  @ObservedObject var viewModel: SessionViewModel
  let onSelectSession: (DiscoveredSession) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Text("Nearby")
          .font(AppFont.caption)
          .foregroundStyle(AppColor.muted)
        if viewModel.isBrowsingNearby && viewModel.nearbySessions.isEmpty {
          ProgressView()
            .controlSize(.mini)
            .accessibilityLabel("Looking for nearby sessions")
        }
      }

      if viewModel.nearbySessions.isEmpty {
        Text("No sessions on this network yet.")
          .font(AppFont.body)
          .foregroundStyle(AppColor.muted)
      } else {
        ForEach(viewModel.nearbySessions) { session in
          NearbySessionRow(session: session) {
            onSelectSession(session)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
      viewModel.startBrowsingForNearbySessions()
    }
  }
}

struct NearbySessionRow: View {
  let session: DiscoveredSession
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        Text("\(session.hostName)’s session")
          .font(AppFont.label)
          .foregroundStyle(AppColor.ink)

        Spacer(minLength: 0)

        Text(session.joinCode)
          .font(AppFont.caption)
          .foregroundStyle(AppColor.muted)

        AppIconView(.caretRight, size: 16)
          .foregroundStyle(AppColor.muted)
      }
      .frame(minHeight: 44)
      .contentShape(Rectangle())
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
