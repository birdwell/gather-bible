

import SwiftUI

struct CommunityView: View {
  @EnvironmentObject var sessionViewModel: SessionViewModel

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        SessionManagementView(viewModel: sessionViewModel)
      }
      .padding(16)
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
