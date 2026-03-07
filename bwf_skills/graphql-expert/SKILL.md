---
name: graphql-expert
description: Design and build production GraphQL APIs. Covers schema design, DataLoader for N+1 prevention, Apollo Federation 2, subscriptions, code generation, persisted queries, security, and GraphQL vs REST decision framework.
---

# GraphQL Expert

Expert guidance for designing, building, and optimizing GraphQL APIs.

## When to Use

- Building or designing GraphQL APIs
- Schema design and type modeling
- Solving N+1 query problems
- Setting up Apollo Federation (microservices)
- Choosing between GraphQL and REST

---

## 1. Schema Design

### Type Definitions
```graphql
type Query {
  user(id: ID!): User
  users(filter: UserFilter, pagination: PaginationInput): UserConnection!
  me: User
}

type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
  updateUser(id: ID!, input: UpdateUserInput!): UpdateUserPayload!
  deleteUser(id: ID!): DeleteUserPayload!
}

type Subscription {
  userCreated: User!
  messageReceived(channelId: ID!): Message!
}

type User implements Node {
  id: ID!
  name: String!
  email: String!
  avatar: String
  posts(first: Int, after: String): PostConnection!
  createdAt: DateTime!
}

# Relay-style Connections (pagination)
type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

# Input types
input CreateUserInput {
  name: String!
  email: String!
  password: String!
}

input UserFilter {
  search: String
  role: UserRole
  isActive: Boolean
}

# Payload pattern (returns result + errors)
type CreateUserPayload {
  user: User
  errors: [UserError!]!
}

type UserError {
  field: String!
  message: String!
}

# Enums
enum UserRole { ADMIN EDITOR VIEWER }

# Custom scalars
scalar DateTime
scalar JSON
scalar URL
```

### Schema Design Rules
```
1. Inputs are "flat" — avoid deeply nested input objects
2. Mutations return Payloads — not raw types
3. Use Relay connections for pagination — cursor-based, not offset
4. Prefix mutations with verb — createUser, updateUser, deleteUser
5. Nullable by default — add ! only when truly required
6. ID fields are always ID! — never String
7. Use enums for fixed sets — UserRole, OrderStatus
8. Avoid generic types — use specific types over JSON scalars
```

## 2. Resolvers (Node.js / TypeScript)

### Basic Resolvers
```typescript
const resolvers = {
  Query: {
    user: async (_parent, { id }, { dataSources }) => {
      return dataSources.userAPI.getUser(id);
    },
    users: async (_parent, { filter, pagination }, { dataSources }) => {
      return dataSources.userAPI.getUsers(filter, pagination);
    },
    me: async (_parent, _args, { currentUser }) => {
      if (!currentUser) throw new GraphQLError('Not authenticated');
      return currentUser;
    },
  },

  Mutation: {
    createUser: async (_parent, { input }, { dataSources }) => {
      try {
        const user = await dataSources.userAPI.create(input);
        return { user, errors: [] };
      } catch (error) {
        return { user: null, errors: [{ field: 'email', message: error.message }] };
      }
    },
  },

  // Field-level resolvers
  User: {
    posts: async (user, { first, after }, { dataSources }) => {
      return dataSources.postAPI.getByUserId(user.id, { first, after });
    },
    avatar: (user) => user.avatar || `https://ui-avatars.com/api/?name=${user.name}`,
  },
};
```

## 3. DataLoader (N+1 Prevention)

### The N+1 Problem
```
Query:
  users(first: 10) {
    name
    posts { title }    ← Without DataLoader: 1 query for users + 10 queries for posts
  }

With DataLoader: 1 query for users + 1 batched query for all posts
```

### Implementation
```typescript
import DataLoader from 'dataloader';

// Create loaders per request (in context)
function createLoaders(db: Database) {
  return {
    userLoader: new DataLoader<string, User>(async (ids) => {
      const users = await db.users.findMany({
        where: { id: { in: [...ids] } },
      });
      // Must return in same order as input IDs
      const userMap = new Map(users.map(u => [u.id, u]));
      return ids.map(id => userMap.get(id) || new Error(`User ${id} not found`));
    }),

    postsByUserLoader: new DataLoader<string, Post[]>(async (userIds) => {
      const posts = await db.posts.findMany({
        where: { userId: { in: [...userIds] } },
      });
      const grouped = new Map<string, Post[]>();
      posts.forEach(p => {
        const list = grouped.get(p.userId) || [];
        list.push(p);
        grouped.set(p.userId, list);
      });
      return userIds.map(id => grouped.get(id) || []);
    }),
  };
}

// Usage in resolvers
const resolvers = {
  Post: {
    author: (post, _args, { loaders }) => loaders.userLoader.load(post.authorId),
  },
  User: {
    posts: (user, _args, { loaders }) => loaders.postsByUserLoader.load(user.id),
  },
};
```

## 4. Apollo Federation 2

### Subgraph: Users Service
```graphql
# users-service/schema.graphql
extend schema @link(url: "https://specs.apollo.dev/federation/v2.5",
  import: ["@key", "@shareable"])

type User @key(fields: "id") {
  id: ID!
  name: String!
  email: String!
}

type Query {
  user(id: ID!): User
  me: User
}
```

### Subgraph: Posts Service
```graphql
# posts-service/schema.graphql
extend schema @link(url: "https://specs.apollo.dev/federation/v2.5",
  import: ["@key", "@external", "@requires"])

type Post @key(fields: "id") {
  id: ID!
  title: String!
  content: String!
  author: User!
}

type User @key(fields: "id") {
  id: ID!
  posts: [Post!]!
}

type Query {
  post(id: ID!): Post
  feed(limit: Int): [Post!]!
}
```

### Reference Resolver
```typescript
// posts-service resolvers
const resolvers = {
  User: {
    __resolveReference: async (user, { dataSources }) => {
      // Fetch posts for this user (Federation calls this)
      return { ...user, posts: await dataSources.postAPI.getByUserId(user.id) };
    },
  },
};
```

### Router Configuration
```yaml
# supergraph config
federation_version: =2.5
subgraphs:
  users:
    routing_url: http://users-service:4001/graphql
    schema:
      subgraph_url: http://users-service:4001/graphql
  posts:
    routing_url: http://posts-service:4002/graphql
    schema:
      subgraph_url: http://posts-service:4002/graphql
```

## 5. Subscriptions (Real-time)

```typescript
import { PubSub } from 'graphql-subscriptions';

const pubsub = new PubSub();

const resolvers = {
  Mutation: {
    sendMessage: async (_p, { input }, { db }) => {
      const message = await db.messages.create(input);
      pubsub.publish(`MESSAGE_${input.channelId}`, { messageReceived: message });
      return message;
    },
  },

  Subscription: {
    messageReceived: {
      subscribe: (_p, { channelId }) =>
        pubsub.asyncIterator(`MESSAGE_${channelId}`),
    },
  },
};
```

### Production: Use Redis PubSub
```typescript
import { RedisPubSub } from 'graphql-redis-subscriptions';

const pubsub = new RedisPubSub({
  connection: { host: 'redis', port: 6379 },
});
```

## 6. Code Generation

### graphql-codegen (TypeScript)
```yaml
# codegen.ts
import { CodegenConfig } from '@graphql-codegen/cli';

const config: CodegenConfig = {
  schema: './schema.graphql',
  documents: './src/**/*.graphql',
  generates: {
    './src/generated/types.ts': {
      plugins: ['typescript', 'typescript-resolvers'],
      config: {
        contextType: '../context#GraphQLContext',
        mappers: {
          User: '../models#UserModel',
          Post: '../models#PostModel',
        },
      },
    },
    './src/generated/operations.ts': {
      plugins: ['typescript', 'typescript-operations'],
    },
  },
};
export default config;
```

## 7. Security

### Query Complexity & Depth Limiting
```typescript
import depthLimit from 'graphql-depth-limit';
import { createComplexityPlugin } from 'graphql-query-complexity';

const server = new ApolloServer({
  validationRules: [depthLimit(7)],
  plugins: [
    createComplexityPlugin({
      maximumComplexity: 1000,
      estimators: [
        fieldExtensionsEstimator(),
        simpleEstimator({ defaultComplexity: 1 }),
      ],
    }),
  ],
});
```

### Persisted Queries
```typescript
// Client sends hash instead of full query
// Reduces bandwidth, prevents arbitrary queries
const link = createPersistedQueryLink({ sha256 });
```

### Rate Limiting
```
Per-field rate limits:
- Query.users: 100/minute
- Mutation.createUser: 10/minute
- Subscription: 5 concurrent per user
```

## 8. GraphQL vs REST Decision Framework

| Factor | Choose GraphQL | Choose REST |
|--------|---------------|-------------|
| **Client needs** | Multiple platforms need different data shapes | All clients need same data |
| **Data relationships** | Complex, nested, interconnected data | Flat, resource-oriented |
| **Bandwidth** | Mobile apps, slow networks | Internal services, high bandwidth |
| **Team** | Frontend-driven development | API-first, backend-driven |
| **Caching** | Complex caching needs | Simple HTTP caching (CDN) |
| **Real-time** | Subscriptions over WebSocket | Webhooks or SSE |
| **File uploads** | REST for uploads, GraphQL for metadata | Built-in multipart |
| **API versioning** | Schema evolution (additive) | URL versioning (/v1, /v2) |
| **Tooling** | Schema introspection, playground | OpenAPI/Swagger |

## 9. Best Practices

- **Schema-first design**: Define schema before resolvers
- **DataLoader everywhere**: Never query DB in a field resolver without batching
- **Pagination from day 1**: Use Relay connections, never return unbounded lists
- **Error handling**: Use union types for expected errors, GraphQL errors for unexpected
- **Persisted queries**: In production, whitelist allowed queries
- **Monitor query cost**: Log and alert on expensive queries
- **Nullable by default**: Makes schema evolution non-breaking
- **Avoid circular references**: Use connection types to break cycles
