import SwiftUI
import SwiftData
import UniformTypeIdentifiers


struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayerService.self) private var playerService
    @Query(sort: \AudioDocument.dateAdded, order: .forward) private var documents: [AudioDocument]
    @State private var viewModel = LibraryViewModel()


    var body: some View {
        @Bindable var viewModel = viewModel


        NavigationStack {
            Group {
                if viewModel.isImporting {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Importing and Processing PDF...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if documents.isEmpty {
                    VStack {
                        Text("Tap + to add a PDF and convert it to audio")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {
                            ForEach(documents) { document in
                                NavigationLink(value: document.id) {
                                    DocumentCard(document: document) {
                                        viewModel.deleteDocument(document, modelContext: modelContext)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .fileImporter(
                isPresented: $viewModel.showFilePicker,
                allowedContentTypes: [.pdf],
                onCompletion: { result in
                    viewModel.importPDF(from: result, modelContext: modelContext)
                }
            )
            .sheet(isPresented: $viewModel.showSearchView) {
                PDFSearchView(viewModel: viewModel)
            }
            .navigationDestination(for: UUID.self) { id in
                if let document = documents.first(where: { $0.id == id }) {
                    DocumentDetailView(document: document, viewModel: viewModel)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Menu {
                        Button {
                            viewModel.showFilePicker = true
                        } label: {
                            Label("Add from Files", systemImage: "folder")
                        }

                        Button {
                            viewModel.showSearchView = true
                        } label: {
                            Label("Search for PDF", systemImage: "magnifyingglass")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                            .background(.black)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                    .padding(.bottom, 0)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
