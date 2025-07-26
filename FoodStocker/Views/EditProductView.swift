//
//  EditProductView.swift
//  FoodStocker
//
//  Interface complète de modification de produit
//

import SwiftUI

struct EditProductView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditProductViewModel
    @State private var showingUnsavedChangesAlert = false
    @State private var showingSuccessToast = false
    @State private var toastMessage = ""
    
    init(product: ProductModel, viewModel: EditProductViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                
                Form {
                    GeneralInfoEditSection(viewModel: viewModel)
                    CategoryLocationEditSection(viewModel: viewModel)
                    DateTraceabilityEditSection(viewModel: viewModel)
                    ValidationErrorsEditSection(viewModel: viewModel)
                }
                .scrollContentBackground(.hidden)
                
                // Toast overlay
                if showingSuccessToast {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage, type: .success)
                            .padding(.bottom, 100)
                    }
                    .animation(.easeInOut(duration: 0.3), value: showingSuccessToast)
                }
            }
            .navigationTitle("Modifier le produit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.AppGradients.primary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                toolbarContent
            }
            .alert("Modifications non sauvegardées", isPresented: $showingUnsavedChangesAlert) {
                Button("Abandonner", role: .destructive) {
                    dismiss()
                }
                Button("Continuer l'édition", role: .cancel) { }
            } message: {
                Text("Vous avez des modifications non sauvegardées. Voulez-vous vraiment quitter sans sauvegarder ?")
            }
            .onChange(of: viewModel.name) {
                viewModel.validateForm()
            }
            .onChange(of: viewModel.quantity) {
                viewModel.validateForm()
            }
            .onChange(of: viewModel.expirationDate) {
                viewModel.validateForm()
            }
            .onChange(of: viewModel.lotNumber) {
                viewModel.validateForm()
            }
            .onChange(of: viewModel.selectedUnit) {
                viewModel.validateForm()
            }
            .onChange(of: viewModel.selectedCategory) {
                viewModel.validateForm()
            }
            .onChange(of: viewModel.selectedLocation) {
                viewModel.validateForm()
            }
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        Color.AppGradients.backgroundIntense
            .ignoresSafeArea()
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            cancelButton
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            saveButton
        }
    }
    
    private var cancelButton: some View {
        Button {
            if viewModel.hasUnsavedChanges() {
                showingUnsavedChangesAlert = true
            } else {
                dismiss()
            }
        } label: {
            Text("Annuler")
                .foregroundStyle(Color.AppGradients.error)
                .font(.headline.weight(.semibold))
        }
    }
    
    private var saveButton: some View {
        Button {
            Task {
                let success = await viewModel.updateProduct()
                if success {
                    await MainActor.run {
                        toastMessage = "Produit modifié avec succès"
                        showingSuccessToast = true
                        
                        // Auto-dismiss after showing toast
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            }
        } label: {
            saveButtonLabel
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
    }
    
    private var saveButtonLabel: some View {
        HStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                Image(systemName: "checkmark.circle.fill")
            }
            Text(viewModel.isLoading ? "Sauvegarde..." : "Sauvegarder")
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
}

// MARK: - Form Sections for EditProductView

// MARK: - General Info Edit Section
struct GeneralInfoEditSection: View {
    @Bindable var viewModel: EditProductViewModel
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                sectionHeader
                nameField
                quantityAndUnitFields
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(sectionBackground)
    }
    
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.AppGradients.primary)
                .font(.title2)
            
            Text("Informations générales")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.AppGradients.accent)
            
            Spacer()
            
            if viewModel.hasChanges {
                Image(systemName: "pencil.circle.fill")
                    .foregroundStyle(Color.AppGradients.warning)
                    .font(.title3)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Nom du produit")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.AppGradients.primary)
                
                if viewModel.hasError(for: .name) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.AppGradients.error)
                        .font(.caption)
                }
            }
            
            TextField("Ex: Pommes, Lait, Poulet...", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)
                .background(fieldBackground)
                .accessibilityLabel("Nom du produit")
        }
    }
    
    private var quantityAndUnitFields: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Quantité")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.AppGradients.secondary)
                    
                    if viewModel.hasError(for: .quantity) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.AppGradients.error)
                            .font(.caption)
                    }
                }
                
                TextField("2.5", text: $viewModel.quantity)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Quantité")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Unité")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.AppGradients.accent)
                
                unitPicker
            }
        }
    }
    
    private var unitPicker: some View {
        Picker("Unité", selection: $viewModel.selectedUnit) {
            ForEach(viewModel.availableUnits, id: \.self) { unit in
                Text(unit)
                    .foregroundStyle(Color.AppGradients.secondary)
                    .tag(unit)
            }
        }
        .pickerStyle(.menu)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(pickerBackground)
    }
    
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.ultraThinMaterial)
            .stroke(Color.AppGradients.primary, lineWidth: 2)
    }
    
    private var pickerBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.AppGradients.cardBackground)
            .stroke(Color.AppGradients.secondary, lineWidth: 1)
    }
    
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .stroke(Color.AppGradients.primary.opacity(0.5), lineWidth: 1)
    }
}

// MARK: - Category Location Edit Section
struct CategoryLocationEditSection: View {
    @Bindable var viewModel: EditProductViewModel
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                sectionHeader
                categoryPicker
                locationPicker
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(sectionBackground)
    }
    
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "tag.fill")
                .foregroundStyle(Color.AppGradients.secondary)
                .font(.title2)
            
            Text("Catégorie et emplacement")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.AppGradients.accent)
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Catégorie")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.AppGradients.primary)
            
            Picker("Catégorie", selection: $viewModel.selectedCategory) {
                ForEach(ProductCategory.allCases, id: \.self) { category in
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.rawValue)
                    }
                    .tag(category)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(pickerBackground)
        }
    }
    
    private var locationPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emplacement")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.AppGradients.accent)
            
            Picker("Emplacement", selection: $viewModel.selectedLocation) {
                ForEach(ProductLocation.allCases, id: \.self) { location in
                    HStack {
                        Image(systemName: location.icon)
                        Text(location.rawValue)
                    }
                    .tag(location)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(pickerBackground)
        }
    }
    
    private var pickerBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.AppGradients.cardBackground)
            .stroke(Color.AppGradients.secondary, lineWidth: 1)
    }
    
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .stroke(Color.AppGradients.secondary.opacity(0.5), lineWidth: 1)
    }
}

// MARK: - Date Traceability Edit Section
struct DateTraceabilityEditSection: View {
    @Bindable var viewModel: EditProductViewModel
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                sectionHeader
                expirationDatePicker
                lotNumberField
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(sectionBackground)
    }
    
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(Color.AppGradients.warning)
                .font(.title2)
            
            Text("Date et traçabilité")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.AppGradients.accent)
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    private var expirationDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Date d'expiration")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.AppGradients.warning)
                
                if viewModel.hasError(for: .expirationDate) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.AppGradients.error)
                        .font(.caption)
                }
            }
            
            DatePicker(
                "Date d'expiration",
                selection: $viewModel.expirationDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(datePickerBackground)
            .accessibilityLabel("Date d'expiration du produit")
        }
    }
    
    private var lotNumberField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Numéro de lot")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.AppGradients.accent)
                
                if viewModel.hasError(for: .lotNumber) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.AppGradients.error)
                        .font(.caption)
                }
            }
            
            TextField("Ex: LOT1234", text: $viewModel.lotNumber)
                .textFieldStyle(.roundedBorder)
                .background(fieldBackground)
                .accessibilityLabel("Numéro de lot")
        }
    }
    
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.ultraThinMaterial)
            .stroke(Color.AppGradients.accent, lineWidth: 2)
    }
    
    private var datePickerBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.AppGradients.cardBackground)
            .stroke(Color.AppGradients.warning, lineWidth: 1)
    }
    
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .stroke(Color.AppGradients.warning.opacity(0.5), lineWidth: 1)
    }
}

// MARK: - Validation Errors Edit Section
struct ValidationErrorsEditSection: View {
    let viewModel: EditProductViewModel
    
    var body: some View {
        if viewModel.hasValidationErrors {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.AppGradients.error)
                            .font(.title2)
                        
                        Text("Erreurs de validation")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.AppGradients.error)
                        
                        Spacer()
                    }
                    
                    ForEach(viewModel.validationErrors, id: \.self) { error in
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.AppGradients.error)
                                .font(.caption)
                            
                            Text(error.localizedDescription)
                                .font(.subheadline)
                                .foregroundStyle(Color.AppGradients.error)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
            }
            .listRowBackground(errorSectionBackground)
        }
    }
    
    private var errorSectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.AppGradients.error.opacity(0.1))
            .stroke(Color.AppGradients.error.opacity(0.5), lineWidth: 1)
    }
}

// MARK: - Toast View Component
struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success, error, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundColor(.white)
                .font(.title3)
            
            Text(message)
                .foregroundColor(.white)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.color, in: Capsule())
        .shadow(radius: 4)
    }
}

#Preview {
    EditProductView(
        product: ProductModel(
            name: "Pommes",
            quantity: 2.5,
            unit: "kg",
            category: .fruits,
            location: .pantry,
            arrivalDate: Date(),
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            lotNumber: "LOT1234"
        ),
        viewModel: EditProductViewModel.mock(with: ProductModel(
            name: "Pommes",
            quantity: 2.5,
            unit: "kg",
            category: .fruits,
            location: .pantry,
            arrivalDate: Date(),
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            lotNumber: "LOT1234"
        ))
    )
}