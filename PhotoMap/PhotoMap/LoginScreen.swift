//
//  LoginScreen.swift
//  PhotoMap
//
//  Created by Sam Grobelny on 2/27/26.
//
import OSLog
import SwiftUI
internal import Auth
import Supabase

struct LoginScreen: View {

    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    @State private var isCheckingUsername: Bool = false
    @State private var isUsernameTaken: Bool = false
    @State private var usernameCheckTask: Task<Void, Never>?
    @State private var errorMessage: String?

    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "Login")

    var onLogin: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                Text("PhotoMap")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .accessibilityIdentifier("emailField")
                        .accessibilityLabel("Email address")
                        .accessibilityHint("Enter your email address")

                    if isSignUp && !email.isEmpty && !isEmailValid {
                        Text("Please enter a valid email address")
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if isSignUp {
                        HStack {
                            TextField("Username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .onChange(of: username) {
                                    checkUsernameAvailability()
                                }
                                .accessibilityIdentifier("usernameField")
                                .accessibilityLabel("Username")
                                .accessibilityHint("Choose a unique username")
                            if isCheckingUsername {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .accessibilityLabel("Checking username availability")
                            } else if !username.isEmpty {
                                Image(systemName: isUsernameTaken ? "xmark.circle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(isUsernameTaken ? .red : .green)
                                    .accessibilityLabel(isUsernameTaken ? "Username is taken" : "Username is available")
                            }
                        }
                        if isUsernameTaken {
                            Text("Username is already taken")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .accessibilityIdentifier("passwordField")
                        .accessibilityLabel("Password")
                        .accessibilityHint(isSignUp ? "Create a password with at least 8 characters" : "Enter your password")
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)

                if isSignUp && !password.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(passwordValidationErrors, id: \.self) { error in
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption2)
                                    .accessibilityHidden(true)
                                Text(error)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Missing requirement: \(error)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Password requirements")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 40)
                }

                Button(action: {
                    Task {
                        await authenticate()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text(isSignUp ? "Sign Up" : "Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(formIsComplete ? Color.blue : Color.gray)
                .cornerRadius(10)
                .disabled(!formIsComplete || isLoading)
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .accessibilityIdentifier("authButton")

                Button(action: {
                    isSignUp.toggle()
                    errorMessage = nil
                    username = ""
                    isUsernameTaken = false
                    isCheckingUsername = false
                    usernameCheckTask?.cancel()
                }) {
                    Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .accessibilityIdentifier("toggleModeButton")

                Spacer()
            }
            .onAppear {
                logger.info("LoginScreen appeared")
            }
            .onDisappear {
                logger.info("LoginScreen disappeared")
            }
        }
    }

    private var passwordValidationErrors: [String] {
        var errors: [String] = []
        if password.count < 8 { errors.append("At least 8 characters") }
        if !password.contains(where: \.isLowercase) { errors.append("A lowercase letter") }
        if !password.contains(where: \.isUppercase) { errors.append("An uppercase letter") }
        if !password.contains(where: \.isNumber) { errors.append("A digit") }
        if !password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?`~".contains($0) }) { errors.append("A symbol") }
        return errors
    }

    private var isPasswordValid: Bool {
        passwordValidationErrors.isEmpty
    }

    private var isEmailValid: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private var formIsComplete: Bool {
        !email.isEmpty && !password.isEmpty && (!isSignUp || (isEmailValid && !username.isEmpty && !isUsernameTaken && !isCheckingUsername))
    }

    private func checkUsernameAvailability() {
        usernameCheckTask?.cancel()
        let trimmed = username.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            isUsernameTaken = false
            isCheckingUsername = false
            return
        }

        isCheckingUsername = true
        usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }

            do {
                let results: [UserProfile] = try await supabase
                    .from("profiles")
                    .select()
                    .eq("username", value: trimmed)
                    .execute()
                    .value
                guard !Task.isCancelled else { return }
                isUsernameTaken = !results.isEmpty
            } catch {
                guard !Task.isCancelled else { return }
                logger.error("Username check failed: \(error.localizedDescription)")
                isUsernameTaken = false
            }
            isCheckingUsername = false
        }
    }

    private func authenticate() async {
        isLoading = true
        errorMessage = nil

        if isSignUp && !isPasswordValid {
            errorMessage = "Password must contain: " + passwordValidationErrors.joined(separator: ", ")
            isLoading = false
            return
        }

        if isSignUp && username.isEmpty {
            errorMessage = "Username is required"
            isLoading = false
            return
        }

        do {
            if isSignUp {
                logger.info("Attempting sign up with email: \(email)")
                let authResponse = try await supabase.auth.signUp(
                    email: email,
                    password: password
                )
                let profile = UserProfile(
                    id: authResponse.user.id,
                    username: username,
                    createdAt: nil
                )
                try await supabase.from("profiles").insert(profile).execute()
                logger.info("Profile created for user: \(username)")
            } else {
                logger.info("Attempting login with email: \(email)")
                try await supabase.auth.signIn(email: email, password: password)
            }
            logger.info("Authentication successful")
            onLogin()
        } catch {
            logger.error("Authentication failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    LoginScreen(onLogin: {})
}
