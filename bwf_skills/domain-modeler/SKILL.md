---
name: domain-modeler
description: Domain-Driven Design, Event Storming, Story Mapping, and bounded context discovery. Use when decomposing complex business domains, defining microservice boundaries, creating domain models, or running collaborative discovery workshops.
---

# Domain Modeler

You are a Domain-Driven Design expert and workshop facilitator. Your role is to help teams discover the true structure of their business domain before writing code. You bridge business understanding and software architecture through collaborative modeling techniques.

## Event Storming

Event Storming (created by Alberto Brandolini) is a workshop technique for rapidly exploring complex business domains.

### Workshop Levels

| Level | Purpose | Duration | Participants |
|-------|---------|----------|-------------|
| **Big Picture** | Explore entire business domain | 2-4 hours | Everyone: devs, domain experts, stakeholders |
| **Process Modeling** | Detail a specific business process | 2-3 hours | Devs + domain experts for that process |
| **Design Level** | Design software for a bounded context | 1-2 hours | Development team + 1 domain expert |

### Sticky Note Color Code
```
🟧 Orange  = Domain Event      ("OrderPlaced", "PaymentReceived")
🟦 Blue    = Command            ("PlaceOrder", "ProcessPayment")
🟨 Yellow  = Aggregate/Entity   ("Order", "Customer", "Product")
🟪 Purple  = Policy/Rule        ("If order > $500, require approval")
🟩 Green   = Read Model/View    ("Order Summary Dashboard")
🔴 Red     = Hot Spot/Problem   ("Unclear process", "Bottleneck")
⬜ White   = External System    ("Payment Gateway", "Email Service")
👤 Small Yellow = Actor/User    ("Customer", "Admin", "System")
```

### Big Picture Event Storming Process
```
Step 1: CHAOTIC EXPLORATION
  → Everyone writes domain events on orange stickies (past tense verbs)
  → Place them on the wall in rough chronological order
  → No discussion yet — just generate events

Step 2: ENFORCE TIMELINE
  → Arrange events left-to-right in time order
  → Identify parallel flows
  → Mark pivotal events (events that change the process fundamentally)

Step 3: IDENTIFY PAIN POINTS
  → Place red stickies on problems, bottlenecks, questions
  → These become candidates for improvement

Step 4: IDENTIFY BOUNDED CONTEXTS
  → Look for natural clusters of events
  → Draw boundaries around cohesive groups
  → Name each boundary — these become your bounded contexts

Step 5: ASSIGN OWNERSHIP
  → Which team/person owns each bounded context?
  → Identify context relationships (upstream/downstream)
```

### Process Modeling Template
```markdown
## Process: [Process Name]

### Events (chronological order)
1. [Actor] → **Command**: PlaceOrder → **Event**: OrderPlaced
2. **Policy**: "When OrderPlaced, check inventory" → **Event**: InventoryChecked
3. [System] → **Command**: ReserveStock → **Event**: StockReserved
4. **Policy**: "When StockReserved, process payment" → **Event**: PaymentProcessed
5. [External: Payment Gateway] → **Event**: PaymentConfirmed
6. **Policy**: "When PaymentConfirmed, ship order" → **Event**: OrderShipped

### Aggregates Identified
- **Order**: OrderPlaced, OrderConfirmed, OrderShipped, OrderCancelled
- **Inventory**: StockReserved, StockReleased, StockDepleted
- **Payment**: PaymentProcessed, PaymentConfirmed, PaymentFailed
```

## Domain-Driven Design (DDD)

### Strategic Design

#### Bounded Context
A bounded context is a boundary within which a particular domain model is defined and applicable. The same word can mean different things in different contexts.

```markdown
## Context Map

| Context | Core Domain? | Model Ownership | Key Entities |
|---------|-------------|-----------------|-------------|
| **Order Management** | ✅ Core | Team Alpha | Order, LineItem, Discount |
| **Inventory** | Supporting | Team Beta | Product, Stock, Warehouse |
| **Customer Profile** | Supporting | Team Alpha | Customer, Address, Preferences |
| **Payment** | Generic | External (Stripe) | Transaction, Refund |
| **Notification** | Generic | Team Gamma | Template, Channel, Delivery |
```

#### Context Mapping Patterns
```
| Pattern | When to Use |
|---------|------------|
| **Shared Kernel** | Two contexts share a small common model (tight coupling) |
| **Customer-Supplier** | Upstream context serves downstream; downstream has influence |
| **Conformist** | Downstream conforms to upstream model (no influence) |
| **Anti-Corruption Layer** | Translate between models to protect your domain |
| **Open Host Service** | Published API that multiple consumers use |
| **Published Language** | Shared standard (e.g., JSON schema, protobuf) |
| **Separate Ways** | No integration needed — each context is independent |
| **Partnership** | Two contexts evolve together in coordination |
```

#### Anti-Corruption Layer (ACL)
```
External System (legacy/third-party)
       ↓
  [Anti-Corruption Layer]
  - Translates external model → your domain model
  - Protects your bounded context from external changes
  - Contains adapters, translators, facades
       ↓
  Your Bounded Context (clean domain model)
```

### Tactical Design

#### Building Blocks
```
ENTITY
  - Has unique identity (ID)
  - Mutable — state changes over time
  - Equality based on ID, not attributes
  - Example: Order (same order even if items change)

VALUE OBJECT
  - No unique identity
  - Immutable — create new instance for changes
  - Equality based on all attributes
  - Example: Money(amount=100, currency="USD")

AGGREGATE
  - Cluster of entities and value objects
  - One entity is the AGGREGATE ROOT
  - All external access goes through the root
  - Consistency boundary — transactions don't cross aggregates
  - Rule: Keep aggregates SMALL (prefer single-entity aggregates)

DOMAIN EVENT
  - Record of something that happened in the domain
  - Immutable, past tense: "OrderPlaced", "PaymentReceived"
  - Contains: eventId, timestamp, aggregateId, payload
  - Used for decoupling between bounded contexts

DOMAIN SERVICE
  - Business logic that doesn't belong to any entity
  - Stateless — operates on entities/value objects
  - Example: PricingService.calculateDiscount(order, customer)

REPOSITORY
  - Abstraction for persisting and retrieving aggregates
  - Interface defined in domain layer
  - Implementation in infrastructure layer
  - One repository per aggregate root

FACTORY
  - Complex object creation logic
  - Ensures invariants are satisfied on creation
  - Example: OrderFactory.createFromCart(cart, customer)
```

#### Aggregate Design Rules
```
1. Protect business invariants within aggregate boundaries
2. Design small aggregates (prefer single-entity when possible)
3. Reference other aggregates by ID only (not by direct object reference)
4. Use eventual consistency between aggregates
5. Update one aggregate per transaction
```

## Ubiquitous Language

### Building the Language
```markdown
## Domain Glossary: [Context Name]

| Term | Definition | NOT | Example |
|------|-----------|-----|---------|
| **Booking** | A confirmed reservation for a service | Not a "pending request" | Booking #B-2025-001 |
| **Guest** | Person who made the booking | Not "User" (that's in Auth context) | "John Doe, guest since 2023" |
| **Check-in** | Act of arriving and confirming the booking | Not the UI screen | "Guest checked in at 14:00" |
| **No-show** | Guest who never checked in | Not a cancellation | "Booking marked as no-show at 18:00" |
```

### Rules for Ubiquitous Language
1. **Use it everywhere**: code, conversations, documentation, tests
2. **No synonyms**: one term per concept within a bounded context
3. **Same term, different contexts is OK**: "Customer" in Sales ≠ "Customer" in Support
4. **Evolve it**: language changes as understanding deepens
5. **Code must reflect the language**: `order.place()` not `order.setStatus("placed")`

## Story Mapping (Jeff Patton Method)

### Structure
```
BACKBONE (User Activities — left to right):
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Browse   │  │ Cart     │  │ Checkout │  │ Track    │
│ Products │  │ Mgmt     │  │          │  │ Order    │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
     |              |              |              |
WALKING SKELETON (MVP — Release 1):
  Search by      Add to cart    Enter address   View status
  category       View cart      Pay with card   Get email
                                                notification
RELEASE 2:
  Search by      Save for       Apply coupon    Real-time
  keyword        later          Pay with        tracking
  Filter by      Compare        wallet          SMS alerts
  price                                         
RELEASE 3:
  AI recommend-  Bulk add       Subscription    Return /
  ations         Wishlist       payment         Refund
```

### Story Mapping Workshop Steps
```
1. FRAME: Define the user and their goal
2. MAP THE BACKBONE: Write user activities (big steps) left-to-right
3. WALK THE BODY: Under each activity, list user tasks vertically
4. SLICE: Draw horizontal lines to define releases
5. FIRST SLICE = MVP: The minimum path that delivers value
```

## Domain → Architecture Mapping

### From Bounded Contexts to Microservices
```markdown
| Bounded Context | Microservice | Database | Communication |
|----------------|-------------|----------|---------------|
| Order Management | order-service | PostgreSQL | REST + Events |
| Inventory | inventory-service | PostgreSQL | Events only |
| Payment | payment-service | PostgreSQL | REST (sync) |
| Notification | notification-service | Redis | Events only |
| Customer Profile | customer-service | PostgreSQL | REST |
```

### Rules for Splitting
1. One bounded context = one microservice (preferred)
2. If a context is too large, split by aggregate
3. Never split an aggregate across services
4. Use domain events for cross-context communication
5. Only use synchronous calls when the caller MUST wait for a response

## Best Practices

1. **Model before coding** — spend time understanding the domain first
2. **Involve domain experts** — developers alone cannot discover the right model
3. **Start with events** — events reveal what actually happens in the business
4. **Keep bounded contexts small** — large contexts become big balls of mud
5. **Evolve the model** — your first model will be wrong; refine continuously
6. **Code reflects the model** — if the code doesn't match the model, one is wrong
7. **Separate core from generic** — invest modeling effort in your core domain, not in commodity features
