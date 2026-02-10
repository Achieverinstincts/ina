import Foundation
import LocalAuthentication
import Dependencies

// MARK: - Biometric Client
// TCA Dependency for Face ID / Touch ID authentication

struct BiometricClient {
    /// Returns the biometric type available on the device
    var biometricType: @Sendable () -> BiometricType
    
    /// Check if biometric authentication is available
    var isAvailable: @Sendable () -> Bool
    
    /// Authenticate using biometrics with a reason string, returns success
    var authenticate: @Sendable (String) async throws -> Bool
    
    /// Check if biometric policy can be evaluated
    var canEvaluatePolicy: @Sendable () -> Bool
}

// MARK: - Biometric Type

enum BiometricType: Equatable, Sendable {
    case faceID
    case touchID
    case none
    
    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "None"
        }
    }
}

// MARK: - Biometric Errors

enum BiometricError: Error, LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case systemCancelled
    case passcodeNotSet
    case biometryLockout
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
        case .authenticationFailed:
            return "Biometric authentication failed. Please try again."
        case .userCancelled:
            return "Authentication was cancelled."
        case .systemCancelled:
            return "Authentication was cancelled by the system."
        case .passcodeNotSet:
            return "A device passcode is required to use biometric authentication."
        case .biometryLockout:
            return "Biometric authentication is locked. Please use your passcode to unlock."
        case .unknown(let message):
            return "Authentication error: \(message)"
        }
    }
    
    init(from laError: LAError) {
        switch laError.code {
        case .biometryNotAvailable:
            self = .notAvailable
        case .biometryNotEnrolled:
            self = .notEnrolled
        case .authenticationFailed:
            self = .authenticationFailed
        case .userCancel:
            self = .userCancelled
        case .systemCancel:
            self = .systemCancelled
        case .passcodeNotSet:
            self = .passcodeNotSet
        case .biometryLockout:
            self = .biometryLockout
        default:
            self = .unknown(laError.localizedDescription)
        }
    }
}

// MARK: - Dependency Key

extension BiometricClient: DependencyKey {
    static let liveValue = BiometricClient.live
    static let testValue = BiometricClient.mock
    static let previewValue = BiometricClient.mock
}

extension DependencyValues {
    var biometricClient: BiometricClient {
        get { self[BiometricClient.self] }
        set { self[BiometricClient.self] = newValue }
    }
}

// MARK: - Live Implementation

extension BiometricClient {
    static let live = BiometricClient(
        biometricType: {
            let context = LAContext()
            var error: NSError?
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                return .none
            }
            
            switch context.biometryType {
            case .faceID:
                return .faceID
            case .touchID:
                return .touchID
            case .opticID:
                return .none
            case .none:
                return .none
            @unknown default:
                return .none
            }
        },
        
        isAvailable: {
            let context = LAContext()
            var error: NSError?
            return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        },
        
        authenticate: { reason in
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                if let laError = error as? LAError {
                    throw BiometricError(from: laError)
                }
                throw BiometricError.notAvailable
            }
            
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
                return success
            } catch let error as LAError {
                throw BiometricError(from: error)
            } catch {
                throw BiometricError.unknown(error.localizedDescription)
            }
        },
        
        canEvaluatePolicy: {
            let context = LAContext()
            var error: NSError?
            return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        }
    )
}

// MARK: - Mock Implementation

extension BiometricClient {
    static let mock = BiometricClient(
        biometricType: {
            return .faceID
        },
        isAvailable: {
            return true
        },
        authenticate: { _ in
            return true
        },
        canEvaluatePolicy: {
            return true
        }
    )
}
