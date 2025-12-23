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
          Text(
            publishImmediately
              ? "Guests will receive the prompt right away" : "Save as draft to send later"
          )
          .font(.caption)
          .foregroundStyle(.tertiary)
        }

        Spacer()

        AsyncActionButton(
          title: publishImmediately ? "Send Discussion" : "Save Draft",
          isLoading: viewModel.isLoading,
          isDisabled: trimmedQuestion.isEmpty
        ) {
          await viewModel.createDiscussion(
            question: trimmedQuestion, publishImmediately: publishImmediately)
          dismiss()
        }
      }
      .padding()
      .navigationTitle("Create Discussion")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium])
  }
}

#Preview {
  CreateDiscussionSheet(viewModel: SessionViewModel())
}
