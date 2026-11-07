import SwiftUI

struct CreateSessionSheet: View {
  @ObservedObject var viewModel: SessionViewModel
  @Binding var isPresented: Bool

  @State private var hostNameInput = ""
  @FocusState private var isNameFieldFocused: Bool

  private var trimmedName: String {
    hostNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 24) {
        FormField(label: "Your name") {
          TextField("How others will see you", text: $hostNameInput)
            .focused($isNameFieldFocused)
            .textContentType(.name)
            .textInputAutocapitalization(.words)
            .submitLabel(.go)
            .onSubmit { attemptCreate() }
            .appField()
        }

        if let error = viewModel.errorMessage {
          InlineError(message: error)
        }

        Button {
          attemptCreate()
        } label: {
          Group {
            if viewModel.isLoading {
              ProgressView()
            } else {
              Text("Start session")
            }
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.appPrimary)
        .disabled(trimmedName.isEmpty || viewModel.isLoading)

        Spacer(minLength: 0)
      }
      .padding(16)
      .appNavigationTitle("Start a session")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
    .appSheet()
    .onAppear {
      viewModel.errorMessage = nil
      viewModel.isInlineErrorSheetPresented = true
      isNameFieldFocused = true
    }
    .onDisappear {
      viewModel.isInlineErrorSheetPresented = false
      viewModel.errorMessage = nil
    }
  }

  private func attemptCreate() {
    guard !trimmedName.isEmpty else { return }
    Task {
      await viewModel.createSession(hostDisplayName: trimmedName)
      if viewModel.isInSession {
        dismiss()
      }
    }
  }

  private func dismiss() {
    isPresented = false
    hostNameInput = ""
    viewModel.errorMessage = nil
  }
}

#Preview {
  CreateSessionSheet(viewModel: SessionViewModel(), isPresented: .constant(true))
}
