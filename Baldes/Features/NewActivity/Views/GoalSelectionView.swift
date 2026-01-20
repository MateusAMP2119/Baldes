import SwiftUI

struct GoalSelectionView: View {
    let scopes: [ActivityScope]
    let onSelect: (ActivityScope) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Por onde começar?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 20)

                    VStack(spacing: 16) {
                        ForEach(scopes) { scope in
                            GoalCard(scope: scope) {
                                onSelect(scope)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Color.clear.frame(height: 250)
            }

            Image("Think")
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
