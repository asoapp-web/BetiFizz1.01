//
//  NotesTabView.swift
//  BetiFizz
//

import SwiftUI

// MARK: - Notes list

struct NotesTabView: View {
    @State private var notes: [BetiFizzNote] = []
    @State private var selectedNoteId: String?
    @State private var showNewEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()

                Group {
                    if notes.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(notes) { note in
                                    Button { selectedNoteId = note.id } label: {
                                        NoteRowCard(note: note)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Notes")
            .betiFizzNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNewEditor = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(BetiFizzTheme.primaryGreen)
                    }
                }
            }
            .sheet(isPresented: $showNewEditor) {
                NoteEditorSheet(noteId: nil) { notes = BetiFizzNotesStore.shared.notes }
            }
            .sheet(item: $selectedNoteId) { id in
                NoteEditorSheet(noteId: id) {
                    notes = BetiFizzNotesStore.shared.notes
                    selectedNoteId = nil
                }
            }
        }
        .onAppear { notes = BetiFizzNotesStore.shared.notes }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            LiquidGlassCard {
                VStack(spacing: 14) {
                    Image(systemName: "note.text")
                        .font(.system(size: 38))
                        .foregroundStyle(BetiFizzTheme.primaryGreen.opacity(0.85))
                    Text("No notes yet")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(BetiFizzTheme.textPrimary)
                    Text("Tap + to create a note. Attach photos, link matches and teams.")
                        .font(.subheadline)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button { showNewEditor = true } label: { Text("New Note") }
                        .buttonStyle(LiquidGlassPrimaryButtonStyle())
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            Spacer()
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Note row card

private struct NoteRowCard: View {
    let note: BetiFizzNote

    var body: some View {
        LiquidGlassCard(cornerRadius: 18, highlightOpacity: 0.3) {
            HStack(alignment: .top, spacing: 14) {
                thumbnail
                VStack(alignment: .leading, spacing: 5) {
                    Text(note.titlePreview)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BetiFizzTheme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(note.updatedAt.betiFizzFormattedMatchLine())
                        .font(.caption)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                    if note.linkedMatchSummary != nil || note.linkedTeamName != nil {
                        HStack(spacing: 6) {
                            if let s = note.linkedMatchSummary {
                                Label(s, systemImage: "sportscourt")
                                    .lineLimit(1)
                            }
                            if let n = note.linkedTeamName {
                                Label(n, systemImage: "shield")
                                    .lineLimit(1)
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                    }
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BetiFizzTheme.textSecondary.opacity(0.5))
            }
        }
    }

    private var thumbnail: some View {
        Group {
            if let data = note.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(BetiFizzTheme.primaryGreen.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: "note.text")
                        .font(.title3)
                        .foregroundStyle(BetiFizzTheme.primaryGreen)
                }
            }
        }
    }
}

// MARK: - Note editor sheet

struct NoteEditorSheet: View {
    let noteId: String?
    let onDismiss: () -> Void

    @State private var note: BetiFizzNote
    @State private var showPhotoSource = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showMatchPicker = false
    @State private var showTeamPicker = false
    @FocusState private var textFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(noteId: String?, onDismiss: @escaping () -> Void) {
        self.noteId = noteId
        self.onDismiss = onDismiss
        let n: BetiFizzNote
        if let id = noteId, let existing = BetiFizzNotesStore.shared.note(byId: id) {
            n = existing
        } else {
            n = BetiFizzNote()
        }
        _note = State(initialValue: n)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        textSection
                        photoSection
                        linksSection
                        actionRow
                    }
                    .padding(20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(noteId == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .betiFizzNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            BetiFizzImagePicker(sourceType: imagePickerSource) { img in
                note.imageData = img.jpegData(compressionQuality: 0.8)
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showPhotoSource) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    BetiFizzPhotoPermission.requestCamera { ok in
                        if ok { imagePickerSource = .camera; showImagePicker = true }
                    }
                }
            }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                Button("Photo Library") {
                    BetiFizzPhotoPermission.requestPhotoLibrary { ok in
                        if ok { imagePickerSource = .photoLibrary; showImagePicker = true }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Choose source") }
        .sheet(isPresented: $showMatchPicker) {
            NoteMatchPickerView { match in
                note.linkedMatchId = match.id
                note.linkedMatchSummary = "\(match.homeTeamName) vs \(match.awayTeamName)"
                showMatchPicker = false
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTeamPicker) {
            NoteTeamPickerView { name, id in
                note.linkedTeamId = id
                note.linkedTeamName = name
                showTeamPicker = false
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: Sections

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Text")
            TextEditor(text: $note.text)
                .font(.body)
                .foregroundStyle(BetiFizzTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 130)
                .padding(14)
                .background(.ultraThinMaterial.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
                .focused($textFocused)
                .onAppear { textFocused = noteId == nil }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Photo")
            if let data = note.imageData, let img = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button { note.imageData = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                    }
                    .offset(x: 8, y: -8)
                }
            } else {
                Button { showPhotoSource = true } label: {
                    Label("Add Photo", systemImage: "photo.badge.plus")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BetiFizzTheme.primaryGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(BetiFizzTheme.primaryGreen.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Links")
            HStack(spacing: 10) {
                if let s = note.linkedMatchSummary {
                    noteChip(s, icon: "sportscourt.fill") {
                        note.linkedMatchId = nil; note.linkedMatchSummary = nil
                    }
                } else {
                    Button { showMatchPicker = true } label: {
                        Label("Match", systemImage: "sportscourt")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(BetiFizzTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                if let n = note.linkedTeamName {
                    noteChip(n, icon: "shield.fill") {
                        note.linkedTeamId = nil; note.linkedTeamName = nil
                    }
                } else {
                    Button { showTeamPicker = true } label: {
                        Label("Team", systemImage: "shield")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(BetiFizzTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var canSave: Bool {
        !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button { save(); dismiss(); onDismiss() } label: { Text("Save") }
                .buttonStyle(LiquidGlassPrimaryButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.42)
            if noteId != nil {
                Button(role: .destructive) {
                    BetiFizzNotesStore.shared.delete(noteId: note.id)
                    dismiss(); onDismiss()
                } label: {
                    Text("Delete")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(red: 1, green: 0.27, blue: 0.27))
                }
                .buttonStyle(.plain)
                .frame(width: 70)
            }
        }
    }

    // MARK: Helpers

    private func save() {
        if noteId == nil { BetiFizzNotesStore.shared.add(note) }
        else { BetiFizzNotesStore.shared.update(note) }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(BetiFizzTheme.textSecondary)
            .tracking(0.8)
    }

    private func noteChip(_ title: String, icon: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption2)
            Text(title).font(.caption).lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill").font(.caption)
            }
        }
        .foregroundStyle(BetiFizzTheme.textPrimary)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(Capsule())
        .overlay { Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1) }
    }
}

// MARK: - Match picker for notes

private struct NoteMatchPickerView: View {
    @StateObject private var vm = MatchesListViewModel.shared
    @State private var search = ""
    let onSelect: (BetiFizzMatch) -> Void

    private var displayed: [BetiFizzMatch] {
        let base = vm.matches
        guard !search.isEmpty else { return base }
        let q = search.lowercased()
        return base.filter {
            $0.homeTeamName.localizedCaseInsensitiveContains(q) ||
            $0.awayTeamName.localizedCaseInsensitiveContains(q) ||
            $0.leagueName.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()
                Group {
                    if vm.isLoading && vm.matches.isEmpty {
                        ProgressView().tint(BetiFizzTheme.primaryGreen).frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if displayed.isEmpty {
                        Text("No matches loaded. Open the Matches tab first.")
                            .foregroundStyle(BetiFizzTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        List {
                            ForEach(displayed) { m in
                                Button { onSelect(m) } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("\(m.homeTeamName) vs \(m.awayTeamName)")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(BetiFizzTheme.textPrimary)
                                        Text("\(m.leagueName) · \(m.date.betiFizzFormattedMatchLine())")
                                            .font(.caption)
                                            .foregroundStyle(BetiFizzTheme.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .searchable(text: $search, prompt: "Team or league")
                    }
                }
            }
            .navigationTitle("Link Match")
            .navigationBarTitleDisplayMode(.inline)
            .betiFizzNavigationChrome()
        }
        .task { await vm.loadMatches() }
    }
}

// MARK: - Team picker for notes

private struct NoteTeamPickerView: View {
    @StateObject private var vm = TeamsListViewModel.shared
    let onSelect: (String, String) -> Void // (name, id)

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()
                Group {
                    if vm.isLoading && vm.teams.isEmpty {
                        ProgressView().tint(BetiFizzTheme.primaryGreen).frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vm.teams.isEmpty {
                        Text("No teams loaded. Open the Matches tab first.")
                            .foregroundStyle(BetiFizzTheme.textSecondary)
                            .padding()
                    } else {
                        List {
                            ForEach(vm.teams) { team in
                                Button { onSelect(team.name, team.id) } label: {
                                    Text(team.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(BetiFizzTheme.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .searchable(text: $vm.searchText, prompt: "Search teams")
                    }
                }
            }
            .navigationTitle("Link Team")
            .navigationBarTitleDisplayMode(.inline)
            .betiFizzNavigationChrome()
        }
        .task { await vm.loadTeams() }
    }
}
