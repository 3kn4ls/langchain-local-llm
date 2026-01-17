import { ChatRequest, ChatResponse, ModelInfo } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'api';
const API_KEY = import.meta.env.VITE_API_KEY || '';

const getHeaders = (extraHeaders: Record<string, string> = {}) => {
  const headers: Record<string, string> = {
    ...extraHeaders,
  };
  if (API_KEY) {
    headers['X-API-KEY'] = API_KEY;
  }
  return headers;
};

export const api = {
  async getModels(): Promise<ModelInfo[]> {
    const response = await fetch(`${API_BASE_URL}/models`, {
      headers: getHeaders(),
    });
    if (!response.ok) {
      throw new Error('Failed to fetch models');
    }
    const data = await response.json();
    return data.models || [];
  },

  async chat(request: ChatRequest): Promise<ChatResponse> {
    const response = await fetch(`${API_BASE_URL}/chat`, {
      method: 'POST',
      headers: getHeaders({
        'Content-Type': 'application/json',
      }),
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error('Failed to send message');
    }

    return response.json();
  },

  async *chatStream(request: ChatRequest): AsyncGenerator<string, void, unknown> {
    const response = await fetch(`${API_BASE_URL}/chat/stream`, {
      method: 'POST',
      headers: getHeaders({
        'Content-Type': 'application/json',
      }),
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error('Failed to start stream');
    }

    const reader = response.body?.getReader();
    if (!reader) {
      throw new Error('No reader available');
    }

    const decoder = new TextDecoder();

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value, { stream: true });

        // Si el servidor envía SSE events
        if (chunk.startsWith('data: ')) {
          const lines = chunk.split('\n');
          for (const line of lines) {
            if (line.startsWith('data: ')) {
              const data = line.slice(6);
              if (data === '[DONE]') return;
              yield data;
            }
          }
        } else {
          // Stream de texto plano
          yield chunk;
        }
      }
    } finally {
      reader.releaseLock();
    }
  },

  async ingest(file: File, embeddingModel?: string): Promise<any> {
    const formData = new FormData();
    formData.append('file', file);
    if (embeddingModel) {
      formData.append('embedding_model', embeddingModel);
    }

    const response = await fetch(`${API_BASE_URL}/ingest`, {
      method: 'POST',
      headers: getHeaders(),
      body: formData,
    });

    if (!response.ok) {
      throw new Error('Upload failed');
    }

    return response.json();
  },

  async getDocuments(embeddingModel?: string): Promise<{ documents: string[] }> {
    const query = embeddingModel ? `?embedding_model=${embeddingModel}` : '';
    const response = await fetch(`${API_BASE_URL}/documents${query}`, {
      headers: getHeaders(),
    });
    if (!response.ok) {
      throw new Error('Failed to fetch documents');
    }
    return response.json();
  },

  async deleteDocument(filename: string, embeddingModel?: string): Promise<any> {
    const query = embeddingModel ? `?embedding_model=${embeddingModel}` : '';
    const response = await fetch(`${API_BASE_URL}/documents/${filename}${query}`, {
      method: 'DELETE',
      headers: getHeaders(),
    });
    if (!response.ok) {
      throw new Error('Failed to delete document');
    }
    return response.json();
  },

  async clearDocuments(embeddingModel?: string): Promise<any> {
    const query = embeddingModel ? `?embedding_model=${embeddingModel}` : '';
    const response = await fetch(`${API_BASE_URL}/documents${query}`, {
      method: 'DELETE',
      headers: getHeaders(),
    });
    if (!response.ok) {
      throw new Error('Failed to clear documents');
    }
    return response.json();
  },
};
