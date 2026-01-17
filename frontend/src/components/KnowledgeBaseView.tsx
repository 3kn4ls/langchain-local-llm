import React from 'react';
import { FileUploader } from './FileUploader';
import { ChatSettings } from '../types';
import { api } from '../utils/api';

interface KnowledgeBaseViewProps {
    settings: ChatSettings;
    onSettingsChange: (settings: ChatSettings) => void;
}

export const KnowledgeBaseView: React.FC<KnowledgeBaseViewProps> = ({ settings, onSettingsChange }) => {
    const embeddingModels = [
        { id: 'nomic-embed-text', name: 'Nomic Embed Text (Fast)' },
        { id: 'all-minilm', name: 'All-MiniLM (Lightweight)' },
        { id: 'qwen3-embedding:8b', name: 'Qwen 3 8B (Quality)' },
    ];

    const handleModelChange = (modelId: string) => {
        onSettingsChange({
            ...settings,
            embedding_model: modelId
        });
    };

    const [documents, setDocuments] = React.useState<string[]>([]);
    const [isLoadingDocs, setIsLoadingDocs] = React.useState(false);

    const fetchDocuments = React.useCallback(async () => {
        setIsLoadingDocs(true);
        try {
            const data = await api.getDocuments(settings.embedding_model);
            setDocuments(data.documents);
        } catch (error) {
            console.error('Error fetching documents:', error);
        } finally {
            setIsLoadingDocs(false);
        }
    }, [settings.embedding_model]);

    React.useEffect(() => {
        fetchDocuments();
    }, [fetchDocuments]);

    const handleDeleteDocument = async (filename: string) => {
        if (!confirm(`Are you sure you want to delete ${filename}?`)) return;

        try {
            await api.deleteDocument(filename, settings.embedding_model);
            fetchDocuments();
        } catch (error) {
            console.error('Error deleting document:', error);
            alert('Failed to delete document');
        }
    };

    const handleClearAll = async () => {
        if (!confirm('Are you sure you want to CLEAR ALL documents for this model? This cannot be undone.')) return;

        try {
            await api.clearDocuments(settings.embedding_model);
            fetchDocuments();
        } catch (error) {
            console.error('Error clearing documents:', error);
            alert('Failed to clear database');
        }
    };

    return (
        <div className="flex flex-col h-full bg-gemini-bg p-8 overflow-y-auto scrollbar-thin scrollbar-thumb-gemini-border">
            <header className="mb-8 max-w-4xl mx-auto w-full">
                <div className="flex items-center gap-3 mb-2">
                    <div className="p-2 bg-purple-500/10 rounded-lg">
                        <svg className="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                        </svg>
                    </div>
                    <h1 className="text-2xl font-bold text-gemini-text-primary">Knowledge Base</h1>
                </div>
                <p className="text-gemini-text-secondary text-sm max-w-2xl pl-12">
                    Manage context documents. Upload PDF, Markdown, or TXT files to ingest them into the vector database for Retrieval-Augmented Generation (RAG).
                </p>
            </header>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 max-w-4xl mx-auto w-full">
                {/* Left Column: Actions */}
                <div className="space-y-8">
                    {/* Upload Section */}
                    <div className="bg-gemini-surface rounded-2xl border border-gemini-border p-6 shadow-sm hover:shadow-md transition-shadow">
                        <h2 className="text-lg font-semibold text-gemini-text-primary mb-4 flex items-center gap-2">
                            <svg className="w-5 h-5 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                            </svg>
                            Ingest Documents
                        </h2>

                        <div className="mb-6">
                            <label className="block text-xs font-semibold text-gemini-text-secondary uppercase tracking-wider mb-2">
                                Select Embedding Model
                            </label>
                            <select
                                value={settings.embedding_model}
                                onChange={(e) => handleModelChange(e.target.value)}
                                className="w-full bg-gemini-bg border border-gemini-border rounded-xl px-4 py-2 text-gemini-text-primary focus:outline-none focus:ring-2 focus:ring-purple-500/50 transition-all text-sm appearance-none cursor-pointer"
                            >
                                {embeddingModels.map(m => (
                                    <option key={m.id} value={m.id}>{m.name}</option>
                                ))}
                            </select>
                        </div>

                        <p className="text-gemini-text-secondary text-sm mb-6">
                            Stored in ChromaDB using <span className="text-purple-400 font-mono">{settings.embedding_model}</span>.
                        </p>

                        <div className="bg-gemini-bg/50 rounded-xl p-4 border border-gemini-border border-dashed">
                            <FileUploader
                                embeddingModel={settings.embedding_model}
                                onUploadSuccess={fetchDocuments}
                            />
                        </div>
                    </div>

                    {/* How RAG Works */}
                    <div className="bg-gemini-surface rounded-2xl border border-gemini-border p-6 shadow-sm">
                        <h2 className="text-lg font-semibold text-gemini-text-primary mb-4 flex items-center gap-2">
                            <svg className="w-5 h-5 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            RAG Overview
                        </h2>
                        <div className="space-y-3 text-xs text-gemini-text-secondary">
                            <p><span className="font-semibold text-gemini-text-primary">Ingest:</span> Splits docs into overlapping chunks.</p>
                            <p><span className="font-semibold text-gemini-text-primary">Embedding:</span> Converts text to high-dimensional vectors.</p>
                            <p><span className="font-semibold text-gemini-text-primary">Retrieve:</span> Finds relevant context for your queries.</p>
                        </div>
                    </div>
                </div>

                {/* Right Column: Ingested Documents */}
                <div className="bg-gemini-surface rounded-2xl border border-gemini-border flex flex-col shadow-sm">
                    <div className="p-6 border-b border-gemini-border flex items-center justify-between">
                        <h2 className="text-lg font-semibold text-gemini-text-primary flex items-center gap-2">
                            <svg className="w-5 h-5 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                            </svg>
                            Ingested Files
                        </h2>
                        {documents.length > 0 && (
                            <button
                                onClick={handleClearAll}
                                className="text-xs text-red-500 hover:text-red-400 transition-colors font-medium border border-red-500/20 px-2 py-1 rounded-lg hover:bg-red-500/10"
                            >
                                Clear All
                            </button>
                        )}
                    </div>

                    <div className="flex-1 overflow-y-auto max-h-[500px] scrollbar-thin scrollbar-thumb-gemini-border p-2">
                        {isLoadingDocs ? (
                            <div className="flex items-center justify-center py-8">
                                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-purple-500"></div>
                            </div>
                        ) : documents.length === 0 ? (
                            <div className="flex flex-col items-center justify-center py-12 text-gemini-text-secondary">
                                <svg className="w-12 h-12 mb-3 opacity-20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                                </svg>
                                <p className="text-sm">No documents found</p>
                            </div>
                        ) : (
                            <div className="space-y-1">
                                {documents.map((doc, idx) => (
                                    <div key={idx} className="group flex items-center justify-between p-3 rounded-xl hover:bg-gemini-hover transition-all">
                                        <div className="flex items-center gap-3 min-w-0">
                                            <div className="p-1.5 bg-gemini-bg rounded-lg border border-gemini-border">
                                                <svg className="w-4 h-4 text-gemini-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                                                </svg>
                                            </div>
                                            <span className="text-sm text-gemini-text-primary truncate font-medium">
                                                {doc}
                                            </span>
                                        </div>
                                        <button
                                            onClick={() => handleDeleteDocument(doc)}
                                            className="opacity-0 group-hover:opacity-100 p-2 text-gemini-text-secondary hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-all"
                                            title="Delete document"
                                        >
                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                            </svg>
                                        </button>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};
