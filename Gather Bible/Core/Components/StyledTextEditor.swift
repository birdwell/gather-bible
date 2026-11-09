//
//  StyledTextEditor.swift
//  Gather Bible
//
//  Multi-line text input on a surface tone
//

import SwiftUI

struct StyledTextEditor: View {
  @Binding var text: String
  var placeholder: LocalizedStringKey?

  /// Scales the caller-supplied minimum height with Dynamic Type so the editor
  /// grows alongside the text it contains. The passed value is the base.
  @ScaledMetric private var minHeight: CGFloat

  init(text: Binding<String>, placeholder: LocalizedStringKey? = nil, minHeight: CGFloat = 100) {
    self._text = text
    self.placeholder = placeholder
    self._minHeight = ScaledMetric(wrappedValue: minHeight, relativeTo: .body)
  }

  var body: some View {
    TextEditor(text: $text)
      .font(AppFont.body)
      .foregroundStyle(AppColor.ink)
      .scrollContentBackground(.hidden)
      .frame(minHeight: minHeight)
      .padding(12)
      .background(alignment: .topLeading) {
        if text.isEmpty, let placeholder {
          Text(placeholder)
            .font(AppFont.body)
            .foregroundStyle(AppColor.muted)
            .padding(.horizontal, 17)
            .padding(.vertical, 20)
            .accessibilityHidden(true)
        }
      }
      .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 8))
  }
}

#Preview {
  StyledTextEditor(text: .constant(""), placeholder: "What stood out to you?")
    .padding()
}
