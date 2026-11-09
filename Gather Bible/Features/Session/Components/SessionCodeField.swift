import SwiftUI

/// Six tiles over a real text field, so typing, paste, and VoiceOver all work.
struct SessionCodeField: View {
  @Binding var code: String
  var isFocused: FocusState<Bool>.Binding
  let onSubmit: () -> Void
  var onComplete: () -> Void = {}

  private let length = 6

  var body: some View {
    ZStack {
      TextField("", text: $code)
        .focused(isFocused)
        .keyboardType(.asciiCapable)
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
        .submitLabel(.join)
        .onSubmit(onSubmit)
        .foregroundStyle(.clear)
        .tint(.clear)
        .onChange(of: code) { _, newValue in
          let cleaned = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
          let limited = String(cleaned.prefix(length))
          if limited != code { code = limited }
          if limited.count == length { onComplete() }
        }

      HStack(spacing: 8) {
        ForEach(0..<length, id: \.self) { tile(at: $0) }
      }
      .allowsHitTesting(false)
      .accessibilityElement(children: .ignore)
      .accessibilityHidden(true)
    }
    .frame(height: 56)
    .contentShape(Rectangle())
    .onTapGesture { isFocused.wrappedValue = true }
  }

  private func tile(at index: Int) -> some View {
    let characters = Array(code)
    let isCurrent = isFocused.wrappedValue && index == min(characters.count, length - 1)

    return Text(index < characters.count ? String(characters[index]) : " ")
      .font(AppFont.heading)
      .foregroundStyle(AppColor.ink)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 8))
      .overlay {
        if isCurrent {
          RoundedRectangle(cornerRadius: 8).strokeBorder(AppColor.ink, lineWidth: 2)
        }
      }
  }
}
