import SwiftUI

// MARK: - Form Sections for AddProductView
struct GeneralInfoSection: View {
    @Bindable var viewModel: AddProductViewModel
    
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
        }
        .padding(.bottom, 8)
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nom du produit")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.AppGradients.primary)
            
            TextField("Ex: Pommes, Lait, Poulet...", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)
                .background(fieldBackground)
                .accessibilityLabel("Nom du produit")
        }
    }
    
    private var quantityAndUnitFields: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quantité")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.AppGradients.secondary)
                
                TextField("2.5", text: $viewModel.quantity)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Quantité")
                    .onSubmit {
                        // Action optionnelle lors de la soumission
                        viewModel.validateForm()
                    }
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

// MARK: - Category and Location Section
struct CategoryLocationSection: View {
    @Bindable var viewModel: AddProductViewModel
    
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
            Image(systemName: "folder.fill")
                .foregroundStyle(Color.AppGradients.accent)
                .font(.title2)
            
            Text("Catégorie et emplacement")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.AppGradients.secondary)
            
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
                            .foregroundStyle(Color.AppGradients.accent)
                        Text(category.rawValue)
                            .foregroundStyle(Color.AppGradients.primary)
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
                .foregroundStyle(Color.AppGradients.secondary)
            
            Picker("Emplacement", selection: $viewModel.selectedLocation) {
                ForEach(ProductLocation.allCases, id: \.self) { location in
                    HStack {
                        Image(systemName: location.icon)
                            .foregroundStyle(Color.AppGradients.secondary)
                        Text(location.rawValue)
                            .foregroundStyle(Color.AppGradients.accent)
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
            .stroke(Color.AppGradients.accent, lineWidth: 1)
    }
    
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .stroke(Color.AppGradients.accent.opacity(0.5), lineWidth: 1)
    }
}

// MARK: - Date and Traceability Section
struct DateTraceabilitySection: View {
    @Bindable var viewModel: AddProductViewModel
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                sectionHeader
                datePicker
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
            
            Text("Dates et traçabilité")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.AppGradients.warning)
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
    
    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date d'expiration")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.AppGradients.primary)
            
            DatePicker("Date d'expiration", selection: $viewModel.expirationDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(datePickerBackground)
                .accessibilityLabel("Date d'expiration")
        }
    }
    
    private var lotNumberField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Numéro de lot")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.AppGradients.accent)
            
            HStack(spacing: 8) {
                TextField("LOT1234", text: $viewModel.lotNumber)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Numéro de lot")
                
                scannerButton
                generateButton
            }
        }
    }
    
    private var scannerButton: some View {
        Button {
            print("🔍 UI: Bouton scanner tapé")
            print("🔍 UI: État scanner: \(viewModel.isShowingScanner), État générateur: \(viewModel.isGeneratingLot)")
            Task { @MainActor in
                viewModel.showScanner()
            }
        } label: {
            Text("📷")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(scannerButtonColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.borderless)
        .disabled(viewModel.isShowingScanner || viewModel.isGeneratingLot) // Désactiver pendant génération
    }
    
    private var generateButton: some View {
        Button {
            print("🎲 UI: Bouton générateur tapé")
            print("🎲 UI: État scanner: \(viewModel.isShowingScanner), État générateur: \(viewModel.isGeneratingLot)")
            viewModel.generateRandomLotNumber() // Pas de Task car déjà géré dans le ViewModel
        } label: {
            HStack(spacing: 4) {
                if viewModel.isGeneratingLot {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                } else {
                    Text("🎲")
                        .font(.title2)
                }
            }
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(generateButtonColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.borderless)
        .disabled(viewModel.isGeneratingLot || viewModel.isShowingScanner) // Protection croisée
    }
    
    // MARK: - Button Colors
    private var scannerButtonColor: Color {
        if viewModel.isShowingScanner || viewModel.isGeneratingLot {
            return Color.blue.opacity(0.5)
        }
        return Color.blue
    }
    
    private var generateButtonColor: Color {
        if viewModel.isGeneratingLot || viewModel.isShowingScanner {
            return Color.green.opacity(0.5)
        }
        return Color.green
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

// MARK: - Validation Errors Section
struct ValidationErrorsSection: View {
    let viewModel: AddProductViewModel
    
    var body: some View {
        if viewModel.hasValidationErrors {
            Section {
                VStack(spacing: 12) {
                    sectionHeader
                    errorsList
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(sectionBackground)
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.AppGradients.error)
                .font(.title2)
            
            Text("Erreurs à corriger")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.AppGradients.error)
            
            Spacer()
        }
    }
    
    private var errorsList: some View {
        ForEach(viewModel.validationErrors, id: \.localizedDescription) { error in
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                
                Text(error.localizedDescription)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.AppGradients.error)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(errorBackground)
        }
    }
    
    private var errorBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.AppGradients.error.opacity(0.1))
            .stroke(Color.AppGradients.error, lineWidth: 1)
    }
    
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .stroke(Color.AppGradients.error.opacity(0.5), lineWidth: 1)
    }
}