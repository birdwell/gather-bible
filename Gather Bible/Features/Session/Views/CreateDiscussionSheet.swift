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
  @FocusState private var isQuestionFocused: Bool

  private var trimmedQuestion: String {
    questionText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var canSubmit: Bool {
    !trimmedQuestion.isEmpty && !viewModel.isLoading
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          StyledTextEditor(
            text: $questionText,
            placeholder: "What stood out to you?",
            minHeight: 120
          )
          .focused($isQuestionFocused)
          .accessibilityLabel("Question")

          if let error = viewModel.errorMessage {
            InlineError(message: error)
          }

          VStack(spacing: 8) {
            Button {
              submit(publishImmediately: true)
            } label: {
              Text("Send to group")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.appPrimary)
            .disabled(!canSubmit)
            .disabled(viewModel.activeDiscussion != nil)

            Button {
              submit(publishImmediately: false)
            } label: {
              Text("Save as draft")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.appSecondary)
            .disabled(!canSubmit)
          }
        }
        .padding(16)
      }
      .appNavigationTitle("Ask a question")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            viewModel.errorMessage = nil
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
    .appSheet()
    .onAppear {
      viewModel.errorMessage = nil
      viewModel.isInlineErrorSheetPresented = true
      isQuestionFocused = true
    }
    .onDisappear {
      viewModel.isInlineErrorSheetPresented = false
      viewModel.errorMessage = nil
    }
  }

  private func submit(publishImmediately: Bool) {
    Task {
      await viewModel.createDiscussion(
        question: trimmedQuestion,
        publishImmediately: publishImmediately
      )
      if viewModel.errorMessage == nil {
        dismiss()
      }
    }
  }
}

#Preview {
  CreateDiscussionSheet(viewModel: SessionViewModel())
}
