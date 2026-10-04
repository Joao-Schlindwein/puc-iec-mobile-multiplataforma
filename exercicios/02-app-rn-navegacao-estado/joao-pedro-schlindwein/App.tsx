// App.tsx — root provider tree
//
// Ordem importa:
// 1. QueryClientProvider (server state via TanStack Query)
// 2. ThemeProvider (estado global app via Context)
// 3. NavigationContainer
// 4. RootStack (screens)

import { NavigationContainer } from '@react-navigation/native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { StatusBar } from 'expo-status-bar';
import { ThemeProvider } from '@/contexts/ThemeContext';
import RootStack from '@/routes/RootStack';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60,
      retry: 1,
    },
  },
});

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <NavigationContainer>
          <RootStack />
          <StatusBar style="auto" />
        </NavigationContainer>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
