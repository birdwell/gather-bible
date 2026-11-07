//
//  JoinSessionSheet.swift
//  Gather Bible
//
//  Sheet for joining an existing session
//

import SwiftUI

/// Sheet view for joining an existing session with a code
struct JoinSessionSheet: View {
  @ObservedObject var viewModel: SessionViewModel
  @Binding var isPresented: Bool

  @State private var joinCodeInput = ""
  @State private var displayNameInput = ""
  @FocusState private var isNameFocused: Bool
  @FocusState private var isCodeFocused: Bool

  init(viewModel: SessionViewModel, isPresented: Binding<Bool>, initialCode: String? = nil) {
    self._viewModel = ObservedObject(wrappedValue: viewModel)
    self._isPresented = isPresented
    self._joinCodeInput = State(initialValue: initialCode ?? "")
  }

  private var trimmedName: String {
    displayNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var canJoin: Bool {
    joinCodeInput.count == 6 && !trimmedName.isEmpty
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          FormField(label: "Session code") {
            SessionCodeField(
              code: $joinCodeInput,
              isFocused: $isCodeFocused,
              onSubmit: { isNameFocused = true },
              onComplete: {
                if trimmedName.isEmpty { isNameFocused = true }
              }
            )
          }

          FormField(label: "Your name") {
            TextField("How others will see you", text: $displayNameInput)
              .focused($isNameFocused)
              .textContentType(.name)
              .textInputAutocapitalization(.words)
              .submitLabel(.join)
              .onSubmit { attemptJoin() }
              .appField()
          }

          if let error = viewModel.errorMessage {
            InlineError(message: error)
          }

          NearbySessionsView(viewModel: viewModel) { session in
            guard !trimmedName.isEmpty else {
              isNameFocused = true
              return
            }
            Task {
              await viewModel.joinSession(
                joinCode: session.joinCode,
                displayName: trimmedName
              )
              if viewModel.isInSession {
                dismiss()
              }
            }
          }
        }
        .padding(16)
      }
      .scrollDismissesKeyboard(.interactively)
      .safeAreaInset(edge: .bottom, spacing: 0) {
        Button {
          attemptJoin()
        } label: {
          Group {
            if viewModel.isLoading {
              ProgressView()
            } else {
              Text("Join session")
            }
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.appPrimary)
        .disabled(!canJoin || viewModel.isLoading)
        .padding(16)
        .background(AppColor.ground)
      }
      .appNavigationTitle("Join a session")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .appSheet()
    .onAppear {
      viewModel.errorMessage = nil
      viewModel.isInlineErrorSheetPresented = true
      if joinCodeInput.isEmpty {
        isCodeFocused = true
      } else {
        isNameFocused = true
      }
    }
    .onDisappear {
      viewModel.isInlineErrorSheetPresented = false
      viewModel.errorMessage = nil
    }
  }

  private func attemptJoin() {
    guard canJoin else {
      if joinCodeInput.count < 6 {
        isCodeFocused = true
      } else {
        isNameFocused = true
      }
      return
    }
    Task {
      await viewModel.joinSession(
        joinCode: joinCodeInput,
        displayName: trimmedName
      )
      if viewModel.isInSession {
        dismiss()
      }
    }
  }

  private func dismiss() {
    isPresented = false
    joinCodeInput = ""
    displayNameInput = ""
    viewModel.errorMessage = nil
    viewModel.stopBrowsingForNearbySessions()
  }
}

#Preview {
  JoinSessionSheet(viewModel: SessionViewModel(), isPresented: .constant(true))
}
