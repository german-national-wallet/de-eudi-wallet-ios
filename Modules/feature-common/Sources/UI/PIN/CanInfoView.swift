//
//  SwiftUIView.swift
//  feature-common
//

import SwiftUI
import logic_ui

struct CanInfoView: View {
    var body: some View {
      GeometryReader { geometry in
        VStack(alignment: .center) {
          HStack {
            Theme.shared.image.infoCircle
              .resizable()
              .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
              .foregroundColor(DSColor.onBackground)

            DSTitleLabel(LocalizableStringKey.canInfoTitle.toString)
          }
          .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
          
          Theme.shared.image.erikaCanFront1
            .resizable()
            .frame(width: geometry.size.width * 0.7, height: 170)
            .padding()
          
          Theme.shared.image.erikaCanFront2
            .resizable()
            .frame(width: geometry.size.width * 0.7, height: 170)
            .padding()
          
          Text(LocalizableStringKey.canInfoDesc.toString)
            .font(DSTypography.Body.large)
            .foregroundColor(DSColor.onBackground)
        }
        .padding(16)
      }
    }
}
