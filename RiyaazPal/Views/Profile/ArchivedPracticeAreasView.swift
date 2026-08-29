//
//  ArchivedPracticeAreasView.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-28.
//

import SwiftData
import SwiftUI

struct ArchivedPracticeAreasView: View {

    @Environment(\.modelContext) private var context

    @Query(sort: \PracticeAreaEntity.order)
    private var areas: [PracticeAreaEntity]

    @StateObject private var viewModel = PracticeAreasViewModel()

    @State private var showInlineDuplicateMessage = false
    @State private var areaPendingDeletion: PracticeAreaEntity?
    @State private var showDeleteAllConfirmation = false

    private var archivedAreas: [PracticeAreaEntity] {
        areas
            .filter { !$0.isActive }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    var body: some View {
        List {
            Section {
                if archivedAreas.isEmpty {
                    emptyState
                } else {
                    ForEach(archivedAreas) { area in
                        ArchivedPracticeAreaRow(area: area) {
                            reactivate(area)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                areaPendingDeletion = area
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }

                if showInlineDuplicateMessage {
                    Text("An active practice area with this name already exists.")
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }
            } footer: {
                Text("Reactivated areas return to your questionnaire and keep their old ratings.")
            }
        }
        .listStyle(.insetGrouped)
        .background(Color("AppBackground"))
        .scrollContentBackground(.hidden)
        .navigationTitle("Archived Areas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !archivedAreas.isEmpty {
                Button("Delete All", role: .destructive) {
                    showDeleteAllConfirmation = true
                }
            }
        }
        .confirmationDialog(
            "Delete this archived area permanently?",
            isPresented: Binding(
                get: { areaPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        areaPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                guard let area = areaPendingDeletion else { return }
                permanentlyDelete(area)
                areaPendingDeletion = nil
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            if let areaPendingDeletion {
                Text("This removes \(areaPendingDeletion.name) and its saved ratings from old sessions. This cannot be undone.")
            }
        }
        .confirmationDialog(
            "Delete all archived areas permanently?",
            isPresented: $showDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Permanently", role: .destructive) {
                permanentlyDeleteAll()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(archivedAreas.count) archived areas and their saved ratings from old sessions. This cannot be undone.")
        }
        .onAppear {
            viewModel.attachContext(context)
        }
        .onChange(of: viewModel.showDuplicateAlert) { _, newValue in
            guard newValue else { return }
            showDuplicateMessage()
            viewModel.showDuplicateAlert = false
        }
    }
}

private extension ArchivedPracticeAreasView {
    var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No archived areas")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Areas you archive from Practice Areas will appear here.")
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        }
        .padding(.vertical, 6)
    }

    func reactivate(_ area: PracticeAreaEntity) {
        guard viewModel.reactivateArea(
            area,
            currentAreas: areas
        ) else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func permanentlyDelete(_ area: PracticeAreaEntity) {
        viewModel.permanentlyDeleteArchivedArea(area)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func permanentlyDeleteAll() {
        viewModel.permanentlyDeleteArchivedAreas(archivedAreas)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func showDuplicateMessage() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showInlineDuplicateMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showInlineDuplicateMessage = false
            }
        }
    }
}

private struct ArchivedPracticeAreaRow: View {
    let area: PracticeAreaEntity
    let onReactivate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color("SecondaryText").opacity(0.45))
                .frame(width: 4, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(area.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color("PrimaryText"))

                Text("Archived")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer()

            Button(action: onReactivate) {
                Label("Reactivate", systemImage: "arrow.uturn.up")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .tint(Color("AccentColor"))
        }
        .padding(.vertical, 6)
    }
}

#Preview("Archived Practice Areas") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    context.insert(
        PracticeAreaEntity(
            name: "Archived Alap",
            isActive: false,
            order: 0
        )
    )

    return NavigationStack {
        ArchivedPracticeAreasView()
    }
    .modelContainer(container)
}
