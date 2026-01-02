//
//  QueueListView.swift
//  Gather Bible
//
//  View for displaying and managing the session queue
//

import SwiftUI

struct QueueListView: View {
  @ObservedObject var viewModel: SessionViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.queue.isEmpty {
          ContentUnavailableView(
            "No Items in Queue",
            systemImage: "list.number",
            description: Text("Add passages to navigate through during your session.")
          )
        } else {
          List {
            ForEach(Array(viewModel.queue.enumerated()), id: \.element.id) { index, reference in
              QueueItemRow(
                reference: reference,
                index: index,
                isCurrentItem: index == viewModel.currentQueueIndex,
                onTap: {
                  Task {
                    await viewModel.navigateToQueueIndex(index)
                    dismiss()
                  }
                }
              )
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
          }
          .listStyle(.insetGrouped)
        }
      }
      .navigationTitle("Queue")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
        }
        if !viewModel.queue.isEmpty {
          ToolbarItem(placement: .primaryAction) {
            EditButton()
          }
        }
      }
    }
  }

  private func deleteItems(at offsets: IndexSet) {
    for index in offsets {
      let reference = viewModel.queue[index]
      Task {
        await viewModel.removeFromQueue(referenceId: reference.id)
      }
    }
  }

  private func moveItems(from source: IndexSet, to destination: Int) {
    var reorderedQueue = viewModel.queue
    reorderedQueue.move(fromOffsets: source, toOffset: destination)
    Task {
      await viewModel.reorderQueue(queue: reorderedQueue)
    }
  }
}

// MARK: - Queue Item Row

struct QueueItemRow: View {
  let reference: QueuedReference
  let index: Int
  let isCurrentItem: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        Text("\(index + 1)")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(isCurrentItem ? .white : .secondary)
          .frame(width: 24, height: 24)
          .background(isCurrentItem ? Color.accentColor : Color(.systemGray5))
          .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(reference.displayLabel)
            .font(.body)
            .fontWeight(isCurrentItem ? .semibold : .regular)
            .foregroundStyle(.primary)

          if !reference.isWholeChapter {
            Text(reference.isSingleVerse ? "Single verse" : "Verse range")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        if isCurrentItem {
          Image(systemName: "play.fill")
            .font(.caption)
            .foregroundStyle(Color.accentColor)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  QueueListView(viewModel: SessionViewModel())
}
