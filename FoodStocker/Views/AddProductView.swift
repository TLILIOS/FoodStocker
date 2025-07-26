import SwiftUI

struct AddProductView: View {
    @State private var viewModel: AddProductViewModel
    @State private var showingSuccessAlert = false
    
    init(viewModel: AddProductViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                formContent
            }
            .navigationTitle("➕ Ajouter un produit")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.AppGradients.primary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                toolbarContent
            }
            .alert("Produit ajouté", isPresented: $showingSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("Le produit a été ajouté avec succès à votre stock.")
            }
            .alert("Erreur", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
            .sheet(isPresented: $viewModel.isShowingScanner) {
                NavigationView {
                    BarcodeScannerWrapper(
                        scannedCode: .constant(""),
                        completion: { scannedCode in
                            Task { @MainActor in
                                viewModel.updateLotNumberFromScan(scannedCode)
                            }
                        }
                    )
                    .navigationTitle("Scanner Code-Barres")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Annuler") {
                                Task { @MainActor in
                                    viewModel.hideScanner()
                                }
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.name) { _, _ in
                Task.detached { @MainActor in
                    viewModel.validateForm()
                }
            }
            .onChange(of: viewModel.quantity) { _, _ in
                Task.detached { @MainActor in
                    viewModel.validateForm()
                }
            }
            .onChange(of: viewModel.expirationDate) { _, _ in
                Task.detached { @MainActor in
                    viewModel.validateForm()
                }
            }
            .onChange(of: viewModel.lotNumber) { _, newValue in
                print("📝 ONCHANGE: lotNumber changé vers '\(newValue)'")
                // Validation avec Task.detached pour éviter les hangs
                Task.detached { @MainActor in
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second delay
                    viewModel.validateForm()
                }
            }
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        // Arrière-plan identique aux autres vues
        Color.AppGradients.backgroundIntense
            .ignoresSafeArea()
    }
    
    // MARK: - Form Content
    private var formContent: some View {
        Form {
            GeneralInfoSection(viewModel: viewModel)
            CategoryLocationSection(viewModel: viewModel)
            DateTraceabilitySection(viewModel: viewModel)
            ValidationErrorsSection(viewModel: viewModel)
        }
        .scrollContentBackground(.hidden)
        .onTapGesture {
            hideKeyboard()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Terminé") {
                    hideKeyboard()
                }
                .foregroundStyle(Color.AppGradients.primary)
                .font(.headline.weight(.semibold))
            }
        }
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            cancelButton
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            addButton
        }
    }
    
    private var cancelButton: some View {
        Button {
            viewModel.resetForm()
        } label: {
            HStack {
                Image(systemName: "xmark.circle.fill")
                Text("Annuler")
            }
            .foregroundStyle(Color.AppGradients.error)
            .font(.headline.weight(.semibold))
        }
    }
    
    private var addButton: some View {
        Button {
            Task {
                let success = await viewModel.addProduct()
                if success {
                    showingSuccessAlert = true
                }
            }
        } label: {
            addButtonLabel
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
    }
    
    private var addButtonLabel: some View {
        HStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                Image(systemName: "plus.circle.fill")
            }
            Text(viewModel.isLoading ? "Ajout..." : "Ajouter")
        }
        .foregroundStyle(buttonForegroundStyle)
        .font(.headline.weight(.semibold))
    }
    
    private var buttonForegroundStyle: some ShapeStyle {
        if viewModel.isFormValid {
            return AnyShapeStyle(Color.AppGradients.success)
        } else {
            return AnyShapeStyle(Color.AppGradients.secondary.opacity(0.5))
        }
    }
    
    // MARK: - Keyboard Management
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    AddProductView(viewModel: AddProductViewModel.mock())
}