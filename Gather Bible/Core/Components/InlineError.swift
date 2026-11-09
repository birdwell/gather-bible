//
//  InlineError.swift
//  Gather Bible
//
//  The one way to show an error next to the thing that caused it
//

import SwiftUI

struct InlineError: View {
  let message: String

  var body: some View {
    HStack(alignment: .top, spacing: 4) {
      AppIconView(.warning, size: 16)
      Text(message)
    }
      .font(AppFont.caption)
      .foregroundStyle(AppColor.danger)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityLabel("Error: \(message)")
  }
}

#Preview {
  InlineError(message: "Check the code and try again.")
    .padding()
}
