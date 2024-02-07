//
//  LoadingView.swift
//  Rede Duque
//
//  Created by Duane de Moura Silva on 18/12/23.
//

import SwiftUI

struct LoadingView: View {
    @State var text : String
    var body: some View {
        Rectangle()
            .foregroundStyle(.ultraThinMaterial)
            .overlay {
                VStack{
                        ProgressView()
                            .scaleEffect(3)
                            .padding()
                        Text(text)
                            .font(.headline)
                            .padding()
                            .multilineTextAlignment(.center)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .background(.clear)
    }
}

#Preview {
    LoadingView(text: "teste")
}
