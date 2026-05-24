//
//  FloatingCard.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import SwiftUI

struct FloatingCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: AppTheme.onSurface.opacity(0.05), radius: 10, y: 4)
    }
}
