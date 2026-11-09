//
//  OnboardingGate.swift
//  Ripple
//
//  Task 2 — Duty 2.2 ("Show onboarding only on first launch")
//
//  HOW TO HOOK IT UP (one line, in RippleApp.swift):
//
//      ContentView()
//          .rippleOnboarding()
//
//  Onboarding then appears over the app until the user finishes it, and
//  never again after that (UserPreferences.hasCompletedOnboarding).
//

import Foundation
import SwiftUI
import SwiftData

/// Launch arguments used only by Task 2's UI tests.
enum Task2LaunchArguments {
    /// Shows onboarding again even if it was already completed.
    static let resetOnboarding = "-RippleResetOnboarding"
    /// Skips onboarding, turns the journal lock off and opens the journal.
    static let openJournal = "-RippleUITestOpenJournal"

    static func isSet(_ argument: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
    }
}

struct OnboardingGate: ViewModifier {

    @Environment(\.modelContext) private var context
    @Query private var preferences: [UserPreferences]

    @State private var didPrepare = false
    @State private var showJournalForUITest = false

    private var needsOnboarding: Bool {
        didPrepare && preferences.first?.hasCompletedOnboarding != true
    }

    func body(content: Content) -> some View {
        content
            .fullScreenCover(
                isPresented: Binding(
                    get: { needsOnboarding },
                    // Closes by itself once hasCompletedOnboarding is saved.
                    set: { _ in }
                )
            ) {
                OnboardingView()
                    .modelContext(context)
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showJournalForUITest) {
                JournalView()
                    .modelContext(context)
            }
            .onAppear(perform: prepare)
    }

    private func prepare() {
        guard !didPrepare else { return }

        if Task2LaunchArguments.isSet(Task2LaunchArguments.resetOnboarding),
           let prefs = try? UserPreferencesStore.current(in: context) {
            prefs.hasCompletedOnboarding = false
            try? context.save()
        }

        if Task2LaunchArguments.isSet(Task2LaunchArguments.openJournal),
           let prefs = try? UserPreferencesStore.current(in: context) {
            prefs.hasCompletedOnboarding = true
            prefs.journalLockEnabled = false
            try? context.save()
            showJournalForUITest = true
        }

        didPrepare = true
    }
}

extension View {
    /// Shows Ripple's onboarding on first launch.
    func rippleOnboarding() -> some View {
        modifier(OnboardingGate())
    }
}
