//
//  NotInSessionView.swift
//  Gather Bible
//
//  View shown when user is not currently in a session
//

import SwiftUI

/// View displayed when the user is not in an active session
struct NotInSessionView: View {
    @ObservedObject var viewModel: SessionViewModel
    @Binding var showingJoinSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            actionButtons
            
            if viewModel.isLoading {
                ProgressView()
            }
        }.padding(24)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("Read Together")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a session and share the code with others to read the same passage in sync.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await viewModel.createSession() }
            } label: {
                Label("Create Session", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(viewModel.isLoading)
            
            Button {
                showingJoinSheet = true
            } label: {
                Label("Join Session", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(viewModel.isLoading)
        }
    }
}

#Preview {
    NotInSessionView(
        viewModel: SessionViewModel(),
        showingJoinSheet: .constant(false)
    )
    .padding()
}
