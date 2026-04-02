//
//  ProfileView.swift
//  BetiFizz
//

import CoreData
import SwiftUI

private let kNickname   = "BetiFizz.profile.nickname"
private let kAvatarMode = "BetiFizz.profile.avatarMode"   // "symbol" | "photo"
private let kAvatarSym  = "BetiFizz.profile.avatarSymbol"
private let kAvatarData = "BetiFizz.profile.avatarData"

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var stats = QuizStatsSnapshot(attempted: 0, correct: 0, bestStreak: 0, currentStreak: 0, lastPlayedAt: nil)

    // Profile identity
    @State private var nickname: String     = UserDefaults.standard.string(forKey: kNickname) ?? "Player"
    @State private var avatarMode: String   = UserDefaults.standard.string(forKey: kAvatarMode) ?? "symbol"
    @State private var avatarSymbol: String = UserDefaults.standard.string(forKey: kAvatarSym)  ?? "person.crop.circle.fill"
    @State private var avatarData: Data?    = UserDefaults.standard.data(forKey: kAvatarData)

    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        heroCard
                        quizCard
                        settingsLink
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Profile")
            .betiFizzNavigationChrome()
        }
        .onAppear {
            QuizStatsRepository.bootstrapIfNeeded(context: viewContext)
            reloadStats()
            reloadIdentity()
        }
        .onReceive(NotificationCenter.default.publisher(for: .betiFizzQuizStatsDidChange)) { _ in
            reloadStats()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(
                nickname: nickname,
                avatarMode: avatarMode,
                avatarSymbol: avatarSymbol,
                avatarData: avatarData
            ) { nick, mode, sym, data in
                nickname = nick; avatarMode = mode; avatarSymbol = sym; avatarData = data
                UserDefaults.standard.set(nick,  forKey: kNickname)
                UserDefaults.standard.set(mode,  forKey: kAvatarMode)
                UserDefaults.standard.set(sym,   forKey: kAvatarSym)
                if let d = data { UserDefaults.standard.set(d, forKey: kAvatarData) }
                else { UserDefaults.standard.removeObject(forKey: kAvatarData) }
            }
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        LiquidGlassCard(cornerRadius: 26, highlightOpacity: 0.32) {
            HStack(spacing: 16) {
                avatarView
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(BetiFizzTheme.primaryGreen.opacity(0.5), lineWidth: 2))

                VStack(alignment: .leading, spacing: 6) {
                    Text(nickname.isEmpty ? "Player" : nickname)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(BetiFizzTheme.textPrimary)
                    Text("Matches · Interactive · Notes")
                        .font(.subheadline)
                        .foregroundStyle(BetiFizzTheme.textSecondary)
                }
                Spacer(minLength: 0)
                Button { showEditProfile = true } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(BetiFizzTheme.primaryGreen)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if avatarMode == "photo", let data = avatarData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle().fill(BetiFizzTheme.primaryGreen.opacity(0.2))
                Image(systemName: avatarSymbol)
                    .font(.system(size: 34))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BetiFizzTheme.primaryGreen, BetiFizzTheme.darkGreen],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }

    // MARK: - Quiz stats card

    private var quizCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Quiz performance", systemImage: "sparkles")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BetiFizzTheme.textPrimary)
                statRow("Answered",  "\(stats.attempted)")
                statRow("Correct",   "\(stats.correct)")
                statRow("Accuracy",  stats.accuracyText)
                statRow("Best streak", "\(stats.bestStreak)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Settings link

    private var settingsLink: some View {
        NavigationLink {
            SettingsView()
        } label: {
            HStack {
                Image(systemName: "gearshape.fill")
                Text("Settings").fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BetiFizzTheme.textSecondary)
            }
            .foregroundStyle(BetiFizzTheme.textPrimary)
            .padding(.vertical, 16).padding(.horizontal, 18)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial).opacity(0.55)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.1), BetiFizzTheme.primaryGreen.opacity(0.12)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.22), BetiFizzTheme.primaryGreen.opacity(0.3)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.1)
            }
            .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(BetiFizzTheme.textSecondary)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(BetiFizzTheme.textPrimary)
        }
        .font(.subheadline)
    }

    private func reloadStats()    { stats = QuizStatsRepository.snapshot(context: viewContext) }
    private func reloadIdentity() {
        nickname     = UserDefaults.standard.string(forKey: kNickname)   ?? "Player"
        avatarMode   = UserDefaults.standard.string(forKey: kAvatarMode) ?? "symbol"
        avatarSymbol = UserDefaults.standard.string(forKey: kAvatarSym)  ?? "person.crop.circle.fill"
        avatarData   = UserDefaults.standard.data(forKey: kAvatarData)
    }
}

// MARK: - Edit profile sheet

private struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draftNick: String
    @State private var draftMode: String
    @State private var draftSymbol: String
    @State private var draftData: Data?
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showPhotoSource = false
    @State private var showSymbolPicker = false

    let onSave: (String, String, String, Data?) -> Void

    init(nickname: String, avatarMode: String, avatarSymbol: String, avatarData: Data?,
         onSave: @escaping (String, String, String, Data?) -> Void) {
        _draftNick   = State(initialValue: nickname)
        _draftMode   = State(initialValue: avatarMode)
        _draftSymbol = State(initialValue: avatarSymbol)
        _draftData   = State(initialValue: avatarData)
        self.onSave  = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        avatarPreview
                        nicknameField
                        avatarOptions
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .betiFizzNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(BetiFizzTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draftNick.trimmingCharacters(in: .whitespaces).isEmpty ? "Player" : draftNick,
                               draftMode, draftSymbol, draftData)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(BetiFizzTheme.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            BetiFizzImagePicker(sourceType: imagePickerSource) { img in
                draftData = img.jpegData(compressionQuality: 0.8)
                draftMode = "photo"
            }
        }
        .confirmationDialog("Choose Photo Source", isPresented: $showPhotoSource) {
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
        }
        .sheet(isPresented: $showSymbolPicker) {
            SFSymbolPickerSheet(selected: draftSymbol) { sym in
                draftSymbol = sym; draftMode = "symbol"; draftData = nil
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var avatarPreview: some View {
        ZStack {
            if draftMode == "photo", let data = draftData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 96, height: 96).clipShape(Circle())
            } else {
                ZStack {
                    Circle().fill(BetiFizzTheme.primaryGreen.opacity(0.2)).frame(width: 96, height: 96)
                    Image(systemName: draftSymbol).font(.system(size: 46))
                        .foregroundStyle(LinearGradient(
                            colors: [BetiFizzTheme.primaryGreen, BetiFizzTheme.darkGreen],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
        }
        .overlay(Circle().stroke(BetiFizzTheme.primaryGreen.opacity(0.5), lineWidth: 2))
        .shadow(color: BetiFizzTheme.primaryGreen.opacity(0.25), radius: 12, y: 6)
    }

    private var nicknameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NICKNAME").font(.caption.weight(.bold))
                .foregroundStyle(BetiFizzTheme.textSecondary).tracking(0.8)
            TextField("Enter nickname", text: $draftNick)
                .font(.body)
                .foregroundStyle(BetiFizzTheme.textPrimary)
                .tint(BetiFizzTheme.primaryGreen)
                .padding(14)
                .background(.ultraThinMaterial.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
    }

    private var avatarOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AVATAR").font(.caption.weight(.bold))
                .foregroundStyle(BetiFizzTheme.textSecondary).tracking(0.8)
            HStack(spacing: 12) {
                Button { showSymbolPicker = true } label: {
                    Label("SF Icon", systemImage: "person.crop.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(draftMode == "symbol" ? Color.white : BetiFizzTheme.textSecondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(draftMode == "symbol"
                                    ? BetiFizzTheme.primaryGreen.opacity(0.7)
                                    : Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Button { showPhotoSource = true } label: {
                    Label("Photo", systemImage: "photo.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(draftMode == "photo" ? Color.white : BetiFizzTheme.textSecondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(draftMode == "photo"
                                    ? BetiFizzTheme.primaryGreen.opacity(0.7)
                                    : Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - SF Symbol picker sheet

private struct SFSymbolPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let selected: String
    let onSelect: (String) -> Void

    private let symbols: [String] = [
        "person.crop.circle.fill", "person.fill", "figure.stand",
        "soccerball", "soccerball.inverse",
        "sportscourt.fill", "trophy.fill", "medal.fill",
        "star.fill", "bolt.fill", "flame.fill",
        "crown.fill", "shield.fill", "shield.lefthalf.filled",
        "figure.run", "figure.soccer",
        "flag.fill", "flag.checkered", "flag.2.crossed.fill",
        "ticket.fill", "mic.fill", "binoculars.fill",
        "number.circle.fill", "checkmark.seal.fill", "rosette",
    ]

    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 5)

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassScreenBackground()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(symbols, id: \.self) { sym in
                            Button {
                                onSelect(sym)
                                dismiss()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(selected == sym
                                              ? BetiFizzTheme.primaryGreen.opacity(0.3)
                                              : Color.white.opacity(0.06))
                                    Image(systemName: sym)
                                        .font(.title2)
                                        .foregroundStyle(selected == sym
                                                         ? BetiFizzTheme.primaryGreen
                                                         : BetiFizzTheme.textSecondary)
                                }
                                .frame(height: 60)
                                .overlay {
                                    if selected == sym {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(BetiFizzTheme.primaryGreen.opacity(0.6), lineWidth: 1.5)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .betiFizzNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(BetiFizzTheme.textSecondary)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
