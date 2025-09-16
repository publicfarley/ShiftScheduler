//
//  Card.swift
//  ShiftScheduler
//
//  Created by Farley Caesar on 2025-09-15.
//



import SwiftUI

// MARK: - Data Model
struct Card: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let creationDate: Date
    let color: Color // For Variant 3
}

// MARK: - Sample Data
func generateSampleCards() -> [Card] {
    let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .indigo, .teal]
    return (1...10).map { i in
        Card(
            title: "Card Title \(i)",
            description: "This is a sample description for card number \(i). It can contain a few lines of text.",
            creationDate: Date().addingTimeInterval(-Double(i) * 3600 * 24),
            color: colors.randomElement()!
        )
    }
}

let sampleCards: [Card] = generateSampleCards()

// MARK: - Main Tab View
struct ContentView2: View {
    var body: some View {
        TabView {
            Variant1ListView()
                .tabItem {
                    Label("Classic", systemImage: "rectangle.grid.1x2")
                }

            Variant2ListView()
                .tabItem {
                    Label("Minimal", systemImage: "list.bullet")
                }

            Variant3ListView()
                .tabItem {
                    Label("Colorful", systemImage: "square.stack.3d.up.fill")
                }

            Variant4ListView()
                .tabItem {
                    Label("Timeline", systemImage: "arrow.down.right.and.arrow.up.left")
                }
        }
    }
}

// MARK: - Variant 1: Classic Clean
struct Variant1ListView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(sampleCards) { card in
                        CardViewVariant1(card: card)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Classic Design")
        }
    }
}

struct CardViewVariant1: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(card.creationDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    Button(action: {}) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Text(card.description)
                .font(.body)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


// MARK: - Variant 2: Minimalist Modern
struct Variant2ListView: View {
    var body: some View {
        NavigationView {
            List(sampleCards) { card in
                CardViewVariant2(card: card)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            }
            .listStyle(.plain)
            .navigationTitle("Minimalist Design")
        }
    }
}

struct CardViewVariant2: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.title)
                    .font(.system(.headline, design: .serif))
                Spacer()
                Text(card.creationDate, format: .relative(presentation: .numeric))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(card.description)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 30) {
                Spacer()
                Button(action: {}) {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.borderless)
                
                Button(action: {}) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
            .font(.caption)
            .padding(.top, 8)
            
            Divider().padding(.top, 8)
        }
    }
}


// MARK: - Variant 3: Colorful & Bold
struct Variant3ListView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(sampleCards) { card in
                        CardViewVariant3(card: card)
                    }
                }
                .padding()
            }
            .navigationTitle("Colorful Design")
        }
    }
}

struct CardViewVariant3: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading) {
            Text(card.title)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(card.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom)
            
            Spacer()
            
            HStack {
                Text(card.creationDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())

                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Button(action: {}) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(card.color.gradient)
        .cornerRadius(20)
        .shadow(color: card.color.opacity(0.5), radius: 8, x: 0, y: 4)
    }
}


// MARK: - Variant 4: Timeline
struct Variant4ListView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sampleCards.enumerated()), id: \.element.id) { index, card in
                        CardViewVariant4(card: card, isFirst: index == 0, isLast: index == sampleCards.count - 1)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Timeline Design")
        }
    }
}

struct CardViewVariant4: View {
    let card: Card
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Timeline
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle().fill(Color.accentColor).frame(width: 2, height: 20)
                }
                
                Circle()
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: 14, height: 14)
                    .background(Circle().fill(Color(.systemBackground)))
                
                if !isLast {
                    Rectangle().fill(Color.accentColor).frame(width: 2)
                }
            }
            .padding(.top, isFirst ? 25 : 0)


            // Card Content
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                            .fontWeight(.bold)
                        Text(card.creationDate, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack {
                        Button(action: {}) { Image(systemName: "pencil") }
                        Button(action: {}) { Image(systemName: "trash") }
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                
                Text(card.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding([.horizontal, .top])
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Previews
#Preview {
   ContentView2()
}
