//
//  SuccessToastBar.swift
//  Pawse
//
//  Reusable success toast bar component
//

import SwiftUI

struct SuccessToastBar: View {
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        if isPresented {
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    // Green circle with checkmark
                    ZStack {
                        Circle()
                            .fill(Color.pawseOliveGreen)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
                .offset(y: isPresented ? 0 : 100)
                .opacity(isPresented ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isPresented)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        SuccessToastBar(message: "share success", isPresented: .constant(true))
    }
}

