import SwiftData
import SwiftUI

struct ActivityEditView: View {
    @Bindable var activity: Activity
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes") {
                    TextField("Nome", text: $activity.name)

                    HStack {
                        Text("Símbolo")
                        Spacer()
                        Image(systemName: activity.symbol)
                            .foregroundStyle(Color(hex: activity.colorHex))
                    }
                }

                Section("Metas") {
                    if let goalTime = activity.goalTimeSeconds {
                        HStack {
                            Text("Tempo diário")
                            Spacer()
                            Text("\(Int(goalTime / 60)) min")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let target = activity.metricTarget, let unit = activity.metricUnit {
                        HStack {
                            Text("Meta")
                            Spacer()
                            Text("\(Int(target)) \(unit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        // Delete action would go here
                    } label: {
                        HStack {
                            Spacer()
                            Text("Eliminar Atividade")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Editar Atividade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
