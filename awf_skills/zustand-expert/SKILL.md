---
name: zustand-expert
description: Advanced Zustand state management — sliced stores, Immer middleware, persist, devtools, IPC sync with Tauri backend, selector optimization, TypeScript patterns. For large-scale React + Tauri desktop apps.
---

# Zustand Expert — State Management

Use this skill for frontend state management in React + Tauri desktop applications.

---

## 1. Store Architecture (Sliced Pattern)

```typescript
import { create } from 'zustand';
import { devtools, persist, immer } from 'zustand/middleware';

// Slice: Auth
interface AuthSlice {
  user: User | null;
  isAuthenticated: boolean;
  login: (credentials: Credentials) => Promise<void>;
  logout: () => void;
}

// Slice: Videos
interface VideoSlice {
  videos: Video[];
  selectedId: string | null;
  fetchVideos: () => Promise<void>;
  selectVideo: (id: string) => void;
  deleteVideo: (id: string) => Promise<void>;
}

// Slice: Queue
interface QueueSlice {
  tasks: QueueTask[];
  addTask: (task: NewTask) => Promise<void>;
  updateProgress: (taskId: string, progress: number) => void;
  cancelTask: (taskId: string) => Promise<void>;
}

// Combined Store
type AppStore = AuthSlice & VideoSlice & QueueSlice;
```

---

## 2. Store with Immer + Persist + Devtools

```typescript
import { invoke } from '@tauri-apps/api/core';

export const useAppStore = create<AppStore>()(
  devtools(
    persist(
      immer((set, get) => ({
        // === Auth Slice ===
        user: null,
        isAuthenticated: false,
        login: async (credentials) => {
          const user = await invoke<User>('auth_login', { credentials });
          set((state) => {
            state.user = user;
            state.isAuthenticated = true;
          });
        },
        logout: () => set((state) => {
          state.user = null;
          state.isAuthenticated = false;
        }),

        // === Video Slice ===
        videos: [],
        selectedId: null,
        fetchVideos: async () => {
          const videos = await invoke<Video[]>('video_list', {});
          set((state) => { state.videos = videos; });
        },
        selectVideo: (id) => set((state) => { state.selectedId = id; }),
        deleteVideo: async (id) => {
          await invoke('video_delete', { id });
          set((state) => {
            state.videos = state.videos.filter(v => v.id !== id);
            if (state.selectedId === id) state.selectedId = null;
          });
        },

        // === Queue Slice ===
        tasks: [],
        addTask: async (task) => {
          const created = await invoke<QueueTask>('queue_add', { task });
          set((state) => { state.tasks.push(created); });
        },
        updateProgress: (taskId, progress) => set((state) => {
          const task = state.tasks.find(t => t.id === taskId);
          if (task) task.progress = progress;
        }),
        cancelTask: async (taskId) => {
          await invoke('queue_cancel', { id: taskId });
          set((state) => {
            const task = state.tasks.find(t => t.id === taskId);
            if (task) task.status = 'cancelled';
          });
        },
      })),
      {
        name: 'metagen-store',
        // Only persist non-sensitive slices
        partialize: (state) => ({
          selectedId: state.selectedId,
        }),
      }
    ),
    { name: 'MetaGen Store' }
  )
);
```

---

## 3. IPC Sync — Tauri Events → Zustand

```typescript
import { listen } from '@tauri-apps/api/event';

// Setup global listeners (call once in App.tsx)
export async function setupIPCSync() {
  // Queue progress
  await listen<QueueProgress>('queue:progress', (event) => {
    useAppStore.getState().updateProgress(
      event.payload.taskId,
      event.payload.percent,
    );
  });

  // Queue completed
  await listen<QueueTask>('queue:completed', (event) => {
    useAppStore.setState((state) => {
      const task = state.tasks.find(t => t.id === event.payload.id);
      if (task) {
        task.status = 'completed';
        task.progress = 100;
      }
    });
  });

  // Error events
  await listen<AppError>('error', (event) => {
    useErrorStore.getState().addError(event.payload);
  });
}
```

---

## 4. Selector Optimization

```typescript
import { useShallow } from 'zustand/react/shallow';

// ❌ BAD — rerenders on ANY store change
function VideoList() {
  const store = useAppStore();
  return <div>{store.videos.map(v => <VideoCard key={v.id} video={v} />)}</div>;
}

// ✅ GOOD — only rerenders when videos change
function VideoList() {
  const videos = useAppStore((state) => state.videos);
  return <div>{videos.map(v => <VideoCard key={v.id} video={v} />)}</div>;
}

// ✅ GOOD — multiple values with shallow comparison
function VideoHeader() {
  const { selectedId, videos } = useAppStore(
    useShallow((state) => ({
      selectedId: state.selectedId,
      videos: state.videos,
    }))
  );
  const selected = videos.find(v => v.id === selectedId);
  return <h1>{selected?.title}</h1>;
}

// ✅ GOOD — computed selector
const useSelectedVideo = () =>
  useAppStore((state) =>
    state.videos.find(v => v.id === state.selectedId) ?? null
  );
```

---

## 5. Error Store (Separate)

```typescript
interface ErrorState {
  errors: AppError[];
  addError: (error: AppError) => void;
  dismissError: (code: string) => void;
  clearAll: () => void;
}

export const useErrorStore = create<ErrorState>()(
  immer((set) => ({
    errors: [],
    addError: (error) => {
      set((state) => { state.errors.push(error); });
      // Auto-dismiss info/warning
      if (error.severity === 'info' || error.severity === 'warning') {
        setTimeout(() => {
          useErrorStore.getState().dismissError(error.code);
        }, 5000);
      }
      // Send to Sentry
      if (error.severity === 'error' || error.severity === 'critical') {
        Sentry.captureException(new Error(error.code), { extra: error });
      }
    },
    dismissError: (code) => set((state) => {
      state.errors = state.errors.filter(e => e.code !== code);
    }),
    clearAll: () => set({ errors: [] }),
  }))
);
```

---

## 6. Settings Store (Persisted)

```typescript
interface SettingsState {
  theme: 'dark' | 'light' | 'system';
  language: string;
  defaultResolution: string;
  defaultModel: string;
  autoSaveInterval: number;
  setTheme: (theme: SettingsState['theme']) => void;
  updateSettings: (patch: Partial<SettingsState>) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    immer((set) => ({
      theme: 'dark',
      language: 'vi',
      defaultResolution: '1080p',
      defaultModel: 'veo',
      autoSaveInterval: 30,
      setTheme: (theme) => set({ theme }),
      updateSettings: (patch) => set((state) => ({ ...state, ...patch })),
    })),
    {
      name: 'metagen-settings',
      version: 1,
      // Migration on version bump
      migrate: (persistedState, version) => {
        if (version === 0) {
          return { ...persistedState, autoSaveInterval: 30 };
        }
        return persistedState as SettingsState;
      },
    }
  )
);
```

---

## 7. Best Practices

1. **Slice by domain** — Auth, Videos, Queue, Settings as separate concerns
2. **Immer for nested updates** — `state.tasks[i].progress = 50` just works
3. **Persist only needed data** — use `partialize` to exclude sensitive/large data
4. **Selectors for performance** — never subscribe to entire store
5. **`useShallow`** for multi-value selects — prevents unnecessary rerenders
6. **Separate error store** — errors are cross-cutting, don't mix with domain state
7. **IPC sync in one place** — `setupIPCSync()` called once in App layout
8. **Devtools in dev only** — `devtools(...)` wraps outer layer
9. **TypeScript all stores** — full type safety for state and actions
10. **Computed selectors** — derive values at select time, not in store
