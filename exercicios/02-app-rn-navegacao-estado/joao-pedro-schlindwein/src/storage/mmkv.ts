// src/storage/mmkv.ts
//
// ATIVIDADE 2 — TASK 7 (storage síncrono)
//
// MMKV (C++ via JSI) é ~30x mais rápido que AsyncStorage.
// Funciona em iOS/Android nativo. Em web (testes/dev), polyfill com localStorage.
//
// Doc: https://github.com/mrousavy/react-native-mmkv

const isWeb = typeof window !== 'undefined' && typeof window.localStorage !== 'undefined';

let getString: (k: string) => string | undefined;
let setItem: (k: string, v: string) => void;
let deleteItem: (k: string) => void;

if (isWeb) {
  getString = (k) => window.localStorage.getItem(k) ?? undefined;
  setItem = (k, v) => window.localStorage.setItem(k, v);
  deleteItem = (k) => window.localStorage.removeItem(k);
} else {
  const { MMKV } = require('react-native-mmkv');
  const storage = new MMKV({ id: 'favorites-store' });
  getString = (k) => storage.getString(k);
  setItem = (k, v) => storage.set(k, v);
  deleteItem = (k) => storage.delete(k);
}

export const mmkvStorage = {
  getItem: (name: string) => getString(name) ?? null,
  setItem: (name: string, value: string) => setItem(name, value),
  removeItem: (name: string) => deleteItem(name),
};
