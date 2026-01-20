import SwiftUI

struct NewActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigationPath = NavigationPath()

    // MARK: - Data
    private let inputs: [ActivityScope] = [
        ActivityScope(
            title: "Acompanhar e Criar Hábitos",
            description: "Contabilizar tempo, repetições e medir progresso.",
            color: Color(red: 0.8, green: 0.2, blue: 0.8),
            imageName: "Habbit",
            imagePosition: .bottomRight,
            imageHeight: 130,
            types: [
                ActivityType(
                    title: "Objetivos por tempo",
                    description: "Para atingir metas temporais.",
                    examples: [
                        ActivityExample(emoji: "📚", text: "Ler", detail: "45m Hoje"),
                        ActivityExample(emoji: "🎨", text: "Pintura", detail: "1h Prática"),
                        ActivityExample(emoji: "🏊", text: "Natação", detail: "45m Treino"),
                    ],
                    shadowColor: Color(red: 0.8, green: 0.2, blue: 0.8)
                ),
                ActivityType(
                    title: "Contagens Diárias",
                    description: "Mantém a constância em hábitos diários.",
                    examples: [
                        ActivityExample(
                            emoji: "☀️", text: "Acordar Cedo", detail: "5 Dias Seguidos"),
                        ActivityExample(emoji: "📵", text: "Sem Redes Sociais", detail: "3 Dias"),
                        ActivityExample(emoji: "🚭", text: "Não Fumar", detail: "2 Meses"),
                    ],
                    shadowColor: Color(red: 0.9, green: 0.3, blue: 0.3)
                ),
                ActivityType(
                    title: "Metas Numéricas",
                    description: "Regista o progresso das tuas metas com precisão.",
                    examples: [
                        ActivityExample(emoji: "✍️", text: "Escrita", detail: "500 Palavras"),
                        ActivityExample(emoji: "💰", text: "Poupança", detail: "20€ Mealheiro"),
                        ActivityExample(emoji: "🏋️", text: "Elevações", detail: "5 × 10kg"),
                    ],
                    shadowColor: Color(red: 0.3, green: 0.3, blue: 0.9)
                ),
            ]
        ),
        ActivityScope(
            title: "Planear e Organizar",
            description: "Planear viagens, listagem de tarefas e projetos ou orçamentos.",
            color: Color(red: 0.9, green: 0.6, blue: 0.2),
            imageName: "Plan",
            imagePosition: .bottomLeft,
            imageHeight: 180,
            types: [
                ActivityType(
                    title: "Listas Generalistas",
                    description: "Aponta tudo para não te esqueceres de nada.",
                    examples: [
                        ActivityExample(emoji: "🛒", text: "Lista de Compras", detail: "5/12 itens"),
                        ActivityExample(emoji: "🎒", text: "Lista de Viagem", detail: "Pronto"),
                        ActivityExample(emoji: "✅", text: "Tarefas Diárias", detail: "3 restantes"),
                    ],
                    shadowColor: Color(red: 0.9, green: 0.6, blue: 0.2)
                ),
                ActivityType(
                    title: "Itinerários",
                    description: "Organiza os teus passeios e o que queres visitar.",
                    examples: [
                        ActivityExample(emoji: "🗼", text: "Viagem a Tóquio", detail: "Out 2026"),
                        ActivityExample(emoji: "🏖️", text: "Férias de Verão", detail: "Marcado"),
                        ActivityExample(emoji: "📍", text: "Locais a Visitar", detail: "12 locais"),
                    ],
                    shadowColor: Color(red: 0.2, green: 0.6, blue: 0.6)
                ),
                ActivityType(
                    title: "Orçamentos",
                    description: "Define limites e controla os teus gastos.",
                    examples: [
                        ActivityExample(emoji: "💰", text: "Gastos Gerais", detail: "Dia"),
                        ActivityExample(emoji: "🛒", text: "Budget Supermercado", detail: "Semanal"),
                        ActivityExample(emoji: "🏠", text: "Obras", detail: "Sala"),
                    ],
                    shadowColor: Color(red: 0.9, green: 0.5, blue: 0.3)
                ),
            ]
        ),
        ActivityScope(
            title: "Escrever e Refletir",
            description: "Para registos diários e notas soltas.",
            color: Color(red: 0.3, green: 0.7, blue: 0.4),
            imageName: "Write",
            imagePosition: .bottomRight,
            imageHeight: 170,
            types: [
                ActivityType(
                    title: "Diário",
                    description: "Guarda as tuas histórias e reflexões do dia-a-dia.",
                    examples: [
                        ActivityExample(emoji: "📓", text: "Diário Pessoal", detail: ""),
                        ActivityExample(emoji: "💭", text: "Pensamentos", detail: "Manhã"),
                        ActivityExample(emoji: "✨", text: "Gratidão", detail: "Noite"),
                    ],
                    shadowColor: Color(red: 0.3, green: 0.7, blue: 0.4)
                ),
                ActivityType(
                    title: "Notas",
                    description: "Bloco de notas para tudo o que te vier à cabeça.",
                    examples: [
                        ActivityExample(emoji: "📝", text: "Notas Rápidas", detail: ""),
                        ActivityExample(emoji: "💡", text: "Ideias", detail: "Projeto X"),
                        ActivityExample(emoji: "🏗️", text: "Notas de Reuniões", detail: "Semanal"),
                    ],
                    shadowColor: Color(red: 0.5, green: 0.5, blue: 0.5)
                ),
                ActivityType(
                    title: "Registo de Sentimentos",
                    description: "Controlo sobre o que sentes.",
                    examples: [
                        ActivityExample(emoji: "🧘", text: "Stresse Diário", detail: ""),
                        ActivityExample(emoji: "⚡", text: "Nível de Energia", detail: ""),
                        ActivityExample(emoji: "😴", text: "Qualidade do Sono", detail: ""),
                    ],
                    shadowColor: Color(red: 0.2, green: 0.6, blue: 0.7)
                ),
            ]
        ),
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GoalSelectionView(scopes: inputs) { selectedScope in
                navigationPath.append(selectedScope)
            }
            .navigationTitle("Novo Balde de atividades")
            .font(.system(size: 16, weight: .bold))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.black)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .navigationDestination(for: ActivityScope.self) { scope in
                ActivityTypeSelectionView(scope: scope)
            }
            .navigationDestination(for: ActivityConfigurationContext.self) { context in
                ActivityConfigurationView(context: context)
            }
        }
    }
}

#Preview {
    NewActivityView()
}
