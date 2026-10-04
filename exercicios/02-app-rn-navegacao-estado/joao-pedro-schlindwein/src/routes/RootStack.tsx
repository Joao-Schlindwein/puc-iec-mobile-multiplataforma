// src/routes/RootStack.tsx
//
// CAMADA ROUTES — navegação do app.
// Doc: https://reactnavigation.org/docs/native-stack-navigator
// Doc: https://reactnavigation.org/docs/bottom-tab-navigator
//
// BÔNUS — Bottom Tabs (Filmes / Favoritos), cada aba com seu próprio
// stack interno pra chegar em Detail a partir de qualquer uma.

import { Text } from 'react-native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import MovieList from '@/screens/MovieList';
import MovieDetail from '@/screens/MovieDetail';
import FavoritesList from '@/screens/FavoritesList';

export type MoviesStackParamList = {
  Home: undefined;
  Detail: { id: number; title: string };
};

export type FavoritesStackParamList = {
  Favorites: undefined;
  Detail: { id: number; title: string };
};

export type RootTabParamList = {
  MoviesTab: undefined;
  FavoritesTab: undefined;
};

// Compatibilidade com código existente que importa RootStackParamList
// (MovieCard, MovieDetail navegam pra "Detail" a partir de qualquer stack).
export type RootStackParamList = MoviesStackParamList & FavoritesStackParamList;

const stackScreenOptions = {
  headerBackVisible: true,
  headerBackTitle: 'Voltar',
};

const MoviesStack = createNativeStackNavigator<MoviesStackParamList>();
function MoviesStackNavigator() {
  return (
    <MoviesStack.Navigator screenOptions={stackScreenOptions}>
      <MoviesStack.Screen name="Home" component={MovieList} options={{ title: 'Filmes' }} />
      <MoviesStack.Screen
        name="Detail"
        component={MovieDetail}
        options={({ route }) => ({ title: route.params.title, headerBackTitle: 'Voltar' })}
      />
    </MoviesStack.Navigator>
  );
}

const FavoritesStack = createNativeStackNavigator<FavoritesStackParamList>();
function FavoritesStackNavigator() {
  return (
    <FavoritesStack.Navigator screenOptions={stackScreenOptions}>
      <FavoritesStack.Screen
        name="Favorites"
        component={FavoritesList}
        options={{ title: 'Favoritos' }}
      />
      <FavoritesStack.Screen
        name="Detail"
        component={MovieDetail}
        options={({ route }) => ({ title: route.params.title, headerBackTitle: 'Voltar' })}
      />
    </FavoritesStack.Navigator>
  );
}

const Tab = createBottomTabNavigator<RootTabParamList>();

export default function RootStack() {
  return (
    <Tab.Navigator screenOptions={{ headerShown: false }}>
      <Tab.Screen
        name="MoviesTab"
        component={MoviesStackNavigator}
        options={{
          title: 'Filmes',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 20, color }}>🎬</Text>,
        }}
      />
      <Tab.Screen
        name="FavoritesTab"
        component={FavoritesStackNavigator}
        options={{
          title: 'Favoritos',
          tabBarIcon: ({ color }) => <Text style={{ fontSize: 20, color }}>❤️</Text>,
        }}
      />
    </Tab.Navigator>
  );
}
