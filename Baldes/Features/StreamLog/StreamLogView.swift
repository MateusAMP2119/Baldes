import SwiftUI

struct StreamLogView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Stream Log")
                    .font(.largeTitle)
                Text("This is where the user can see their activity stream.")
            }
        }
    }
}

#Preview {
    StreamLogView()
}
