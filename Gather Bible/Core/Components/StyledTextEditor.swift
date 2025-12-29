//
//  StyledTextEditor.swift
//  Gather Bible
//
//  Reusable styled text editor component
//

import SwiftUI

/// A styled text editor with consistent background and border styling
struct StyledTextEditor: View {
  @Binding var text: String
  var minHeight: CGFloat = 100

  var body: some View {
    TextEditor(text: $text)
      .frame(minHeight: minHeight)
      .padding(12)
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color(.separator), lineWidth: 0.5)
      )
  }
}

#Preview {
  StyledTextEditor(text: .constant("Sample text"))
    .padding()
}
