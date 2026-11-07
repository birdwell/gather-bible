//
//  DiscussionPromptSheet.swift
//  Gather Bible
//
//  Sheet for guests to respond to a discussion question
//

import SwiftUI

/// Sheet view for guests to respond to a discussion prompt
struct DiscussionPromptSheet: View {
  @ObservedObject var viewModel: SessionViewModel
  @Environment(\.dismiss) private var dismiss

  @State private var responseText = ""
  @FocusState private var isResponseFocused: Bool

  private var trimmedResponse: String {
    responseText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          if let discussion = viewModel.activeDiscussion {
            Text(discussion.question)
              .font(AppFont.display)
              .foregroundStyle(AppColor.ink)
              .fixedSize(horizontal: false, vertical: true)
              .accessibilityAddTraits(.isHeader)
          }

          StyledTextEditor(text: $responseText, placeholder: "Your response", minHeight: 120)
            .focused($isResponseFocused)
            .accessibilityLabel("Your response")

          if let error = viewModel.errorMessage {
            InlineError(message: error)
          }

          Button {
            Task {
              await viewModel.submitDiscussionResponse(response: trimmedResponse)
              if viewModel.errorMessage == nil {
                dismiss()
              }
            }
          } label: {
            Group {
              if viewModel.isLoading {
                ProgressView()
              } else {
                Text("Share response")
              }
            }
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.appPrimary)
          .disabled(trimmedResponse.isEmpty || viewModel.isLoading)
        }
        .padding(16)
      }
      .appNavigationTitle("Discussion")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Skip") {
            viewModel.errorMessage = nil
            viewModel.dismissDiscussionPrompt()
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.large])
    .interactiveDismissDisabled(!trimmedResponse.isEmpty)
    .appSheet()
    .onAppear {
      viewModel.errorMessage = nil
      viewModel.isInlineErrorSheetPresented = true
      isResponseFocused = true
    }
    .onDisappear {
      viewModel.isInlineErrorSheetPresented = false
      viewModel.errorMessage = nil
    }
  }
}

#Preview {
  DiscussionPromptSheet(viewModel: SessionViewModel())
}
