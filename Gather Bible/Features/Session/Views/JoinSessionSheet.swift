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
  @FocusState private var isNameFieldFocused: Bool

  init(viewModel: SessionViewModel, isPresented: Binding<Bool>, initialCode: String? = nil) {
    self._viewModel = ObservedObject(wrappedValue: viewModel)
    self._isPresented = isPresented
    self._joinCodeInput = State(initialValue: initialCode ?? "")
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          FormField(label: "Your Name", helper: "This is how others will see you") {
            TextField("Enter your name", text: $displayNameInput)
              .focused($isNameFieldFocused)
              .padding()
              .background(Color(.secondarySystemBackground))
              .clipShape(RoundedRectangle(cornerRadius: 12))
          }

          NearbySessionsView(viewModel: viewModel) { session in
            Task {
              await viewModel.joinSession(
                joinCode: session.joinCode,
                displayName: displayNameInput.isEmpty ? "Guest" : displayNameInput
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
            Button("Join") {
              Task {
                await viewModel.joinSession(
                  joinCode: joinCodeInput,
                  displayName: displayNameInput.isEmpty ? "Guest" : displayNameInput
                )
                if viewModel.isInSession {
                  dismiss()
                }
              }
            }
            .disabled(joinCodeInput.count != 6)
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .onAppear {
      isNameFieldFocused = true
    }
  }

  private var sessionCodeInput: some View {
    FormField(label: "Session Code") {
      TextField("ABC123", text: $joinCodeInput)
        .font(.system(.title, design: .monospaced))
        .fontWeight(.bold)
        .multilineTextAlignment(.center)
        .kerning(6)
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
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
    viewModel.stopBrowsingForNearbySessions()
  }
}

#Preview {
  JoinSessionSheet(viewModel: SessionViewModel(), isPresented: .constant(true))
}
