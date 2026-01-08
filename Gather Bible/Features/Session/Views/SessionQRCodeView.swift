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

  private var qrCodeImage: UIImage? {
    generateQRCode(from: "gatherbible://join?code=\(sessionCode)")
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Text("Scan to Join")
          .font(.title2)
          .fontWeight(.semibold)

        if let qrImage = qrCodeImage {
          Image(uiImage: qrImage)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 250, height: 250)
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 4)
            .accessibilityLabel("QR code for session \(sessionCode)")
        } else {
          ProgressView()
            .frame(width: 250, height: 250)
        }

        VStack(spacing: 8) {
          Text("Session Code")
            .font(.caption)
            .foregroundStyle(.secondary)

          Text(sessionCode)
            .font(.system(.title, design: .monospaced))
            .fontWeight(.bold)
            .kerning(4)
        }

        Text("Have others scan this QR code to join your session")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.systemBackground))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium])
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
