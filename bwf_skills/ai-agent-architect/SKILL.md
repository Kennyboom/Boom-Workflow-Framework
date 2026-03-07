---
name: ai-agent-architect
description: Design and build autonomous AI agents. Covers LangChain/LangGraph, CrewAI, AutoGen, agentic patterns (ReAct, Plan-Execute, Reflection), function calling, multi-agent orchestration, memory systems, and guardrails.
---

# AI Agent Architect

Expert guidance for building autonomous AI agent systems that reason, plan, and execute multi-step tasks.

## When to Use

- Building AI agents that use tools autonomously
- Multi-agent collaborative systems
- Complex workflows with planning and execution
- Function calling / tool use with LLMs
- Conversational agents with memory

---

## 1. Agent Architecture Patterns

```
┌─────────────────────────────────────────────┐
│                Agent Loop                   │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐  │
│  │ Observe │→ │  Reason  │→ │    Act    │  │
│  │ (input) │  │ (think)  │  │ (tool/    │  │
│  │         │  │          │  │  respond) │  │
│  └─────────┘  └──────────┘  └─────┬─────┘  │
│       ↑                           │         │
│       └───────────────────────────┘         │
│              (loop until done)              │
└─────────────────────────────────────────────┘
```

### Pattern Comparison
| Pattern | Description | Best For |
|---------|-------------|----------|
| **ReAct** | Reason + Act in alternating steps | General tool use |
| **Plan-Execute** | Plan all steps first, then execute | Complex multi-step tasks |
| **Reflection** | Self-critique and improve output | Writing, code generation |
| **Tool Use** | Single LLM call with function calling | Simple API integrations |
| **Multi-Agent** | Multiple specialized agents collaborate | Complex workflows |

## 2. Function Calling (Tool Use)

### OpenAI Function Calling
```python
from openai import OpenAI

client = OpenAI()

tools = [
    {
        "type": "function",
        "function": {
            "name": "search_products",
            "description": "Search the product catalog by name, category, or price range",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query"},
                    "category": {"type": "string", "enum": ["electronics", "clothing", "books"]},
                    "max_price": {"type": "number", "description": "Maximum price in USD"},
                },
                "required": ["query"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get current weather for a location",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {"type": "string", "description": "City name"},
                },
                "required": ["location"],
            },
        },
    },
]

# Agent loop
messages = [{"role": "user", "content": "Find me a laptop under $1000"}]

while True:
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=messages,
        tools=tools,
        tool_choice="auto",
    )

    msg = response.choices[0].message
    messages.append(msg)

    if msg.tool_calls:
        for call in msg.tool_calls:
            result = execute_tool(call.function.name, call.function.arguments)
            messages.append({
                "role": "tool",
                "tool_call_id": call.id,
                "content": str(result),
            })
    else:
        print(msg.content)
        break
```

### Gemini Function Calling
```python
import google.generativeai as genai

search_tool = genai.protos.Tool(
    function_declarations=[
        genai.protos.FunctionDeclaration(
            name="search_products",
            description="Search product catalog",
            parameters=genai.protos.Schema(
                type=genai.protos.Type.OBJECT,
                properties={
                    "query": genai.protos.Schema(type=genai.protos.Type.STRING),
                    "max_price": genai.protos.Schema(type=genai.protos.Type.NUMBER),
                },
                required=["query"],
            ),
        ),
    ]
)

model = genai.GenerativeModel("gemini-2.0-flash", tools=[search_tool])
chat = model.start_chat()
response = chat.send_message("Find laptops under $1000")
```

## 3. LangGraph (Recommended for Complex Agents)

### ReAct Agent
```python
from langgraph.prebuilt import create_react_agent
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool

@tool
def search_web(query: str) -> str:
    """Search the web for current information."""
    return tavily_client.search(query)

@tool
def calculate(expression: str) -> float:
    """Evaluate a mathematical expression."""
    return eval(expression)  # Use safe eval in production

llm = ChatOpenAI(model="gpt-4o")
agent = create_react_agent(llm, tools=[search_web, calculate])

# Run
result = agent.invoke({
    "messages": [{"role": "user", "content": "What is the GDP of Japan divided by its population?"}]
})
```

### Custom Graph (Plan-Execute)
```python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict, Annotated
import operator

class AgentState(TypedDict):
    messages: Annotated[list, operator.add]
    plan: list[str]
    current_step: int
    results: dict

def planner(state: AgentState) -> AgentState:
    """Create a plan of steps to complete the task."""
    plan = llm.invoke(
        f"Create a step-by-step plan for: {state['messages'][-1].content}"
    )
    return {"plan": parse_plan(plan.content), "current_step": 0}

def executor(state: AgentState) -> AgentState:
    """Execute the current step of the plan."""
    step = state["plan"][state["current_step"]]
    result = agent_executor.invoke({"input": step})
    return {
        "results": {**state["results"], step: result},
        "current_step": state["current_step"] + 1,
        "messages": [AIMessage(content=result)],
    }

def should_continue(state: AgentState) -> str:
    if state["current_step"] >= len(state["plan"]):
        return "synthesize"
    return "execute"

def synthesizer(state: AgentState) -> AgentState:
    """Combine all results into final answer."""
    summary = llm.invoke(f"Synthesize these results: {state['results']}")
    return {"messages": [AIMessage(content=summary.content)]}

# Build graph
graph = StateGraph(AgentState)
graph.add_node("plan", planner)
graph.add_node("execute", executor)
graph.add_node("synthesize", synthesizer)

graph.add_edge(START, "plan")
graph.add_edge("plan", "execute")
graph.add_conditional_edges("execute", should_continue, {
    "execute": "execute",
    "synthesize": "synthesize",
})
graph.add_edge("synthesize", END)

app = graph.compile()
```

### Human-in-the-Loop
```python
from langgraph.checkpoint.memory import MemorySaver

# Add checkpointing for interrupt/resume
checkpointer = MemorySaver()
app = graph.compile(checkpointer=checkpointer, interrupt_before=["execute"])

# Run until interrupt
config = {"configurable": {"thread_id": "user-123"}}
result = app.invoke({"messages": [HumanMessage("Delete all user data")]}, config)

# User reviews and approves
# Resume execution
app.invoke(None, config)  # Continues from checkpoint
```

## 4. Multi-Agent Systems

### Supervisor Pattern (LangGraph)
```python
from langgraph.graph import StateGraph

def supervisor(state):
    """Route tasks to specialized agents."""
    response = llm.invoke(
        f"""You are a supervisor managing these agents:
        - researcher: searches for information
        - writer: writes content
        - reviewer: reviews and improves content

        Given the current state, which agent should act next?
        Respond with the agent name or 'FINISH'.

        Task: {state['task']}
        Progress: {state['progress']}"""
    )
    return {"next": response.content.strip()}

graph = StateGraph(SupervisorState)
graph.add_node("supervisor", supervisor)
graph.add_node("researcher", researcher_agent)
graph.add_node("writer", writer_agent)
graph.add_node("reviewer", reviewer_agent)

# Supervisor routes to agents
graph.add_conditional_edges("supervisor", route_to_agent)
# All agents report back to supervisor
for agent in ["researcher", "writer", "reviewer"]:
    graph.add_edge(agent, "supervisor")
```

### CrewAI (Simpler Multi-Agent)
```python
from crewai import Agent, Task, Crew

researcher = Agent(
    role="Research Analyst",
    goal="Find comprehensive information on the given topic",
    backstory="Expert researcher with access to web search",
    tools=[search_tool],
    llm="gpt-4o",
)

writer = Agent(
    role="Content Writer",
    goal="Write engaging, well-structured articles",
    backstory="Professional writer specializing in tech content",
    llm="gpt-4o",
)

research_task = Task(
    description="Research the latest trends in {topic}",
    agent=researcher,
    expected_output="Comprehensive research notes with sources",
)

writing_task = Task(
    description="Write a blog post based on the research",
    agent=writer,
    expected_output="A 1000-word blog post",
    context=[research_task],  # Depends on research
)

crew = Crew(agents=[researcher, writer], tasks=[research_task, writing_task])
result = crew.kickoff(inputs={"topic": "AI agents in 2025"})
```

## 5. Memory Systems

### Short-Term (Conversation)
```python
from langchain_core.chat_history import InMemoryChatMessageHistory

# Simple conversation buffer
history = InMemoryChatMessageHistory()
history.add_user_message("My name is Alice")
history.add_ai_message("Hello Alice!")
```

### Long-Term (Vector Memory)
```python
from langchain.memory import VectorStoreRetrieverMemory

# Store important facts, retrieve when relevant
memory = VectorStoreRetrieverMemory(
    retriever=vectorstore.as_retriever(search_kwargs={"k": 5}),
    memory_key="relevant_history",
)

# Automatically stores conversation turns
memory.save_context(
    {"input": "I prefer Python over JavaScript"},
    {"output": "Noted! I'll use Python in examples."},
)

# Later, when user asks about code:
relevant = memory.load_memory_variables({"input": "Write me a web scraper"})
# Returns: "User prefers Python over JavaScript"
```

### Summary Memory (Compress Old Context)
```python
from langchain.memory import ConversationSummaryBufferMemory

memory = ConversationSummaryBufferMemory(
    llm=llm,
    max_token_limit=2000,  # Summarize when exceeding limit
)
# Recent messages kept verbatim, older ones summarized
```

## 6. Tool Design Principles

```python
@tool
def search_database(
    query: str,
    table: str = "products",
    limit: int = 10,
) -> str:
    """Search the database for records matching the query.

    Use this tool when you need to find specific data from the database.
    Always specify the table name. Common tables: products, users, orders.

    Args:
        query: Natural language search query
        table: Database table to search (default: products)
        limit: Maximum results to return (default: 10, max: 50)

    Returns:
        JSON string of matching records with id, name, and relevant fields.
    """
    # Implementation
    results = db.search(table, query, limit=min(limit, 50))
    return json.dumps(results, indent=2)
```

### Tool Design Rules
```
1. DESCRIPTIVE NAMES: search_products > search > s
2. DETAILED DOCSTRINGS: LLM reads these to decide when to use
3. CLEAR PARAMETERS: type hints, defaults, descriptions
4. BOUNDED OUTPUTS: limit results, truncate long text
5. ERROR MESSAGES: return helpful errors, not stack traces
6. IDEMPOTENT: same input → same output (when possible)
7. SINGLE RESPONSIBILITY: one tool per action
```

## 7. Guardrails

### Input Validation
```python
from guardrails import Guard
from guardrails.hub import ToxicLanguage, DetectPII

# Block toxic inputs
guard = Guard().use_many(
    ToxicLanguage(on_fail="exception"),
    DetectPII(on_fail="fix"),  # Redact PII automatically
)

validated_input = guard.validate(user_message)
```

### Output Validation
```python
# Ensure agent responses are safe and accurate
def validate_agent_output(response: str, context: list[str]) -> str:
    # Check for hallucination
    verification = llm.invoke(
        f"""Does this response contain claims NOT supported by the context?
        Context: {context}
        Response: {response}
        Answer YES or NO with explanation."""
    )
    if "YES" in verification.content:
        return "I'm not confident in this answer. Let me search for more information."
    return response
```

### Rate Limiting & Cost Control
```python
# Track token usage per user
class TokenTracker:
    def __init__(self, daily_limit=100_000):
        self.usage = {}
        self.daily_limit = daily_limit

    def check(self, user_id: str, estimated_tokens: int) -> bool:
        used = self.usage.get(user_id, 0)
        if used + estimated_tokens > self.daily_limit:
            raise RateLimitError(f"Daily token limit exceeded")
        return True

    def record(self, user_id: str, tokens_used: int):
        self.usage[user_id] = self.usage.get(user_id, 0) + tokens_used
```

## 8. Error Recovery

```python
class ResilientAgent:
    def __init__(self, max_retries=3):
        self.max_retries = max_retries

    async def execute_with_recovery(self, task: str) -> str:
        for attempt in range(self.max_retries):
            try:
                result = await self.agent.ainvoke({"input": task})
                return result["output"]
            except ToolExecutionError as e:
                # Retry with modified approach
                task = f"{task}\n\nPrevious attempt failed: {e}. Try a different approach."
            except RateLimitError:
                await asyncio.sleep(2 ** attempt)  # Exponential backoff
            except Exception as e:
                if attempt == self.max_retries - 1:
                    return f"I encountered an error after {self.max_retries} attempts: {e}"

        return "Unable to complete the task. Please try rephrasing your request."
```

## 9. Frameworks Comparison

| Framework | Complexity | Flexibility | Multi-Agent | Production |
|-----------|-----------|-------------|-------------|------------|
| **LangGraph** | Medium | ⭐⭐⭐⭐⭐ | Graph-based | ⭐⭐⭐⭐⭐ |
| **CrewAI** | Low | ⭐⭐⭐ | Role-based | ⭐⭐⭐ |
| **AutoGen** | Medium | ⭐⭐⭐⭐ | Conversation | ⭐⭐⭐⭐ |
| **OpenAI Assistants** | Low | ⭐⭐ | No | ⭐⭐⭐ |
| **Custom** | High | ⭐⭐⭐⭐⭐ | Any | ⭐⭐⭐⭐⭐ |

### Decision Guide
```
Need simple tool-use agent?        → OpenAI Assistants API
Need multi-step workflow?          → LangGraph
Need role-based team of agents?    → CrewAI
Need conversation between agents?  → AutoGen
Need maximum control?              → Custom agent loop
```

## 10. Best Practices

- **Start simple**: Single agent with tools before multi-agent
- **Structured outputs**: Use `response_format` for reliable JSON
- **Observability**: Log every LLM call, tool invocation, and decision
- **Checkpointing**: Save state for long-running agents (resume on failure)
- **Human-in-the-loop**: Always for destructive operations (delete, send, publish)
- **Token budgets**: Set max iterations and token limits per agent run
- **Test with evals**: Create test cases for agent behavior, not just output
- **Streaming**: Stream intermediate steps to users for transparency
