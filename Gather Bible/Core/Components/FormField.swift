//
//  FormField.swift
//  Gather Bible
//
//  Reusable form field wrapper with label and helper text
//

import SwiftUI

/// A wrapper that adds a label and optional helper text to any input
struct FormField<Content: View>: View {
  let label: String
  var helper: String? = nil
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(AppFont.caption)
        .foregroundStyle(AppColor.muted)
        // Hidden from VoiceOver to avoid double-reading: the label is instead
        // associated directly with the input below.
        .accessibilityHidden(true)

      content()
        .accessibilityLabel(label)

      if let helper {
        Text(helper)
          .font(AppFont.caption)
          .foregroundStyle(AppColor.muted)
      }
    }
    .accessibilityElement(children: .contain)
  }
}

#Preview {
  VStack(spacing: 24) {
    FormField(label: "Email", helper: "We'll never share your email") {
      TextField("Enter email", text: .constant(""))
        .textFieldStyle(.roundedBorder)
    }

    FormField(label: "Name") {
      TextField("Enter name", text: .constant(""))
        .textFieldStyle(.roundedBorder)
    }
  }
  .padding()
}
