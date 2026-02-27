import SwiftUI
import SwiftData

struct PDFSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: LibraryViewModel
    @State private var searchText = ""
    @State private var selectedResult: ExaResult?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Search for PDFs...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .onSubmit {
                            viewModel.searchPDFs(query: searchText)
                        }
                    
                    Button("Search") {
                        viewModel.searchPDFs(query: searchText)
                    }
                    .disabled(searchText.isEmpty || viewModel.isSearching)
                    .padding(.trailing)
                }
                .padding(.top)
                
                if viewModel.isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView("No PDFs Found", systemImage: "magnifyingglass", description: Text("Try a different search term."))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.searchResults) { result in
                                Button {
                                    selectedResult = result
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(result.title ?? "Untitled PDF")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                        
                                        Text(result.url)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(.rect(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Search PDFs")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedResult) { result in
                if let url = URL(string: result.url) {
                    PDFPreviewView(url: url) {
                        viewModel.importFromURL(url, modelContext: modelContext)
                        dismiss() // Dismiss the search view after selection
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
