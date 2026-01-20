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
            imageName: "Think",
            imagePosition: .bottomRight,
            imageHeight: 120,
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
            imageHeight: 220,
            types: [
                ActivityType(
                    title: "Lista de Verificação",
                    description: "Aponta tudo para não te esqueceres de nada.",
                    examples: [
                        ActivityExample(emoji: "🛒", text: "Lista de Compras", detail: "5/12 itens"),
                        ActivityExample(emoji: "🎒", text: "Lista de Viagem", detail: "Pronto"),
                        ActivityExample(emoji: "✅", text: "Tarefas Diárias", detail: "3 restantes"),
                    ],
                    shadowColor: Color(red: 0.9, green: 0.6, blue: 0.2)
                ),
                ActivityType(
                    title: "Itinerário",
                    description: "Organiza os teus passeios e o que queres visitar.",
                    examples: [
                        ActivityExample(emoji: "🗼", text: "Viagem a Tóquio", detail: "Out 2026"),
                        ActivityExample(emoji: "🏖️", text: "Férias de Verão", detail: "Marcado"),
                        ActivityExample(emoji: "📍", text: "Locais a Visitar", detail: "12 locais"),
                    ],
                    shadowColor: Color(red: 0.2, green: 0.6, blue: 0.6)
                ),
            ]
        ),
        ActivityScope(
            title: "Escrever e Refletir",
            description: "Para registos diários e notas soltas.",
            color: Color(red: 0.3, green: 0.7, blue: 0.4),
            imageName: "Write",
            imagePosition: .bottomRight,
            imageHeight: 220,
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
                        ActivityExample(emoji: "💡", text: "Ideias", detail: "Projeto A"),
                        ActivityExample(emoji: "🏗️", text: "Notas de Reunião", detail: "Semanal"),
                    ],
                    shadowColor: Color(red: 0.5, green: 0.5, blue: 0.5)
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
            .navigationDestination(for: ActivityType.self) { type in
                ActivityConfigurationView(activityType: type)
            }
        }
    }
}

// MARK: - Step 1: Goal Selection View

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

struct GoalCard: View {
    let scope: ActivityScope
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scope.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(scope.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .fontWeight(.semibold)
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(scope.color)
                    .offset(x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Activity Type Selection View

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
                            NavigationLink(value: type) {
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

// MARK: - Supporting Views

struct ActivityTypeCard: View {
    let title: String
    let description: String
    let examples: [ActivityExample]
    let shadowColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                    .padding(6)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
            }

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
                .frame(height: 2)

            // Examples Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(examples, id: \.text) { example in
                        HStack(spacing: 4) {
                            Text(example.emoji)
                            Text(example.text)
                                .fontWeight(.medium)
                            if !example.detail.isEmpty {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(example.detail)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }

        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(shadowColor)
                .offset(x: 0, y: 4)
        )
    }
}

#Preview {
    NewActivityView()
}
