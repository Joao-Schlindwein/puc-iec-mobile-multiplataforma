// src/components/UpdatePrompt.tsx
// Avisos do Service Worker (registerType: 'prompt'):
//   - offlineReady → "App pronto para uso offline" (dispensável)
//   - needRefresh  → "Nova versão disponível" com Atualizar / Depois
// Só aparece no BUILD (npm run build && npm run preview).

import { useRegisterSW } from 'virtual:pwa-register/react';

const toastStyle: React.CSSProperties = {
  position: 'fixed',
  left: 16,
  right: 16,
  bottom: 80,
  zIndex: 1000,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
  gap: 12,
  maxWidth: 480,
  margin: '0 auto',
  padding: '12px 16px',
  background: '#01b4e4',
  color: '#0d253f',
  borderRadius: 10,
  boxShadow: '0 4px 16px rgba(0, 0, 0, 0.35)',
  fontSize: 14,
  fontWeight: 600,
};

const btnStyle: React.CSSProperties = {
  background: '#0d253f',
  color: '#01b4e4',
  border: 'none',
  borderRadius: 6,
  padding: '6px 14px',
  fontWeight: 700,
  cursor: 'pointer',
  fontSize: 13,
  whiteSpace: 'nowrap',
};

const ghostBtnStyle: React.CSSProperties = {
  ...btnStyle,
  background: 'transparent',
  color: '#0d253f',
  border: '1px solid #0d253f',
};

export function UpdatePrompt() {
  const {
    offlineReady: [offlineReady, setOfflineReady],
    needRefresh: [needRefresh, setNeedRefresh],
    updateServiceWorker,
  } = useRegisterSW();

  if (needRefresh) {
    return (
      <div role="alert" style={toastStyle}>
        <span>🔄 Nova versão disponível</span>
        <span style={{ display: 'flex', gap: 8 }}>
          <button onClick={() => updateServiceWorker(true)} style={btnStyle}>Atualizar</button>
          <button onClick={() => setNeedRefresh(false)} style={ghostBtnStyle}>Depois</button>
        </span>
      </div>
    );
  }

  if (offlineReady) {
    return (
      <div role="status" style={toastStyle}>
        <span>✅ App pronto para uso offline</span>
        <button onClick={() => setOfflineReady(false)} style={btnStyle}>OK</button>
      </div>
    );
  }

  return null;
}
