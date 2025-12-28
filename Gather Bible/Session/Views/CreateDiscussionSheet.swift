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
            .accessibilityHint(publishImmediately ? "Currently on. Guests will receive the prompt right away" : "Currently off. Discussion will be saved as draft")
          Text(
            publishImmediately
              ? "Guests will receive the prompt right away" : "Save as draft to send later"
          )
          .font(.caption)
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
        }

      }
      .padding()
      .navigationTitle("Create Discussion")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          if viewModel.isLoading {
            ProgressView()
          } else {
            Button(publishImmediately ? "Send" : "Save") {
              Task {
                await viewModel.createDiscussion(
                  question: trimmedQuestion, publishImmediately: publishImmediately)
                dismiss()
              }
            }
            .disabled(trimmedQuestion.isEmpty)
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}

#Preview {
  CreateDiscussionSheet(viewModel: SessionViewModel())
}
