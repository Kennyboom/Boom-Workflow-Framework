---
name: react-native-expert
description: Build production-grade cross-platform mobile apps with React Native, Expo, and TypeScript. Covers Expo Router, NativeWind, state management, native modules, offline-first patterns, and EAS deployment.
---

# React Native Expert

Expert guidance for building cross-platform mobile applications with React Native and Expo SDK 52+.

## When to Use

- Building mobile apps with React Native / Expo
- Cross-platform iOS + Android development
- Expo Router navigation setup
- Styling with NativeWind or StyleSheet
- EAS Build, Submit, and OTA updates

---

## 1. Project Structure (Expo Router)

```
app/
├── _layout.tsx          # Root layout (providers, fonts, splash)
├── (tabs)/
│   ├── _layout.tsx      # Tab navigator
│   ├── index.tsx        # Home tab
│   ├── explore.tsx      # Explore tab
│   └── profile.tsx      # Profile tab
├── (auth)/
│   ├── _layout.tsx      # Auth stack (no tabs)
│   ├── login.tsx
│   └── register.tsx
├── [id].tsx             # Dynamic route
├── modal.tsx            # Modal presentation
└── +not-found.tsx       # 404 screen
components/
├── ui/                  # Reusable primitives
└── features/            # Feature-specific
hooks/
lib/
├── api.ts               # API client (axios/fetch)
├── storage.ts           # MMKV / AsyncStorage wrapper
└── constants.ts
stores/                  # Zustand stores
types/
```

## 2. Navigation (Expo Router)

### Root Layout with Providers
```tsx
// app/_layout.tsx
import { Stack } from 'expo-router';
import { QueryClientProvider, QueryClient } from '@tanstack/react-query';
import { ThemeProvider } from '@/lib/theme';

const queryClient = new QueryClient();

export default function RootLayout() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <Stack>
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          <Stack.Screen name="(auth)" options={{ headerShown: false }} />
          <Stack.Screen name="modal" options={{ presentation: 'modal' }} />
        </Stack>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
```

### Tab Navigator
```tsx
// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function TabLayout() {
  return (
    <Tabs screenOptions={{ tabBarActiveTintColor: '#007AFF' }}>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home" size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
```

### Deep Linking & Type-Safe Navigation
```tsx
import { useRouter, useLocalSearchParams, Link } from 'expo-router';

// Programmatic navigation
const router = useRouter();
router.push('/profile/123');
router.replace('/(auth)/login');
router.back();

// Type-safe params
const { id } = useLocalSearchParams<{ id: string }>();

// Declarative link
<Link href={{ pathname: '/[id]', params: { id: '123' } }}>Details</Link>
```

## 3. Styling

### NativeWind v4 (Tailwind for RN)
```tsx
import { View, Text, Pressable } from 'react-native';

export function Card({ title, onPress }: CardProps) {
  return (
    <Pressable
      onPress={onPress}
      className="bg-white dark:bg-gray-800 rounded-2xl p-4 shadow-md
                 active:scale-95 transition-transform"
    >
      <Text className="text-lg font-semibold text-gray-900 dark:text-white">
        {title}
      </Text>
    </Pressable>
  );
}
```

### StyleSheet (When Needed)
```tsx
import { StyleSheet, Platform } from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: Platform.OS === 'ios' ? 44 : 0,
  },
  shadow: Platform.select({
    ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 2 },
           shadowOpacity: 0.1, shadowRadius: 4 },
    android: { elevation: 4 },
  }),
});
```

## 4. State Management

### Zustand (Recommended)
```tsx
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { zustandStorage } from '@/lib/storage'; // MMKV adapter

interface AuthStore {
  token: string | null;
  user: User | null;
  login: (token: string, user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      login: (token, user) => set({ token, user }),
      logout: () => set({ token: null, user: null }),
    }),
    { name: 'auth-store', storage: createJSONStorage(() => zustandStorage) }
  )
);
```

### TanStack Query (Server State)
```tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

export function useProducts() {
  return useQuery({
    queryKey: ['products'],
    queryFn: () => api.get<Product[]>('/products'),
    staleTime: 5 * 60 * 1000,
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateProductDTO) => api.post('/products', data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['products'] }),
  });
}
```

## 5. Performance Optimization

### FlatList Best Practices
```tsx
<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <MemoizedCard item={item} />}
  getItemLayout={(_, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
  maxToRenderPerBatch={10}
  windowSize={5}
  removeClippedSubviews={true}
  initialNumToRender={10}
/>
```

### Memoization
```tsx
import { memo, useCallback, useMemo } from 'react';

const MemoizedCard = memo(({ item, onPress }: Props) => {
  return <Pressable onPress={() => onPress(item.id)}>...</Pressable>;
});

// In parent
const handlePress = useCallback((id: string) => {
  router.push(`/details/${id}`);
}, [router]);

const sortedItems = useMemo(
  () => items.sort((a, b) => b.date - a.date),
  [items]
);
```

### Image Optimization
```tsx
import { Image } from 'expo-image';

<Image
  source={{ uri: imageUrl }}
  style={{ width: 200, height: 200 }}
  contentFit="cover"
  placeholder={blurhash}
  transition={200}
  cachePolicy="memory-disk"
/>
```

## 6. Offline-First Patterns

### MMKV Storage (Fast KV Store)
```tsx
import { MMKV } from 'react-native-mmkv';

export const storage = new MMKV();

export const mmkvStorage = {
  getItem: (key: string) => storage.getString(key) ?? null,
  setItem: (key: string, value: string) => storage.set(key, value),
  removeItem: (key: string) => storage.delete(key),
};
```

### Optimistic Updates with TanStack Query
```tsx
useMutation({
  mutationFn: updateTodo,
  onMutate: async (newTodo) => {
    await queryClient.cancelQueries({ queryKey: ['todos'] });
    const previous = queryClient.getQueryData(['todos']);
    queryClient.setQueryData(['todos'], (old: Todo[]) =>
      old.map(t => t.id === newTodo.id ? { ...t, ...newTodo } : t)
    );
    return { previous };
  },
  onError: (err, _, context) => {
    queryClient.setQueryData(['todos'], context?.previous);
  },
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['todos'] }),
});
```

## 7. Native Modules & Expo SDK

### Common Expo Packages
```bash
npx expo install expo-camera expo-image-picker expo-location
npx expo install expo-notifications expo-secure-store
npx expo install expo-haptics expo-local-authentication
npx expo install expo-file-system expo-sharing
```

### Expo SecureStore (Sensitive Data)
```tsx
import * as SecureStore from 'expo-secure-store';

await SecureStore.setItemAsync('auth_token', token);
const token = await SecureStore.getItemAsync('auth_token');
await SecureStore.deleteItemAsync('auth_token');
```

### Push Notifications
```tsx
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';

async function registerForPush(): Promise<string | undefined> {
  if (!Device.isDevice) return;
  const { status } = await Notifications.requestPermissionsAsync();
  if (status !== 'granted') return;
  const token = await Notifications.getExpoPushTokenAsync({
    projectId: Constants.expoConfig?.extra?.eas?.projectId,
  });
  return token.data;
}
```

## 8. EAS Build & Deploy

### Configuration (eas.json)
```json
{
  "cli": { "version": ">= 12.0.0" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal",
      "ios": { "simulator": false }
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {
      "ios": { "appleId": "your@email.com", "ascAppId": "123456789" },
      "android": { "serviceAccountKeyPath": "./google-sa.json" }
    }
  }
}
```

### CLI Commands
```bash
# Build
eas build --platform ios --profile production
eas build --platform android --profile production

# Submit to stores
eas submit --platform ios --latest
eas submit --platform android --latest

# OTA update (no store review!)
eas update --branch production --message "Bug fix"
```

## 9. TypeScript Patterns

### Strict Configuration
```json
// tsconfig.json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "paths": { "@/*": ["./*"] }
  }
}
```

### API Response Types
```tsx
interface ApiResponse<T> {
  data: T;
  meta: { page: number; total: number };
}

type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };
```

## 10. Best Practices

- **Hermes engine**: Enabled by default in Expo SDK 50+, improves startup time
- **New Architecture**: Enable Fabric & TurboModules for better performance
- **expo-image** over Image: Built-in caching, blurhash, transitions
- **MMKV** over AsyncStorage: 30x faster for key-value storage
- **Reanimated** for animations: Runs on UI thread, 60fps guaranteed
- **expo-router** over React Navigation: File-based routing, deep linking, type safety
- **Zustand** over Redux: Less boilerplate, better DX, middleware support
- **env vars**: Use `expo-constants` + `eas.json`, never hardcode secrets
