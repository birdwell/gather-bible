

import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var sessionViewModel: SessionViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SessionManagementView(viewModel: sessionViewModel)
            }
            .padding()
        }
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        CommunityView()
            .environmentObject(SessionViewModel())
    }
}