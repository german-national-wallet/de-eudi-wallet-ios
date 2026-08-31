//
//  SegmentedToggle.swift
//  feature-issuance
//
import SwiftUI
import logic_ui

// TODO: We will have to remove the entire flow under this, since we will no longer need this.
struct CredentialFormatSegmentedToggle: View {
    var options: [AddDocumentUIModel]
    let msoMdocConfigId: String
    @Binding var selected: AddDocumentUIModel

    private var sortedOptions: [AddDocumentUIModel] {
        options.sorted { first, second in
            if first.id == msoMdocConfigId { return true }
            if second.alias == msoMdocConfigId { return false }
            return first.alias < second.alias
        }
    }

    var body: some View {
        HStack(spacing: 0) {
          ForEach(sortedOptions, id: \.id) { option in
                Button(action: {
                    withAnimation {
                        selected = option
                    }
                }, label: {
                    HStack(spacing: 6) {
                        if selected.format == option.format {
                            Image(systemName: "checkmark")
                        }
                      Text(option.alias)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                      selected.format == option.format ? Color.purple.opacity(0.15) : Color.clear
                    )
                })
                .foregroundColor(.black)
            }
        }
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.gray, lineWidth: 1)
        )
        .padding([.leading, .bottom, .trailing])
        .onAppear {
            // Set default selection to first option if not already selected
            let sorted = sortedOptions
            if !sorted.contains(where: { $0.id == selected.id }), let firstOption = sorted.first {
                selected = firstOption
            }
        }
    }
}
