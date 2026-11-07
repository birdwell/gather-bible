//
//  DiscussionListSection.swift
//  Gather Bible
//

import SwiftUI

struct DiscussionListSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    Section {
      content
    } header: {
      Text(title)
        .font(AppFont.label)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
