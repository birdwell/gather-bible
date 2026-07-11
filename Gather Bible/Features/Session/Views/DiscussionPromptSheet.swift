//
//  DiscussionPromptSheet.swift
//  Gather Bible
//
//  Half-sheet for guests to respond to a discussion question
//

import SwiftUI

/// Sheet view for guests to respond to a discussion prompt
struct DiscussionPromptSheet: View {
  @ObservedObject var viewModel: SessionViewModel
  @Environment(\.dismiss) private var dismiss

  @State private var responseText = ""

  private var trimmedResponse: String {
    responseText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        if let discussion = viewModel.activeDiscussion {
          QuestionHeader(question: discussion.question)
        }

        FormField(label: "Your Response") {
          StyledTextEditor(text: $responseText, minHeight: 120)
        }

        errorMessage

        Spacer()
      }
      .padding()
      .navigationTitle("Discussion")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Skip") {
            viewModel.errorMessage = nil
            viewModel.dismissDiscussionPrompt()
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          if viewModel.isLoading {
            ProgressView()
          } else {
            Button("Submit") {
              Task {
                await viewModel.submitDiscussionResponse(response: trimmedResponse)
                if viewModel.errorMessage == nil {
                  dismiss()
                }
              }
            }
            .disabled(trimmedResponse.isEmpty)
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .interactiveDismissDisabled(!trimmedResponse.isEmpty)
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

private struct QuestionHeader: View {
  let question: String

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "bubble.left.and.bubble.right.fill")
        .font(.system(size: 32))
        .foregroundStyle(.blue)

      Text(question)
        .font(.title3)
        .fontWeight(.medium)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  DiscussionPromptSheet(viewModel: SessionViewModel())
}
