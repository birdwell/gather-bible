import SwiftUI

struct CreateSessionSheet: View {
  @ObservedObject var viewModel: SessionViewModel
  @Binding var isPresented: Bool

  @State private var hostNameInput = ""
  @FocusState private var isNameFieldFocused: Bool

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        FormField(label: "Your Name", helper: "This is how others will see you in nearby sessions") {
          TextField("Enter your name", text: $hostNameInput)
            .focused($isNameFieldFocused)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        if let error = viewModel.errorMessage {
          errorMessage(error)
        }
      }
      .padding()
      .navigationTitle("Create Session")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          if viewModel.isLoading {
            ProgressView()
          } else {
            Button("Create") {
              Task {
                await viewModel.createSession(
                  hostDisplayName: hostNameInput.isEmpty ? "Host" : hostNameInput
                )
                if viewModel.isInSession {
                  dismiss()
                }
              }
            }
          }
        }
      }
    }
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
    .onAppear {
      isNameFieldFocused = true
    }
  }

  private func errorMessage(_ error: String) -> some View {
    HStack {
      Image(systemName: "exclamationmark.triangle.fill")
        .accessibilityHidden(true)
      Text(error)
    }
    .font(.subheadline)
    .foregroundStyle(.red)
    .padding()
    .frame(maxWidth: .infinity)
    .background(Color.red.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private func dismiss() {
    isPresented = false
    hostNameInput = ""
  }
}

#Preview {
  CreateSessionSheet(viewModel: SessionViewModel(), isPresented: .constant(true))
}
