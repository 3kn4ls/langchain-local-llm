import React, { useState, useRef } from 'react';

export const FileUploader: React.FC = () => {
    const [isUploading, setIsUploading] = useState(false);
    const [uploadStatus, setUploadStatus] = useState<string>('');
    const fileInputRef = useRef<HTMLInputElement>(null);

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = e.target.files;
        if (!files || files.length === 0) return;

        const file = files[0];
        await uploadFile(file);
    };

    const uploadFile = async (file: File) => {
        setIsUploading(true);
        setUploadStatus(`Uploading ${file.name}...`);

        const formData = new FormData();
        formData.append('file', file);

        try {
            const response = await fetch('/api/ingest', {
                method: 'POST',
                body: formData,
            });

            if (!response.ok) {
                throw new Error('Upload failed');
            }

            const data = await response.json();
            setUploadStatus(`Success! Added ${data.chunks_added} chunks from ${data.filename}`);

            // Clear after 3 seconds
            setTimeout(() => setUploadStatus(''), 3000);
        } catch (error) {
            console.error('Error uploading file:', error);
            setUploadStatus('Error uploading file. Please try again.');
        } finally {
            setIsUploading(false);
            if (fileInputRef.current) {
                fileInputRef.current.value = '';
            }
        }
    };

    return (
        <div className="p-4 bg-gray-800 rounded-lg border border-gray-700">
            <h3 className="text-sm font-medium text-gray-300 mb-2">Knowledge Base</h3>
            <p className="text-xs text-gray-400 mb-3">
                Upload documents (txt, md, pdf) to add to the context.
            </p>

            <div className="flex flex-col gap-2">
                <input
                    type="file"
                    ref={fileInputRef}
                    onChange={handleFileChange}
                    className="hidden"
                    accept=".txt,.md,.pdf"
                />
                <button
                    onClick={() => fileInputRef.current?.click()}
                    disabled={isUploading}
                    className={`px-3 py-2 rounded-md text-sm font-medium transition-colors ${isUploading
                            ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
                            : 'bg-blue-600 hover:bg-blue-700 text-white'
                        }`}
                >
                    {isUploading ? 'Uploading...' : 'Upload Document'}
                </button>

                {uploadStatus && (
                    <div className={`text-xs mt-1 ${uploadStatus.includes('Error') ? 'text-red-400' : 'text-green-400'
                        }`}>
                        {uploadStatus}
                    </div>
                )}
            </div>
        </div>
    );
};
