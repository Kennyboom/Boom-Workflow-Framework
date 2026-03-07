---
name: crdt-collaboration
description: Real-time collaboration with CRDTs — Yjs for timeline/text sync, shared cursors, offline-first editing, version snapshots, and conflict resolution patterns. For multi-user video editing workspaces.
---

# CRDT Collaboration — Real-time Multi-User Editing

Use this skill for building real-time collaboration features in desktop apps.

---

## 1. Yjs Document Setup

```typescript
import * as Y from 'yjs';
import { WebsocketProvider } from 'y-websocket';

export function createCollabDoc(workspaceId: string) {
  const doc = new Y.Doc();

  // Connect to sync server
  const provider = new WebsocketProvider(
    'wss://collab.metagen.app',
    `workspace-${workspaceId}`,
    doc,
    { connect: true }
  );

  // Awareness (cursors, selections, presence)
  const awareness = provider.awareness;
  awareness.setLocalState({
    user: { name: 'Kelly', color: '#FF6B35' },
    cursor: null,
    selection: null,
    activeElement: null,
  });

  return { doc, provider, awareness };
}
```

---

## 2. Timeline CRDT (Video Editing)

```typescript
// Shared timeline structure
const timeline = doc.getArray<Y.Map<any>>('timeline');

// Add clip to timeline
export function addClip(timeline: Y.Array<Y.Map<any>>, clip: TimelineClip) {
  const clipMap = new Y.Map();
  clipMap.set('id', clip.id);
  clipMap.set('type', clip.type); // 'video' | 'audio' | 'text'
  clipMap.set('track', clip.track);
  clipMap.set('startFrame', clip.startFrame);
  clipMap.set('endFrame', clip.endFrame);
  clipMap.set('sourceUrl', clip.sourceUrl);
  clipMap.set('properties', new Y.Map(Object.entries(clip.properties)));
  timeline.push([clipMap]);
}

// Move clip (atomic operation)
export function moveClip(
  timeline: Y.Array<Y.Map<any>>,
  clipId: string,
  newStart: number,
  newTrack: number,
) {
  doc.transact(() => {
    timeline.forEach((clipMap) => {
      if (clipMap.get('id') === clipId) {
        clipMap.set('startFrame', newStart);
        clipMap.set('track', newTrack);
      }
    });
  });
}

// Observe changes
timeline.observeDeep((events) => {
  events.forEach((event) => {
    if (event.target === timeline) {
      // Clips added/removed
      renderTimeline();
    } else {
      // Clip property changed (move, resize, etc.)
      updateClip(event.target.get('id'));
    }
  });
});
```

---

## 3. Shared Cursors & Presence

```typescript
import { useAwareness } from './hooks/useAwareness';

export function CollaboratorCursors() {
  const states = useAwareness(awareness);

  return (
    <>
      {Array.from(states.entries()).map(([clientId, state]) => {
        if (clientId === doc.clientID) return null;
        if (!state.cursor) return null;
        return (
          <div
            key={clientId}
            className="absolute pointer-events-none z-50"
            style={{
              left: state.cursor.x,
              top: state.cursor.y,
              transition: 'all 100ms ease-out',
            }}
          >
            <CursorIcon color={state.user.color} />
            <span className="text-xs bg-black/80 text-white px-1 rounded">
              {state.user.name}
            </span>
          </div>
        );
      })}
    </>
  );
}

// Update local cursor position
function handleMouseMove(e: MouseEvent) {
  awareness.setLocalStateField('cursor', { x: e.clientX, y: e.clientY });
}
```

---

## 4. Offline-First Sync

```typescript
import { IndexeddbPersistence } from 'y-indexeddb';

// Persist locally — works offline
const localPersistence = new IndexeddbPersistence(
  `workspace-${workspaceId}`,
  doc,
);

localPersistence.on('synced', () => {
  console.log('Local data loaded from IndexedDB');
});

// Reconnection handling
provider.on('status', ({ status }: { status: string }) => {
  if (status === 'connected') {
    // Auto-merge local changes with server
    console.log('Reconnected — changes synced');
  } else {
    console.log('Offline — edits saved locally');
  }
});
```

---

## 5. Version Snapshots

```typescript
import * as Y from 'yjs';

// Create snapshot (checkpoint)
export function createSnapshot(doc: Y.Doc, label: string): Uint8Array {
  const snapshot = Y.snapshot(doc);
  const encoded = Y.encodeSnapshot(snapshot);
  // Store in DB with label and timestamp
  return encoded;
}

// Restore snapshot
export function restoreSnapshot(doc: Y.Doc, snapshotData: Uint8Array) {
  const snapshot = Y.decodeSnapshot(snapshotData);
  const restoredDoc = Y.createDocFromSnapshot(doc, snapshot);
  // Apply restored state
  return restoredDoc;
}

// Compare versions
export function diffSnapshots(doc: Y.Doc, snap1: Uint8Array, snap2: Uint8Array) {
  const s1 = Y.decodeSnapshot(snap1);
  const s2 = Y.decodeSnapshot(snap2);
  // Compute structural diff...
}
```

---

## 6. Best Practices

1. **Yjs over Automerge** for performance — faster for large documents
2. **`doc.transact()`** for atomic operations — batch related changes
3. **Y.Map for structured data** — clips, settings, properties
4. **Y.Array for ordered collections** — timeline tracks, layer order
5. **IndexedDB persistence** — seamless offline → online sync
6. **Awareness for presence** — cursors, selections, active elements
7. **Snapshots for undo** — create checkpoint before destructive operations
8. **Debounce cursor updates** — 50ms throttle to reduce network traffic
