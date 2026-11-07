//
//  SessionQRCodeView.swift
//  Gather Bible
//
//  QR code display for sharing session join codes
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// Displays a QR code that can be scanned to join the session
struct SessionQRCodeView: View {
  let sessionCode: String
  @Environment(\.dismiss) private var dismiss

  private var joinURLString: String {
    "gatherbible://join?code=\(sessionCode)"
  }

  private var joinURL: URL? {
    URL(string: joinURLString)
  }

  private var qrCodeImage: UIImage? {
    generateQRCode(from: joinURLString)
  }

  private var spokenCode: String {
    sessionCode.map { String($0) }.joined(separator: " ")
  }

  var body: some View {
    sheetContent.appSheet()
  }

  private var sheetContent: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          if let qrImage = qrCodeImage {
            Image(uiImage: qrImage)
              .interpolation(.none)
              .resizable()
              .scaledToFit()
              .frame(width: 250, height: 250)
              .padding(20)
              .background(Color.white)
              .clipShape(RoundedRectangle(cornerRadius: 12))
              .accessibilityLabel("QR code for session \(sessionCode)")
          } else {
            ProgressView()
              .frame(width: 250, height: 250)
          }

          VStack(spacing: 8) {
            Text("Session code")
              .font(AppFont.caption)
              .foregroundStyle(AppColor.muted)

            Text(sessionCode)
              .font(AppFont.heading)
              .fontWeight(.bold)
              .accessibilityLabel(spokenCode)
          }

          if let joinURL {
            ShareLink(
              item: joinURL,
              subject: Text("Join my Bible reading session"),
              message: Text("Tap to join my reading session, or enter code \(sessionCode).")
            ) {
              HStack(spacing: 8) {
                AppIconView(.share)
                Text("Share invite")
              }
            }
            .buttonStyle(.appSecondary)
          }
        }
        .padding()
        .frame(maxWidth: .infinity)
      }
      .background(AppColor.ground)
      .appNavigationTitle("Scan to join")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private func generateQRCode(from string: String) -> UIImage? {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    guard let data = string.data(using: .utf8) else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("H", forKey: "inputCorrectionLevel")

    guard let outputImage = filter.outputImage else { return nil }

    let scale = 10.0
    let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

    guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
      return nil
    }

    return UIImage(cgImage: cgImage)
  }
}

#Preview {
  SessionQRCodeView(sessionCode: "ABC123")
}
