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
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "Login")

    var onLogin: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Text("PhotoMap")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)

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
                .background(!email.isEmpty && !password.isEmpty ? Color.blue : Color.gray)
                .cornerRadius(10)
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .padding(.horizontal, 40)
                .padding(.top, 20)

                Button(action: {
                    isSignUp.toggle()
                    errorMessage = nil
                }) {
                    Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

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

    private func authenticate() async {
        isLoading = true
        errorMessage = nil

        do {
            if isSignUp {
                logger.info("Attempting sign up with email: \(email)")
                try await supabase.auth.signUp(email: email, password: password)
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
