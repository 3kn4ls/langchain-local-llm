import { useState, useEffect } from 'react';
import { ChatWindow } from './components/ChatWindow';
import { ConversationList } from './components/ConversationList';
import { KnowledgeBaseView } from './components/KnowledgeBaseView';
import { useChat } from './hooks/useChat';
import { storage } from './utils/storage';
import { Conversation, ChatSettings } from './types';

function App() {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [currentConversationId, setCurrentConversationId] = useState<string | null>(null);
  const [currentView, setCurrentView] = useState<'chat' | 'knowledge'>('chat');
  const [settings, setSettings] = useState<ChatSettings>(() => storage.getSettings());
  const [showSidebar, setShowSidebar] = useState(true);
  const [isMobile, setIsMobile] = useState(false);

  const {
    messages,
    isLoading,
    isStreaming,
    sendMessage,
    stopGeneration,
    regenerateLastMessage,
    clearMessages,
    setMessages,
  } = useChat(settings);

  // Mobile detection
  useEffect(() => {
    const checkMobile = () => {
      const mobile = window.innerWidth < 768; // md breakpoint
      setIsMobile(mobile);
      if (mobile) setShowSidebar(false); // Default closed on mobile
      else setShowSidebar(true); // Default open on desktop
    };

    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  useEffect(() => {
    const savedConversations = storage.getConversations();
    setConversations(savedConversations);
    if (savedConversations.length > 0) {
      const latest = savedConversations[0];
      setCurrentConversationId(latest.id);
      setMessages(latest.messages);
    }
  }, []);

  useEffect(() => {
    storage.saveSettings(settings);
  }, [settings]);

  useEffect(() => {
    if (currentConversationId && messages.length > 0) {
      saveCurrentConversation();
    }
  }, [messages]);

  const saveCurrentConversation = () => {
    if (!currentConversationId) return;

    const updatedConversations = conversations.map((conv) =>
      conv.id === currentConversationId
        ? {
          ...conv,
          messages,
          updatedAt: Date.now(),
          title: messages[0]?.content.slice(0, 50) || 'Nueva conversación',
        }
        : conv
    );

    setConversations(updatedConversations);
    storage.saveConversations(updatedConversations);
  };

  const handleNewConversation = () => {
    if (messages.length > 0 && currentConversationId) {
      saveCurrentConversation();
    }

    const newConversation: Conversation = {
      id: Date.now().toString(),
      title: 'Nueva conversación',
      messages: [],
      model: settings.model,
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };

    const updatedConversations = [newConversation, ...conversations];
    setConversations(updatedConversations);
    storage.saveConversations(updatedConversations);
    setCurrentConversationId(newConversation.id);
    clearMessages();
    if (isMobile) setShowSidebar(false);
  };

  const handleSelectConversation = (id: string) => {
    if (currentConversationId && messages.length > 0) {
      saveCurrentConversation();
    }

    const conversation = conversations.find((conv) => conv.id === id);
    if (conversation) {
      setCurrentConversationId(id);
      setMessages(conversation.messages);
    }
    if (isMobile) setShowSidebar(false);
  };

  const handleDeleteConversation = (id: string) => {
    const updatedConversations = conversations.filter((conv) => conv.id !== id);
    setConversations(updatedConversations);
    storage.saveConversations(updatedConversations);

    if (currentConversationId === id) {
      if (updatedConversations.length > 0) {
        const next = updatedConversations[0];
        setCurrentConversationId(next.id);
        setMessages(next.messages);
      } else {
        setCurrentConversationId(null);
        clearMessages();
      }
    }
  };

  const handleSendMessage = (content: string) => {
    if (!currentConversationId) {
      handleNewConversation();
    }
    sendMessage(content);
  };

  return (
    <div className="flex h-screen bg-gemini-bg text-gemini-text-primary overflow-hidden relative">
      {/* Mobile Backdrop */}
      {isMobile && showSidebar && (
        <div
          className="fixed inset-0 bg-black/60 z-30 backdrop-blur-sm transition-opacity animate-fade-in"
          onClick={() => setShowSidebar(false)}
        />
      )}

      {/* Sidebar - Responsive Logic */}
      <div className={`
        transition-all duration-300 ease-in-out overflow-hidden flex-shrink-0 z-40
        ${isMobile
          ? 'fixed inset-y-0 left-0 h-full w-[280px] shadow-2xl'
          : 'relative h-full'
        }
        ${showSidebar
          ? (isMobile ? 'translate-x-0' : 'w-[280px]')
          : (isMobile ? '-translate-x-full' : 'w-0')
        }
      `}>
        <ConversationList
          conversations={conversations}
          currentConversationId={currentConversationId}
          currentView={currentView}
          onSelectConversation={handleSelectConversation}
          onNewConversation={handleNewConversation}
          onDeleteConversation={handleDeleteConversation}
          onViewChange={setCurrentView}
        />
      </div>

      <div className="flex-1 flex flex-col relative w-full h-full max-w-full min-w-0">
        {/* Toggle Button */}
        <button
          onClick={() => setShowSidebar(!showSidebar)}
          className={`absolute top-4 left-4 z-20 
            ${showSidebar && !isMobile ? 'opacity-0 pointer-events-none' : 'opacity-100'}
            p-2 text-gemini-text-secondary hover:text-gemini-text-primary hover:bg-gemini-hover rounded-full transition-all`}
          aria-label="Toggle sidebar"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>

        {currentView === 'chat' ? (
          <ChatWindow
            messages={messages}
            isLoading={isLoading}
            isStreaming={isStreaming}
            settings={settings}
            onSendMessage={handleSendMessage}
            onStopGeneration={stopGeneration}
            onRegenerateLastMessage={regenerateLastMessage}
            onClearMessages={clearMessages}
            onSettingsChange={setSettings}
          />
        ) : (
          <div className="flex-1 bg-gemini-bg overflow-hidden relative">
            <KnowledgeBaseView />
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
