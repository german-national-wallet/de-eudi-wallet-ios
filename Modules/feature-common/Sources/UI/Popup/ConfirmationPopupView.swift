//
//  ConfirmationPopupView.swift
//  feature-common
//

import SwiftUI
import logic_ui

public struct ConfirmationPopupView: View {
    @ObservedObject var viewModel: ConfirmationPopupViewModel

    public init(viewModel: ConfirmationPopupViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
      ZStack {
        Color.black.opacity(0.4)
          .edgesIgnoringSafeArea(.all)
        VStack(spacing: 16) {
          if let titleIcon = viewModel.titleIcon {
            titleIcon
              .resizable()
              .frame(width: 30, height: 30)
              .foregroundStyle(DSColor.error)
          }

          HStack {
            if let infoIcon = viewModel.infoIcon {
              infoIcon
                .resizable()
                .foregroundStyle(DSColor.primary)
                .frame(width: 30, height: 30)
            }

            Text(viewModel.title)
              .font(DSTypography.Title.large)
              .fontWeight(DSStyle.FontWeight.medium_500)
              .foregroundStyle(DSColor.onSurface)
              .multilineTextAlignment(.center)
          }
            VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
              HStack {
                Text(viewModel.detail)
                  .font(DSTypography.Body.medium)
                  .fontWeight(DSStyle.FontWeight.regular_400)
                  .foregroundStyle(DSColor.onSurface)
                  .multilineTextAlignment(.leading)
                Spacer()
              }
          
              VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
                if !viewModel.errorCode.isEmpty {
                  VStack(alignment: .leading) {
                    Text("Error code:")
                    Text(viewModel.errorCode)
                  }
                  .font(DSTypography.Body.medium)
                  .fontWeight(DSStyle.FontWeight.regular_400)
                  .foregroundStyle(DSColor.onSurface)
                }
                
                if !viewModel.traceId.isEmpty {
                  HStack {
                    VStack(alignment: .leading) {
                      Text("Trace ID:")
                      Text(viewModel.traceId)
                    }
                    .font(DSTypography.Body.medium)
                    .fontWeight(DSStyle.FontWeight.regular_400)
                    .foregroundStyle(DSColor.onSurface)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.copyTraceId()
                    }, label: {
                        Image(systemName: viewModel.isTraceIdCopied ? "checkmark" : "doc.on.doc.fill")
                            .foregroundStyle(viewModel.isTraceIdCopied ? DSColor.primary : DSColor.onSurfaceVariant)
                            .font(.system(size: 16))
                    })
                    .buttonStyle(PlainButtonStyle())
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isTraceIdCopied)
                  }
                }
              }
            
          }
          .frame(maxWidth: .infinity)
          
          VStack {
            if let primaryTitle = viewModel.primaryButtontitle {
              DSPrimaryButton(title: primaryTitle) {
                viewModel.onConfirm()
              }
            }
            if let secondaryTitle = viewModel.secondaryButtontitle {
              DSSecondaryButton(
                title: secondaryTitle,
                action: viewModel.onCancel
              )
            }
          }
        }
        .padding(24)
        .background(DSColor.background)
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding(32)
      }
    }
}
