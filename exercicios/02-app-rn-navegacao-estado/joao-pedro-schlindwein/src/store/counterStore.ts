// src/store/counterStore.ts
//
// HANDS-ON AULA 2 — Passo 3 (Zustand counter)
//
// Doc Zustand: https://github.com/pmndrs/zustand
//
// Conceitos:
// - Store = singleton fora da árvore React
// - Hook gerado pelo create() consumido direto em componentes
// - Sem Provider, sem configureStore (diferente do Redux)

import { create } from 'zustand';

type CounterState = {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
};

export const useCounterStore = create<CounterState>((set) => ({
  count: 0,
  increment: () => set((s) => ({ count: s.count + 1 })),
  decrement: () => set((s) => ({ count: s.count - 1 })),
  reset: () => set({ count: 0 }),
}));
