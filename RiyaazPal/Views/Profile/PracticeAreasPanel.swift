//
//  PracticeAreasPanel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-05-03.
//

import Foundation
import SwiftData
import SwiftUI

private enum PracticeAreasRoute: Hashable {
    case archivedAreas
}

struct PracticeAreasPanel: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \PracticeAreaEntity.order)
    private var areas: [PracticeAreaEntity]

    @StateObject private var viewModel = PracticeAreasViewModel()

    @State private var newAreaName = ""
    @State private var editingAreaID: UUID?
    @State private var showInlineDuplicateMessage = false
    @State private var showInlineEmptyNameMessage = false

    private var activeAreas: [PracticeAreaEntity] {
        areas
            .filter(\.isActive)
            .sorted { $0.order < $1.order }
    }

    private var archivedAreas: [PracticeAreaEntity] {
        areas.filter { !$0.isActive }
    }

    var body: some View {
        List {
            Section {
                if activeAreas.isEmpty {
                    emptyState
                } else {
                    ForEach(activeAreas) { area in
                        PracticeAreaRow(
                            area: area,
                            isEditing: editingAreaID == area.id,
                            onBeginEditing: {
                                editingAreaID = area.id
                            },
                            onCommit: { newName in
                                commitRename(area, to: newName)
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                viewModel.deactivateArea(area)
                            } label: {
                                Label("Remove", systemImage: "minus.circle")
                            }
                        }
                    }
                    .onMove { source, destination in
                        viewModel.moveAreas(
                            from: source,
                            to: destination,
                            activeAreas: activeAreas
                        )
                    }
                }
            } footer: {
                Text("Deactivated areas stay attached to older session ratings.")
            }

            Section {
                NavigationLink(value: PracticeAreasRoute.archivedAreas) {
                    ArchivedPracticeAreasPanelRow(count: archivedAreas.count)
                }
            }

            Section {
                HStack(spacing: 10) {
                    TextField("Add practice area", text: $newAreaName)
                        .submitLabel(.done)
                        .onSubmit(addArea)

                    Button(action: addArea) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                    .disabled(newAreaName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if showInlineDuplicateMessage {
                    Text("That practice area already exists.")
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }

                if showInlineEmptyNameMessage {
                    Text("Enter a practice area name.")
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color("AppBackground"))
        .scrollContentBackground(.hidden)
        .navigationDestination(for: PracticeAreasRoute.self) { route in
            switch route {
            case .archivedAreas:
                ArchivedPracticeAreasView()
            }
        }
        .navigationTitle("Practice Areas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .onAppear {
            viewModel.attachContext(context)
        }
        .onChange(of: viewModel.showDuplicateAlert) { _, newValue in
            guard newValue else { return }
            showDuplicateMessage()
            viewModel.showDuplicateAlert = false
        }
        .onChange(of: viewModel.showEmptyNameAlert) { _, newValue in
            guard newValue else { return }
            showEmptyNameMessage()
            viewModel.showEmptyNameAlert = false
        }
    }
}

private extension PracticeAreasPanel {

    var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No practice areas yet")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Add the skill areas you want to rate after each session.")
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        }
        .padding(.vertical, 6)
    }

    func addArea() {
        guard let createdArea = viewModel.createArea(
            name: newAreaName,
            currentAreas: areas
        ) else { return }

        newAreaName = ""
        editingAreaID = createdArea.id
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func commitRename(
        _ area: PracticeAreaEntity,
        to newName: String
    ) {
        if viewModel.renameArea(
            area,
            to: newName,
            currentAreas: areas
        ) {
            editingAreaID = nil
        }
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

    func showEmptyNameMessage() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showInlineEmptyNameMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showInlineEmptyNameMessage = false
            }
        }
    }
}

private struct PracticeAreaRow: View {

    let area: PracticeAreaEntity
    let isEditing: Bool
    let onBeginEditing: () -> Void
    let onCommit: (String) -> Void

    @State private var draft: String
    @FocusState private var isFocused

    init(
        area: PracticeAreaEntity,
        isEditing: Bool,
        onBeginEditing: @escaping () -> Void,
        onCommit: @escaping (String) -> Void
    ) {
        self.area = area
        self.isEditing = isEditing
        self.onBeginEditing = onBeginEditing
        self.onCommit = onCommit
        _draft = State(initialValue: area.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color("AccentColor").opacity(0.6))
                .frame(width: 4, height: 28)

            if isEditing {
                TextField("Practice area", text: $draft)
                    .font(.body.weight(.medium))
                    .submitLabel(.done)
                    .onSubmit { commit() }
                    .focused($isFocused)
            } else {
                Text(area.name)
                    .font(.body.weight(.medium))
                    .onTapGesture {
                        onBeginEditing()
                    }
            }

            Spacer()
        }
        .onChange(of: isEditing) { _, isItemEditing in
            if isItemEditing {
                draft = area.name
                isFocused = true
            }
        }
        .onChange(of: isFocused) { _, isItemFocused in
            if !isItemFocused && isEditing {
                commit()
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            draft = area.name
            return
        }

        onCommit(trimmed)
    }
}

private struct ArchivedPracticeAreasPanelRow: View {
    let count: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Archived Practice Areas")
                    .font(.body)
                    .fontWeight(.medium)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer()

            Image(systemName: "archivebox")
                .foregroundStyle(Color("AccentColor"))
        }
        .padding(.vertical, 4)
    }

    private var statusText: String {
        guard count > 0 else { return "None archived" }
        let noun = count == 1 ? "area" : "areas"
        return "\(count) \(noun)"
    }
}

#Preview("Practice Areas") {
    let container = PreviewModelContainer.make()
    let context = container.mainContext

    let areas = [
        PracticeAreaEntity(name: "Sapat Taans", order: 0),
        PracticeAreaEntity(name: "Bol Taans", order: 1),
        PracticeAreaEntity(name: "Layakari", order: 2)
    ]

    for area in areas {
        context.insert(area)
    }

    return NavigationStack {
        PracticeAreasPanel()
    }
    .modelContainer(container)
}
