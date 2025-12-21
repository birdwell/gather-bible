//
//  SessionManagementView.swift
//  Gather Bible
//
//  Session management UI - simplified to follow Apple HIG
//

import SwiftUI

/// Session management UI component
struct SessionManagementView: View {
    @ObservedObject var viewModel: SessionViewModel
    @State private var showingJoinSheet = false
    @State private var joinCodeInput = ""
    @State private var displayNameInput = ""
    
    var body: some View {
        VStack(spacing: 16) {
            if !viewModel.isInSession {
                notInSessionView
            } else {
                inSessionView
            }
        }
    }
    
    // MARK: - Not In Session
    
    private var notInSessionView: some View {
        VStack(spacing: 20) {
            // Description
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
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    print("🔵 [UI] Create Session button tapped")
                    Task { await viewModel.createSession() }
                } label: {
                    Label("Create Session", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isLoading)
                
                Button {
                    showingJoinSheet = true
                } label: {
                    Label("Join Session", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isLoading)
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .sheet(isPresented: $showingJoinSheet) {
            joinSessionSheet
        }
    }
    
    // MARK: - In Session
    
    @State private var codeCopied = false
    
    private var inSessionView: some View {
        VStack(spacing: 16) {
            // Join code banner with copy button
            VStack(spacing: 8) {
                Text("Session Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Text(viewModel.joinCode)
                        .font(.system(.largeTitle, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .kerning(4)
                    
                    Button {
                        UIPasteboard.general.string = viewModel.joinCode
                        codeCopied = true
                        
                        // Reset after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            codeCopied = false
                        }
                    } label: {
                        Image(systemName: codeCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.title2)
                            .foregroundStyle(codeCopied ? .green : .accentColor)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                }
                
                if codeCopied {
                    Text("Copied!")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .transition(.opacity.combined(with: .scale))
                }
                
                if viewModel.isHost {
                    Label("You're hosting", systemImage: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .animation(.easeInOut(duration: 0.2), value: codeCopied)
            
            // Participants count
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.secondary)
                Text("\(viewModel.activeParticipantCount) participant\(viewModel.activeParticipantCount == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Current position
                Text("\(viewModel.currentBook) \(viewModel.currentChapter)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            
            // Follow host toggle (guests only)
            if !viewModel.isHost {
                Toggle("Follow Host", isOn: $viewModel.followHost)
                    .onChange(of: viewModel.followHost) { _, _ in
                        viewModel.toggleFollowHost()
                    }
            }
            
            // Claim host (when host is inactive)
            if !viewModel.isHost && viewModel.isCurrentHostInactive {
                Button {
                    Task { await viewModel.claimHost() }
                } label: {
                    Label("Claim Host", systemImage: "crown.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(viewModel.isLoading)
            }
            
            Divider()
            
            // Leave button
            Button(role: .destructive) {
                Task { await viewModel.leaveSession() }
            } label: {
                Label("Leave Session", systemImage: "xmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
            
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
    
    // MARK: - Join Sheet
    
    private var joinSessionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Join code input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Code")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("ABC123", text: $joinCodeInput)
                        .font(.system(.largeTitle, design: .monospaced))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .kerning(6)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: joinCodeInput) { _, newValue in
                            joinCodeInput = String(newValue.prefix(6)).uppercased()
                        }
                }
                
                // Display name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter your name", text: $displayNameInput)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("This is how others will see you")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // Error message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                    }
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
                
                // Join button
                Button {
                    Task {
                        await viewModel.joinSession(
                            joinCode: joinCodeInput,
                            displayName: displayNameInput.isEmpty ? "Guest" : displayNameInput
                        )
                        if viewModel.isInSession {
                            showingJoinSheet = false
                            joinCodeInput = ""
                            displayNameInput = ""
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Join Session")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(joinCodeInput.count != 6 || viewModel.isLoading)
            }
            .padding()
            .navigationTitle("Join Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingJoinSheet = false
                        joinCodeInput = ""
                        displayNameInput = ""
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview("Not in Session") {
    SessionManagementView(viewModel: SessionViewModel())
        .padding()
}
