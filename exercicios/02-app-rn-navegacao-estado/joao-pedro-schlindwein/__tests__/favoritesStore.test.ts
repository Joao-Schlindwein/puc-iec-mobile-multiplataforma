// __tests__/favoritesStore.test.ts
//
// ATIVIDADE 2 — testar useFavoritesStore.
//
// Mínimo 3 testes verdes pra CI passar (somados aos 5 de counterStore = 8 total).

import { useFavoritesStore } from '../src/store/favoritesStore';

describe('favoritesStore', () => {
  beforeEach(() => {
    useFavoritesStore.setState({ ids: [] });
  });

  test('toggle adiciona id se não existe', () => {
    useFavoritesStore.getState().toggle(1);
    expect(useFavoritesStore.getState().ids).toContain(1);
  });

  test('toggle remove id se já existe', () => {
    useFavoritesStore.getState().toggle(1);
    useFavoritesStore.getState().toggle(1);
    expect(useFavoritesStore.getState().ids).not.toContain(1);
  });

  test('isFavorite retorna true após add', () => {
    useFavoritesStore.getState().add(42);
    expect(useFavoritesStore.getState().isFavorite(42)).toBe(true);
  });

  test('remove tira o id da lista', () => {
    useFavoritesStore.getState().add(7);
    useFavoritesStore.getState().remove(7);
    expect(useFavoritesStore.getState().isFavorite(7)).toBe(false);
  });

  test('clear esvazia ids', () => {
    useFavoritesStore.getState().add(1);
    useFavoritesStore.getState().add(2);
    useFavoritesStore.getState().clear();
    expect(useFavoritesStore.getState().ids).toEqual([]);
  });

  test('add não duplica id já existente', () => {
    useFavoritesStore.getState().add(5);
    useFavoritesStore.getState().add(5);
    expect(useFavoritesStore.getState().ids).toEqual([5]);
  });
});
