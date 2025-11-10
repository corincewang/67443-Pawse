//
//  FloatingWindowView.swift
//  Pawse
//
//  Reusable floating window components
//

import SwiftUI

// Base floating window view
struct FloatingWindowView<Content: View>: View {
    let isPresented: Bool
    let onDismiss: () -> Void
    let content: Content
    
    init(isPresented: Bool, onDismiss: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        self.content = content()
    }
    
    var body: some View {
        if isPresented {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onDismiss()
                    }
                
                // Floating window content
                content
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// Confirmation dialog component (matches PetFormView share dialog style)
struct ConfirmationFloatingWindow: View {
    let isPresented: Bool
    let title: String
    let confirmText: String
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    
    var body: some View {
        FloatingWindowView(isPresented: isPresented, onDismiss: cancelAction) {
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.pawseOliveGreen)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                    .padding(.horizontal, 10)
                
                HStack(spacing: 15) {
                    // Confirm button - matches PetFormView "invite" button
                    Button(action: confirmAction) {
                        Text(confirmText)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.pawseOrange)
                            .cornerRadius(25)
                    }
                    
                    // Cancel button - matches PetFormView "cancel" button
                    Button(action: cancelAction) {
                        Text("cancel")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "DFA894"))
                            .cornerRadius(25)
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }
}

// Input dialog component (matches PetFormView invite dialog style)
struct InputFloatingWindow: View {
    let isPresented: Bool
    let title: String
    let placeholder: String
    @Binding var inputText: String
    let confirmText: String
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    let isLoading: Bool
    
    var body: some View {
        FloatingWindowView(isPresented: isPresented, onDismiss: cancelAction) {
            VStack(spacing: 20) {
                TextField(placeholder, text: $inputText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(height: 52)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "9B7EDE"), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    )
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                HStack(spacing: 15) {
                    // Confirm button - matches PetFormView "invite" button
                    Button(action: confirmAction) {
                        Text(confirmText)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.pawseOrange)
                            .cornerRadius(25)
                    }
                    .disabled(inputText.isEmpty || isLoading)
                    
                    // Cancel button - matches PetFormView "cancel" button
                    Button(action: cancelAction) {
                        Text("cancel")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "DFA894"))
                            .cornerRadius(25)
                    }
                }
            }
        }
    }
}