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

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        sessionCodeInput
        displayNameInputSection
        errorMessage

        Spacer()

        joinButton
      }
      .padding()
      .navigationTitle("Join Session")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium])
  }

  // MARK: - Session Code Input

  private var sessionCodeInput: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Session Code")
        .font(.subheadline)
        .foregroundStyle(.secondary)

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

  // MARK: - Display Name Input

  private var displayNameInputSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Your Name")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      TextField("Enter your name", text: $displayNameInput)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))

      Text("This is how others will see you")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
  }

  // MARK: - Error Message

  @ViewBuilder
  private var errorMessage: some View {
    if let error = viewModel.errorMessage {
      HStack {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
        Text(error)
          .foregroundStyle(.red)
      }
      .font(.subheadline)
      .padding()
      .frame(maxWidth: .infinity)
      .background(Color.red.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
  }

  // MARK: - Join Button

  private var joinButton: some View {
    Button {
      Task {
        await viewModel.joinSession(
          joinCode: joinCodeInput,
          displayName: displayNameInput.isEmpty ? "Guest" : displayNameInput
        )
        if viewModel.isInSession {
          dismiss()
        }
      }
    } label: {
      Group {
        if viewModel.isLoading {
          ProgressView()
            .tint(.white)
        } else {
          Text("Join Session")
            .fontWeight(.semibold)
        }
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
    .disabled(joinCodeInput.count != 6 || viewModel.isLoading)
  }

  // MARK: - Helpers

  private func dismiss() {
    isPresented = false
    joinCodeInput = ""
    displayNameInput = ""
  }
}

#Preview {
  JoinSessionSheet(
    viewModel: SessionViewModel(),
    isPresented: .constant(true)
  )
}
