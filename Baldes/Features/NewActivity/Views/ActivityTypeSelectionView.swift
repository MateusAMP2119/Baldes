import SwiftUI

struct ActivityTypeSelectionView: View {
    let scope: ActivityScope

    var body: some View {
        ZStack(alignment: scope.imagePosition.alignment) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(scope.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Escolhe um modelo para começar")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        ForEach(scope.types) { type in
                            NavigationLink(
                                value: ActivityConfigurationContext(scope: scope, type: type)
                            ) {
                                ActivityTypeCard(
                                    title: type.title,
                                    description: type.description,
                                    examples: type.examples,
                                    shadowColor: type.shadowColor
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)

                    Color.clear.frame(height: scope.imageHeight)
                }
            }

            Image(scope.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: scope.imageHeight)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
