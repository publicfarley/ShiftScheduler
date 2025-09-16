//
//  CardData.swift
//  ShiftScheduler
//
//  Created by Farley Caesar on 2025-09-15.
//


import SwiftUI

// MARK: - Data Models
struct CardData: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let creationDate: Date
    let color: Color
    let icon: String
}

// MARK: - Sample Data Generator
extension CardData {
    static func generateSampleData() -> [CardData] {
        let titles: [String] = [
            "Project Alpha", "Task Managementi", "Design System", "User Research",
            "Code Review", "Sprint Planning", "Bug Fixes", "Feature Release",
            "Team Meeting", "Documentation"
        ]
        
        let descriptions: [String] = [
            "Complete the initial phase of the project with all stakeholders aligned",
            "Organize and prioritize tasks for maximum productivity",
            "Establish consistent design patterns across all platforms",
            "Conduct user interviews and analyze feedback data",
            "Review pull requests and ensure code quality standards",
            "Plan upcoming sprint goals and resource allocation",
            "Address critical bugs reported by the QA team",
            "Deploy new features to production environment",
            "Weekly sync with cross-functional teams",
            "Update technical documentation and user guides"
        ]
        
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .indigo, .teal, .cyan, .mint]
        let icons: [String] = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "flame.fill", "snowflake", "sun.max.fill", "moon.fill", "cloud.fill", "diamond.fill"]
        
        var cards: [CardData] = []
        let calendar = Calendar.current
        let today = Date()
        
        for index in 0..<5 {
            let card = CardData(
                title: titles[index],
                description: descriptions[index],
                creationDate: calendar.date(byAdding: .day, value: -index, to: today) ?? today,
                color: colors[index],
                icon: icons[index]
            )
            cards.append(card)
        }
        
        return cards
    }
}

// MARK: - Card Variant 1: Classic Material Design
struct ClassicMaterialCard: View {
    let card: CardData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: card.icon)
                    .foregroundColor(card.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(card.creationDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "pencil")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Text(card.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Card Variant 2: Gradient Header Style
struct GradientHeaderCard: View {
    let card: CardData
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(card.creationDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: card.icon)
                    .font(.title)
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [card.color, card.color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Content area
            VStack(alignment: .leading, spacing: 12) {
                Text(card.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                HStack {
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Card Variant 3: Minimal Border Style
struct MinimalBorderCard: View {
    let card: CardData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(card.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: card.icon)
                            .font(.body)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(card.creationDate, style: .date)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(card.description)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(4)
            
            HStack {
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(card.color.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

// MARK: - Card Variant 4: Floating Action Style
struct FloatingActionCard: View {
    let card: CardData
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: card.icon)
                        .font(.title2)
                        .foregroundColor(card.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.title)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(card.creationDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text(card.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                Spacer()
            }
            .padding(20)
            .padding(.trailing, 40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(card.color.opacity(0.05))
            )
            
            // Floating action buttons
            VStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.blue))
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                Button(action: {}) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.red))
                        .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                Spacer()
            }
            .padding(.trailing, 16)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 140)
    }
}

// MARK: - Card Variant 5: Neumorphic Style
struct NeumorphicCard: View {
    let card: CardData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(card.creationDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: card.icon)
                    .font(.title2)
                    .foregroundColor(card.color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
                            .shadow(color: .white.opacity(0.7), radius: 4, x: -2, y: -2)
                    )
            }
            
            Text(card.description)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
            
            HStack {
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Image(systemName: "pencil")
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
                                    .shadow(color: .white.opacity(0.7), radius: 2, x: -1, y: -1)
                            )
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
                                    .shadow(color: .white.opacity(0.7), radius: 2, x: -1, y: -1)
                            )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 4, y: 4)
                .shadow(color: .white.opacity(0.7), radius: 8, x: -4, y: -4)
        )
    }
}

// MARK: - Card Variant 6: Glass Morphism Style
struct GlassmorphismCard: View {
    let card: CardData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(card.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: card.icon)
                    .font(.title)
                    .foregroundColor(card.color)
            }
            
            Text(card.creationDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(card.description)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
            
            HStack {
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                Button(action: {}) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [card.color.opacity(0.3), card.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Card Variant 7: Compact List Style
struct CompactListCard: View {
    let card: CardData
    
    var body: some View {
        HStack(spacing: 16) {
            // Left indicator
            Rectangle()
                .fill(card.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            // Icon
            Image(systemName: card.icon)
                .font(.title2)
                .foregroundColor(card.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(card.color.opacity(0.1))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(card.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(card.creationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                
                Button(action: {}) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Card Variant 8: Magazine Style
struct MagazineStyleCard: View {
    let card: CardData
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [card.color.opacity(0.8), card.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)
                
                // Action buttons overlay
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "pencil")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(.black.opacity(0.2)))
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(.black.opacity(0.2)))
                    }
                }
                .padding(.top, 12)
                .padding(.trailing, 12)
                
                // Icon and title
                HStack {
                    Image(systemName: card.icon)
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(card.creationDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            
            // Content section
            VStack(alignment: .leading, spacing: 12) {
                Text(card.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Card Variant Views
struct CardVariantView<CardType: View>: View {
    let title: String
    let cards: [CardData]
    let cardBuilder: (CardData) -> CardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(cards) { card in
                        cardBuilder(card)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Main Content View
struct ContentView3: View {
    let sampleCards = CardData.generateSampleData()
    
    var body: some View {
        TabView {
            CardVariantView(title: "Classic Material Design", cards: sampleCards) { card in
                ClassicMaterialCard(card: card)
            }
            .tabItem {
                Image(systemName: "square.stack.3d.up")
                Text("Classic")
            }
            
            CardVariantView(title: "Gradient Header Style", cards: sampleCards) { card in
                GradientHeaderCard(card: card)
            }
            .tabItem {
                Image(systemName: "paintbrush.pointed")
                Text("Gradient")
            }
            
            CardVariantView(title: "Minimal Border Style", cards: sampleCards) { card in
                MinimalBorderCard(card: card)
            }
            .tabItem {
                Image(systemName: "rectangle.portrait")
                Text("Minimal")
            }
            
            CardVariantView(title: "Floating Action Style", cards: sampleCards) { card in
                FloatingActionCard(card: card)
            }
            .tabItem {
                Image(systemName: "circle.fill")
                Text("Floating")
            }
            
            CardVariantView(title: "Neumorphic Style", cards: sampleCards) { card in
                NeumorphicCard(card: card)
            }
            .tabItem {
                Image(systemName: "sun.max")
                Text("Neumorphic")
            }
            
            CardVariantView(title: "Glassmorphism Style", cards: sampleCards) { card in
                GlassmorphismCard(card: card)
            }
            .tabItem {
                Image(systemName: "sparkles")
                Text("Glass")
            }
            
            CardVariantView(title: "Compact List Style", cards: sampleCards) { card in
                CompactListCard(card: card)
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Compact")
            }
            
            CardVariantView(title: "Magazine Style", cards: sampleCards) { card in
                MagazineStyleCard(card: card)
            }
            .tabItem {
                Image(systemName: "doc.richtext")
                Text("Magazine")
            }
        }
        .navigationTitle("Card Variants")
    }
}

#Preview {
    ContentView3()
}
