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
  @FocusState private var focusedField: Field?

  private enum Field: Hashable {
    case name
    case code
  }

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
        VStack(spacing: 24) {
          FormField(label: "Your Name", helper: "This is how others will see you") {
            TextField("Enter your name", text: $displayNameInput)
              .focused($focusedField, equals: .name)
              .textContentType(.name)
              .textInputAutocapitalization(.words)
              .submitLabel(.next)
              .onSubmit { focusedField = .code }
              .padding()
              .background(Color(.secondarySystemBackground))
              .clipShape(RoundedRectangle(cornerRadius: 12))
          }

          NearbySessionsView(viewModel: viewModel) { session in
            guard !trimmedName.isEmpty else {
              focusedField = .name
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

          divider

          sessionCodeInput

          errorMessage
        }
        .padding()
      }
      .navigationTitle("Join Session")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          if viewModel.isLoading {
            ProgressView()
          } else {
            Button("Join") { attemptJoin() }
              .disabled(!canJoin)
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .onAppear {
      viewModel.errorMessage = nil
      viewModel.isInlineErrorSheetPresented = true
      focusedField = .name
    }
    .onDisappear {
      viewModel.isInlineErrorSheetPresented = false
      viewModel.errorMessage = nil
    }
  }

  private func attemptJoin() {
    guard canJoin else {
      if trimmedName.isEmpty { focusedField = .name }
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

  private var sessionCodeInput: some View {
    FormField(label: "Session Code") {
      TextField("ABC123", text: $joinCodeInput)
        .font(.system(.title, design: .monospaced))
        .fontWeight(.bold)
        .multilineTextAlignment(.center)
        .keyboardType(.asciiCapable)
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
        .focused($focusedField, equals: .code)
        .submitLabel(.join)
        .onSubmit { attemptJoin() }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: joinCodeInput) { _, newValue in
          joinCodeInput = String(newValue.prefix(6)).uppercased()
        }
    }
  }

  @ViewBuilder
  private var errorMessage: some View {
    if let error = viewModel.errorMessage {
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
      .accessibilityElement(children: .combine)
      .accessibilityLabel("Error: \(error)")
      .accessibilityAddTraits(.isStaticText)
    }
  }

  private var divider: some View {
    HStack {
      Rectangle()
        .fill(Color(.separator))
        .frame(height: 1)

      Text("or enter code")
        .font(.caption)
        .foregroundStyle(.secondary)

      Rectangle()
        .fill(Color(.separator))
        .frame(height: 1)
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
