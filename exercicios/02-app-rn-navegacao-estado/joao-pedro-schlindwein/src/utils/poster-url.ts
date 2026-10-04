// src/utils/poster-url.ts
//
// TMDB serve imagens em CDN separada com paths relativos.
// Esse helper monta URL completa.

export const posterUrl = (
  path: string | null,
  size: 'w185' | 'w342' | 'w500' = 'w342'
) => (path ? `https://image.tmdb.org/t/p/${size}${path}` : null);
