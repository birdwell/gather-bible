//
//  CreateDiscussionSheet.swift
//  Gather Bible
//
//  Sheet for host to create a discussion question
//

import SwiftUI

/// Sheet view for creating a discussion question
struct CreateDiscussionSheet: View {
  @ObservedObject var viewModel: SessionViewModel
  @Environment(\.dismiss) private var dismiss

  @State private var questionText = ""
  @State private var publishImmediately = true

  private var trimmedQuestion: String {
    questionText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        FormField(label: "Question", helper: "Ask a question for your group to discuss") {
          StyledTextEditor(text: $questionText, minHeight: 100)
        }

        VStack(alignment: .leading, spacing: 8) {
          Toggle("Send immediately", isOn: $publishImmediately)
            .accessibilityHint("Determines whether the discussion is sent now or saved as a draft")
          Text(
            publishImmediately
              ? "Guests will receive the prompt right away" : "Save as draft to send later"
          )
          .font(.caption)
          .foregroundStyle(.secondary)
        }

        errorMessage

      }
      .padding()
      .navigationTitle("Create Discussion")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            viewModel.errorMessage = nil
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          if viewModel.isLoading {
            ProgressView()
          } else {
            Button(publishImmediately ? "Send" : "Save") {
              Task {
                await viewModel.createDiscussion(
                  question: trimmedQuestion, publishImmediately: publishImmediately)
                if viewModel.errorMessage == nil {
                  dismiss()
                }
              }
            }
            .disabled(trimmedQuestion.isEmpty)
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .onAppear {
      viewModel.errorMessage = nil
      viewModel.isInlineErrorSheetPresented = true
    }
    .onDisappear {
      viewModel.isInlineErrorSheetPresented = false
      viewModel.errorMessage = nil
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
}

#Preview {
  CreateDiscussionSheet(viewModel: SessionViewModel())
}
