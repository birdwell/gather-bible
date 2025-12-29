

import SwiftUI

struct CommunityView: View {
  @EnvironmentObject var sessionViewModel: SessionViewModel
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  private var isRegularWidth: Bool {
    horizontalSizeClass == .regular
  }

  var body: some View {
    ScrollView {
      VStack(spacing: isRegularWidth ? 24 : 16) {
        SessionManagementView(viewModel: sessionViewModel)
      }
      .padding(isRegularWidth ? 32 : 16)
      .frame(maxWidth: .infinity)
    }
    .navigationTitle("Community")
  }
}

#Preview {
    NavigationStack {
        CommunityView()
            .environmentObject(SessionViewModel())
    }
}
