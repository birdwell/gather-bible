//
//  DraftBadge.swift
//  Gather Bible
//

import SwiftUI

struct DraftBadge: View {
  var body: some View {
    Text("Draft")
      .font(.caption)
      .foregroundStyle(.orange)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color.orange.opacity(0.15))
      .clipShape(Capsule())
  }
}

#Preview {
  DraftBadge()
}
