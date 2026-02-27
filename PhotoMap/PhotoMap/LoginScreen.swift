//
//  LoginScreen.swift
//  PhotoMap
//
//  Created by Sam Grobelny on 2/27/26.
//
import OSLog
import SwiftUI
struct LoginScreen: View {
    
    @State private var username: String = ""
    @State private var password: String = ""
    
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
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                
                Button(action: {
                    if !username.isEmpty && !password.isEmpty {
                        logger.info("Login button tapped with username: \(username)")
                        onLogin()
                    }
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!username.isEmpty && !password.isEmpty ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(username.isEmpty || password.isEmpty)
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
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
}

