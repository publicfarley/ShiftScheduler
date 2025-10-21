import SwiftUI

struct EditLocationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var address: String
    
    private var isFormValid: Bool {
        !name.isEmpty && !address.isEmpty
    }
    
    let location: Location
    
    init(location: Location) {
        self.location = location
        _name = State(initialValue: location.name)
        _address = State(initialValue: location.address)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("LOCATION INFORMATION")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            
                            VStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Name")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("Location name", text: $name)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)
                                    
                                    Divider()
                                    
                                    HStack(alignment: .top) {
                                        Text("Address")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("Street address", text: $address, axis: .vertical)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(.secondary)
                                            .lineLimit(4, reservesSpace: true)
                                    }
                                    .padding(.vertical, 12)
                                }
                                .padding(.horizontal, 16)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .dismissKeyboardOnTap()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        updateLocation()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func updateLocation() {
        location.name = name
        location.address = address
        dismiss()
    }
}

#Preview {
    EditLocationView(location: Location(name: "Sample Location", address: "123 Main St"))
}