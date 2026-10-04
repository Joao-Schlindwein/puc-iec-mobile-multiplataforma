// src/contexts/ThemeContext.tsx
//
// CAMADA CONTEXTS — estado GLOBAL da aplicação.
// "Como compartilhar estado global da aplicação"
//
// Use Context API pra:
// - usuário logado / token
// - tema (dark/light)
// - idioma
// - permissões
//
// NÃO use Context pra dados do servidor (filmes, posts) — isso é
// responsabilidade do TanStack Query (camada queries/).

import { createContext, useContext, useState, ReactNode } from 'react';

type Theme = 'light' | 'dark';

type ThemeContextData = {
  theme: Theme;
  toggle: () => void;
};

const ThemeContext = createContext({} as ThemeContextData);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('light');

  const toggle = () => setTheme((t) => (t === 'light' ? 'dark' : 'light'));

  return <ThemeContext.Provider value={{ theme, toggle }}>{children}</ThemeContext.Provider>;
}

export const useTheme = () => useContext(ThemeContext);
