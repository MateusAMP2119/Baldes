import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

struct UniversalStepView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel
    @State private var emojiInput: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Activity Type Title
                Text(viewModel.context.type.title)
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Name Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nome")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        TextField("", text: $viewModel.name)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Icon Picker
                        ZStack(alignment: .center) {
                            let isSFSymbol: Bool = {
                                #if canImport(UIKit)
                                    return UIImage(systemName: viewModel.symbol) != nil
                                #elseif canImport(AppKit)
                                    return NSImage(
                                        systemSymbolName: viewModel.symbol,
                                        accessibilityDescription: nil) != nil
                                #else
                                    return false
                                #endif
                            }()

                            if isSFSymbol {
                                Image(systemName: viewModel.symbol)
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            } else if emojiInput.isEmpty && !viewModel.symbol.isEmpty {
                                Text(viewModel.symbol)
                                    .font(.title2)
                            }

                            TextField("", text: $emojiInput)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .onChange(of: emojiInput) { _, newValue in
                                    // Use scalar properties to check for Emoji
                                    let validEmojis = newValue.filter { char in
                                        guard let scalar = char.unicodeScalars.first else {
                                            return false
                                        }
                                        return scalar.properties.isEmoji
                                            && !scalar.isASCII
                                    }

                                    if let lastEmoji = validEmojis.last {
                                        let newString = String(lastEmoji)
                                        if emojiInput != newString {
                                            emojiInput = newString
                                        }
                                        viewModel.symbol = newString
                                    } else {
                                        // If valid emojis found is empty
                                        if !newValue.isEmpty {
                                            emojiInput = ""
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .frame(width: 56, height: 56)
                        .background(Color.white)
                    }
                }

                // Configuration Section (Merged)
                VStack(spacing: 24) {
                    if viewModel.context.scope.title == "Acompanhar e Criar Hábitos" {
                        HabitsConfigView(viewModel: viewModel)
                    } else if viewModel.context.scope.title == "Planear e Organizar" {
                        PlanConfigView(viewModel: viewModel)
                    } else if viewModel.context.scope.title == "Escrever e Refletir" {
                        ReflectConfigView(viewModel: viewModel)
                    }
                }
            }
            .padding()
            .padding(.bottom, 120)
        }
        .onAppear {
            let isSFSymbol: Bool = {
                #if canImport(UIKit)
                    return UIImage(systemName: viewModel.symbol) != nil
                #elseif canImport(AppKit)
                    return NSImage(
                        systemSymbolName: viewModel.symbol, accessibilityDescription: nil) != nil
                #else
                    return false
                #endif
            }()

            if !isSFSymbol {
                emojiInput = viewModel.symbol
            }
        }
    }
}
