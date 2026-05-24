//
//  GlowBackground.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import SwiftUI

struct GlowBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .blue.opacity(0.2),
                    .purple.opacity(0.2),
                    .pink.opacity(0.15)
                ],
                startPoint: animate ? .topLeading : .bottomLeading,
                endPoint: animate ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .blur(radius: 50)
            .animation(
                .easeInOut(duration: 6).repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear {
                animate = true
            }
        }
    }
}