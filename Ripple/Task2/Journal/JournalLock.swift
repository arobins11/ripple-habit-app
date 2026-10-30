//
//  JournalLock.swift
//  Ripple
//
//  Task 2 — Duty 2.5
//  Optional journal privacy lock using Face ID, Touch ID or the device
//  passcode (Apple's LocalAuthentication framework).
//
//  REQUIRED PROJECT SETTING (Face ID apps crash without it):
//  Ripple target → Info tab → add the key
//  "Privacy - Face ID Usage Description" with a value such as
//  "Ripple uses Face ID to keep your journal private."
//

import Foundation
import SwiftUI
import LocalAuthentication

enum JournalLockService {

    /// Whether this device can authenticate at all (biometrics or passcode).
    static func isAvailable() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// "Face ID", "Touch ID", "Optic ID" or "Passcode" for button labels.
    static var methodName: String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Passcode"
        }
    }

    /// Asks the user to authenticate. Falls back to the device passcode
    /// if biometrics fail or aren't set up.
    static func authenticate(reason: String) async -> Result<Void, JournalLockError> {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var availabilityError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &availabilityError) else {
            return .failure(.unavailable)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success ? .success(()) : .failure(.failed)
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                return .failure(.cancelled)
            default:
                return .failure(.failed)
            }
        } catch {
            return .failure(.failed)
        }
    }
}

enum JournalLockError: Error, Equatable {
    case unavailable
    case cancelled
    case failed

    var message: String {
        switch self {
        case .unavailable:
            "This device has no Face ID, Touch ID or passcode set up, so the journal can't be locked."
        case .cancelled:
            "Unlock was cancelled."
        case .failed:
            "We couldn't verify it's you. Please try again."
        }
    }
}

/// Shown instead of journal content while the journal is locked.
struct JournalLockScreen: View {

    let onUnlock: () -> Void

    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("Journal Locked")
                .font(.title2.bold())
                .accessibilityIdentifier("journal.lockedTitle")

            Text("Your entries are hidden until you unlock.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await unlock() }
            } label: {
                Label("Unlock with \(JournalLockService.methodName)", systemImage: "faceid")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isAuthenticating)
            .accessibilityIdentifier("journal.unlockButton")

            Spacer()
        }
        .padding(24)
        .task { await unlock() }
    }

    private func unlock() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        switch await JournalLockService.authenticate(reason: "Unlock your Ripple journal") {
        case .success:
            errorMessage = nil
            onUnlock()
        case .failure(let error):
            errorMessage = error.message
        }
    }
}
