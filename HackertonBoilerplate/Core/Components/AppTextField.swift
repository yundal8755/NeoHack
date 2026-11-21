import SwiftUI

struct AppTextField: View {
    let placeholder: String
    let systemImage: String?
    @Binding var text: String

    init(_ placeholder: String, systemImage: String? = nil, text: Binding<String>) {
        self.placeholder = placeholder
        self.systemImage = systemImage
        self._text = text
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(AppColor.textSecondary)
            }

            TextField("", text: $text, prompt: Text(verbatim: placeholder))
                .font(AppFont.body)
                .foregroundStyle(AppColor.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(AppSpacing.md)
        .background(AppColor.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(AppColor.border)
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    AppTextField("Search", systemImage: "magnifyingglass", text: $text)
        .padding(AppSpacing.lg)
        .background(AppColor.background)
}
