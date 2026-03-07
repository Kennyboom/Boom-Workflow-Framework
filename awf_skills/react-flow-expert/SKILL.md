---
name: react-flow-expert
description: Visual pipeline builder with React Flow — custom node types, DAG validation, DagreJS auto-layout, connection rules, Zustand integration, and performance optimization. For Recipe Studio visual workflows.
---

# React Flow Expert — Visual Pipeline Builder

Use this skill for building node-based visual editors like Recipe Studio.

---

## 1. Setup with Zustand

```typescript
import { create } from 'zustand';
import {
  Node, Edge, Connection, addEdge,
  applyNodeChanges, applyEdgeChanges,
  NodeChange, EdgeChange,
} from '@xyflow/react';

interface RecipeFlowState {
  nodes: Node[];
  edges: Edge[];
  onNodesChange: (changes: NodeChange[]) => void;
  onEdgesChange: (changes: EdgeChange[]) => void;
  onConnect: (connection: Connection) => void;
  addNode: (type: string, position: { x: number; y: number }) => void;
  removeNode: (id: string) => void;
}

export const useRecipeFlowStore = create<RecipeFlowState>((set, get) => ({
  nodes: [],
  edges: [],
  onNodesChange: (changes) =>
    set({ nodes: applyNodeChanges(changes, get().nodes) }),
  onEdgesChange: (changes) =>
    set({ edges: applyEdgeChanges(changes, get().edges) }),
  onConnect: (connection) => {
    if (!isValidConnection(connection, get().nodes, get().edges)) return;
    set({ edges: addEdge(connection, get().edges) });
  },
  addNode: (type, position) => {
    const id = `node-${Date.now()}`;
    const newNode = createNodeByType(type, id, position);
    set({ nodes: [...get().nodes, newNode] });
  },
  removeNode: (id) => set({
    nodes: get().nodes.filter(n => n.id !== id),
    edges: get().edges.filter(e => e.source !== id && e.target !== id),
  }),
}));
```

---

## 2. Custom Node Types

```tsx
import { Handle, Position, NodeProps } from '@xyflow/react';

// Input Node (Video/Image source)
function InputNode({ data }: NodeProps) {
  return (
    <div className="bg-blue-900/80 border border-blue-500 rounded-lg p-3 min-w-[200px]">
      <div className="text-xs text-blue-300 font-mono">INPUT</div>
      <div className="font-medium text-white">{data.label}</div>
      <select className="mt-2 w-full bg-blue-800 text-sm rounded p-1">
        <option>Video File</option>
        <option>Image Sequence</option>
        <option>URL</option>
      </select>
      <Handle type="source" position={Position.Right} className="!bg-blue-400" />
    </div>
  );
}

// AI Processing Node
function AiNode({ data }: NodeProps) {
  return (
    <div className="bg-purple-900/80 border border-purple-500 rounded-lg p-3 min-w-[200px]">
      <Handle type="target" position={Position.Left} className="!bg-purple-400" />
      <div className="text-xs text-purple-300 font-mono">AI</div>
      <div className="font-medium text-white">{data.label}</div>
      <div className="text-xs text-gray-400 mt-1">{data.model || 'Gemini'}</div>
      <Handle type="source" position={Position.Right} className="!bg-purple-400" />
    </div>
  );
}

// Output Node
function OutputNode({ data }: NodeProps) {
  return (
    <div className="bg-green-900/80 border border-green-500 rounded-lg p-3 min-w-[200px]">
      <Handle type="target" position={Position.Left} className="!bg-green-400" />
      <div className="text-xs text-green-300 font-mono">OUTPUT</div>
      <div className="font-medium text-white">{data.label}</div>
    </div>
  );
}

export const nodeTypes = {
  input: InputNode,
  ai: AiNode,
  media: MediaNode,
  edit: EditNode,
  output: OutputNode,
  logic: LogicNode,
};
```

---

## 3. Connection Validation

```typescript
function isValidConnection(
  connection: Connection,
  nodes: Node[],
  edges: Edge[],
): boolean {
  const sourceNode = nodes.find(n => n.id === connection.source);
  const targetNode = nodes.find(n => n.id === connection.target);
  if (!sourceNode || !targetNode) return false;

  // Rule 1: No self-connections
  if (connection.source === connection.target) return false;

  // Rule 2: Type compatibility
  const compatible = TYPE_COMPATIBILITY[sourceNode.type!];
  if (compatible && !compatible.includes(targetNode.type!)) return false;

  // Rule 3: No duplicate connections
  const exists = edges.some(
    e => e.source === connection.source && e.target === connection.target
  );
  if (exists) return false;

  // Rule 4: DAG cycle detection
  if (wouldCreateCycle(connection, edges)) return false;

  return true;
}

function wouldCreateCycle(connection: Connection, edges: Edge[]): boolean {
  const visited = new Set<string>();
  const stack = [connection.source!];
  const tempEdges = [...edges, { source: connection.source!, target: connection.target! }];

  while (stack.length > 0) {
    const node = stack.pop()!;
    if (node === connection.target) continue;
    if (visited.has(node)) continue;
    visited.add(node);
    tempEdges
      .filter(e => e.target === node)
      .forEach(e => stack.push(e.source));
  }
  return visited.has(connection.target!);
}

const TYPE_COMPATIBILITY: Record<string, string[]> = {
  input: ['ai', 'media', 'edit', 'logic'],
  ai: ['media', 'edit', 'output', 'logic'],
  media: ['ai', 'edit', 'output', 'logic'],
  edit: ['ai', 'media', 'output', 'logic'],
  logic: ['ai', 'media', 'edit', 'output'],
};
```

---

## 4. Auto-Layout (DagreJS)

```typescript
import dagre from '@dagrejs/dagre';

export function autoLayout(nodes: Node[], edges: Edge[]): Node[] {
  const g = new dagre.graphlib.Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({ rankdir: 'LR', nodesep: 80, ranksep: 120 });

  nodes.forEach(node => {
    g.setNode(node.id, { width: 220, height: 100 });
  });
  edges.forEach(edge => {
    g.setEdge(edge.source, edge.target);
  });

  dagre.layout(g);

  return nodes.map(node => {
    const pos = g.node(node.id);
    return { ...node, position: { x: pos.x - 110, y: pos.y - 50 } };
  });
}
```

---

## 5. Pipeline Execution (Topological Sort)

```typescript
export function getExecutionOrder(nodes: Node[], edges: Edge[]): string[] {
  const inDegree = new Map<string, number>();
  const adjacency = new Map<string, string[]>();

  nodes.forEach(n => { inDegree.set(n.id, 0); adjacency.set(n.id, []); });
  edges.forEach(e => {
    adjacency.get(e.source)!.push(e.target);
    inDegree.set(e.target, (inDegree.get(e.target) || 0) + 1);
  });

  const queue = [...inDegree.entries()].filter(([_, d]) => d === 0).map(([id]) => id);
  const order: string[] = [];

  while (queue.length > 0) {
    const node = queue.shift()!;
    order.push(node);
    for (const neighbor of adjacency.get(node) || []) {
      const newDegree = (inDegree.get(neighbor) || 0) - 1;
      inDegree.set(neighbor, newDegree);
      if (newDegree === 0) queue.push(neighbor);
    }
  }

  if (order.length !== nodes.length) throw new Error('DAG cycle detected!');
  return order;
}
```

---

## 6. Best Practices

1. **Zustand for flow state** — React Flow uses Zustand internally, align with it
2. **Memoize node components** — `React.memo()` all custom nodes
3. **Color-code node types** — blue=input, purple=AI, green=output, orange=edit
4. **DagreJS for auto-layout** — `rankdir: 'LR'` for left-to-right pipelines
5. **Cycle detection on connect** — prevent invalid DAGs immediately
6. **Topological sort for execution** — process nodes in dependency order
7. **Minimap + Controls** — essential for complex pipelines
