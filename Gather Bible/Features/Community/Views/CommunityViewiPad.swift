//
//  CommunityViewiPad.swift
//  Gather Bible
//
//  iPad-optimized Community view using NavigationSplitView
//

import SwiftUI

enum CommunitySection: String, CaseIterable, Identifiable {
  case session = "Session"
  case discussions = "Discussions"
  case participants = "Participants"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .session: return "person.2.fill"
    case .discussions: return "bubble.left.and.bubble.right.fill"
    case .participants: return "person.3.fill"
    }
  }
}

struct CommunityViewiPad: View {
  @EnvironmentObject var sessionViewModel: SessionViewModel
  @State private var selectedSection: CommunitySection? = .session
  @State private var columnVisibility: NavigationSplitViewVisibility = .all

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      sidebar
        .navigationTitle("Community")
    } detail: {
      detailView
    }
    .navigationSplitViewStyle(.balanced)
  }

  // MARK: - Sidebar

  private var sidebar: some View {
    List(selection: $selectedSection) {
      Section {
        ForEach(CommunitySection.allCases) { section in
          sidebarRow(for: section)
            .tag(section)
        }
      } header: {
        if sessionViewModel.isInSession {
          sessionStatusHeader
        }
      }

      if !sessionViewModel.isInSession {
        Section {
          quickActions
        }
      }
    }
    .listStyle(.sidebar)
  }

  private func sidebarRow(for section: CommunitySection) -> some View {
    Label {
      HStack {
        Text(section.rawValue)
        Spacer()
        if section == .participants && sessionViewModel.isInSession {
          Text("\(sessionViewModel.activeParticipantCount)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
        }
        if section == .discussions && sessionViewModel.activeDiscussion != nil {
          Circle()
            .fill(.blue)
            .frame(width: 8, height: 8)
        }
      }
    } icon: {
      Image(systemName: section.icon)
    }
  }

  private var sessionStatusHeader: some View {
    HStack {
      Circle()
        .fill(.green)
        .frame(width: 8, height: 8)
      Text("In Session")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
      Text(sessionViewModel.joinCode)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
  }

  private var quickActions: some View {
    VStack(spacing: 12) {
      Button {
        Task { await sessionViewModel.createSession() }
      } label: {
        Label("Create Session", systemImage: "plus.circle.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(sessionViewModel.isLoading)
    }
    .padding(.vertical, 8)
  }

  // MARK: - Detail View

  @ViewBuilder
  private var detailView: some View {
    switch selectedSection {
    case .session:
      SessionDetailView(viewModel: sessionViewModel)
    case .discussions:
      DiscussionsDetailView(viewModel: sessionViewModel)
    case .participants:
      ParticipantsDetailView(viewModel: sessionViewModel)
    case .none:
      ContentUnavailableView(
        "Select a Section",
        systemImage: "sidebar.left",
        description: Text("Choose a section from the sidebar")
      )
    }
  }
}

#Preview {
  CommunityViewiPad()
    .environmentObject(SessionViewModel())
}
