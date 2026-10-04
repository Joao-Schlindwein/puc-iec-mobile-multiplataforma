// src/services/api.ts
//
// CAMADA SERVICES — somente comunicação HTTP.
// Não conhece cache, não conhece estado da aplicação.
//
// "Como falar com o backend"
//
// Doc axios: https://axios-http.com/
// Token TMDB: gerar em https://www.themoviedb.org/settings/api

import axios from 'axios';

const TOKEN = process.env.EXPO_PUBLIC_TMDB_TOKEN;

// Detecta token ausente, vazio, placeholder ou dummy de teste.
export const isTokenMissing = (() => {
  if (!TOKEN) return true;
  const t = TOKEN.trim();
  if (t.length < 20) return true;
  if (t === 'cole_seu_token_aqui') return true;
  if (t.startsWith('dummy')) return true;
  return false;
})();

// TMDB API key v3 (32 chars hex) usa query param ?api_key=.
// API Read Access Token v4 (JWT longo eyJhbGc...) usa Authorization: Bearer.
const isV4Token = TOKEN ? TOKEN.startsWith('eyJ') : false;

export const api = axios.create({
  baseURL: 'https://api.themoviedb.org/3',
  timeout: 10000,
});

// Interceptor: adiciona Bearer token + idioma em toda request.
api.interceptors.request.use((config) => {
  if (isTokenMissing) {
    return Promise.reject(
      new Error('TMDB_TOKEN_MISSING: configure EXPO_PUBLIC_TMDB_TOKEN no .env')
    );
  }
  const baseParams = { language: 'pt-BR', ...(config.params || {}) };
  if (isV4Token) {
    config.headers.Authorization = `Bearer ${TOKEN}`;
    config.params = baseParams;
  } else {
    // v3 API key — usa query param ?api_key=
    config.params = { ...baseParams, api_key: TOKEN };
  }
  return config;
});

// Interceptor: log de erro centralizado.
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err?.response?.status === 401 || err?.message?.startsWith?.('TMDB_TOKEN_MISSING')) {
      // sinaliza erro de auth pro screen tratar com tela amigável
      err.isTokenError = true;
    }
    console.warn('[api] erro:', err?.response?.status ?? err?.message, err?.config?.url);
    return Promise.reject(err);
  }
);

// Helper pra detectar erro de token em qualquer ponto do app.
export const isTokenError = (error: unknown): boolean => {
  if (!error) return false;
  const e = error as { isTokenError?: boolean; response?: { status?: number }; message?: string };
  if (e.isTokenError) return true;
  if (e.response?.status === 401) return true;
  if (e.message?.startsWith?.('TMDB_TOKEN_MISSING')) return true;
  return false;
};
