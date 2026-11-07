import SwiftUI

struct CommunityView: View {
  @EnvironmentObject var sessionViewModel: SessionViewModel

  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        SessionManagementView(viewModel: sessionViewModel)
          .padding(16)
          .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
      }
    }
    .background(AppColor.ground.ignoresSafeArea())
    .navigationTitle("Community")
    .toolbar(.hidden, for: .navigationBar)
  }
}

#Preview {
  NavigationStack {
    CommunityView()
      .environmentObject(SessionViewModel())
  }
}
