---
name: rag-engineer
description: Build production-grade Retrieval-Augmented Generation systems. Covers chunking strategies, embedding models, vector databases (Pinecone/Weaviate/pgvector), hybrid search, reranking, advanced patterns (HyDE, RAPTOR), and evaluation with RAGAS.
---

# RAG Engineer

Expert guidance for building advanced Retrieval-Augmented Generation pipelines beyond basic "embed → search → generate."

## When to Use

- Building knowledge bases with AI search
- Document Q&A systems
- Semantic search over large corpora
- Reducing LLM hallucination with grounding
- Enterprise search and knowledge management

---

## 1. RAG Architecture Overview

```
┌──────────────┐     ┌────────────────┐     ┌──────────────┐
│   Document   │────▶│   Chunking &   │────▶│   Vector     │
│   Ingestion  │     │   Embedding    │     │   Database   │
└──────────────┘     └────────────────┘     └──────┬───────┘
                                                    │
┌──────────────┐     ┌────────────────┐     ┌──────▼───────┐
│   LLM        │◀────│   Prompt       │◀────│   Retrieval  │
│   Generation │     │   Construction │     │   + Rerank   │
└──────────────┘     └────────────────┘     └──────────────┘
```

## 2. Chunking Strategies

### Strategy Comparison
| Strategy | Best For | Chunk Size | Overlap |
|----------|----------|------------|---------|
| **Fixed-size** | Simple docs, logs | 512-1024 tokens | 50-100 tokens |
| **Recursive** | General text | 500-1000 chars | 100-200 chars |
| **Semantic** | Articles, books | Variable | By similarity threshold |
| **Document-aware** | Markdown, HTML, code | By section/function | None |
| **Parent-child** | Long documents | Parent: 2000, Child: 500 | None |

### Recursive Text Splitting (LangChain)
```python
from langchain.text_splitter import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    separators=["\n\n", "\n", ". ", " ", ""],
    length_function=len,
)

chunks = splitter.split_documents(documents)
```

### Semantic Chunking
```python
from langchain_experimental.text_splitter import SemanticChunker
from langchain_openai import OpenAIEmbeddings

splitter = SemanticChunker(
    OpenAIEmbeddings(),
    breakpoint_threshold_type="percentile",
    breakpoint_threshold_amount=95,
)

# Splits when embedding similarity drops below threshold
chunks = splitter.split_documents(documents)
```

### Parent-Child (Small-to-Big) Retrieval
```python
from langchain.retrievers import ParentDocumentRetriever
from langchain.storage import InMemoryStore

# Search on small chunks, return parent context
parent_splitter = RecursiveCharacterTextSplitter(chunk_size=2000)
child_splitter = RecursiveCharacterTextSplitter(chunk_size=500)

retriever = ParentDocumentRetriever(
    vectorstore=vectorstore,
    docstore=InMemoryStore(),
    child_splitter=child_splitter,
    parent_splitter=parent_splitter,
)
```

## 3. Embedding Models

### Comparison
| Model | Dimensions | Quality | Speed | Cost |
|-------|-----------|---------|-------|------|
| `text-embedding-3-large` (OpenAI) | 3072 | ⭐⭐⭐⭐⭐ | Fast | $0.13/1M tokens |
| `text-embedding-3-small` (OpenAI) | 1536 | ⭐⭐⭐⭐ | Fast | $0.02/1M tokens |
| `embed-english-v3.0` (Cohere) | 1024 | ⭐⭐⭐⭐⭐ | Fast | $0.10/1M tokens |
| `BAAI/bge-large-en-v1.5` | 1024 | ⭐⭐⭐⭐ | Medium | Free (self-hosted) |
| `sentence-transformers/all-MiniLM-L6-v2` | 384 | ⭐⭐⭐ | Very fast | Free |
| `nomic-embed-text` (Ollama) | 768 | ⭐⭐⭐⭐ | Fast | Free (local) |

### Usage
```python
from openai import OpenAI

client = OpenAI()

def embed(texts: list[str], model="text-embedding-3-small") -> list[list[float]]:
    response = client.embeddings.create(input=texts, model=model)
    return [item.embedding for item in response.data]

# Batch for efficiency
embeddings = embed(["Hello world", "How are you?"])
```

### Dimensionality Reduction (Cost Optimization)
```python
# text-embedding-3 supports native dimension reduction
response = client.embeddings.create(
    input="Hello world",
    model="text-embedding-3-large",
    dimensions=256,  # Reduce from 3072 to 256 (91% storage savings)
)
```

## 4. Vector Databases

### Comparison Matrix
| Database | Type | Scale | Features | Best For |
|----------|------|-------|----------|----------|
| **Pinecone** | Managed | Billions | Namespaces, metadata filter | Production SaaS |
| **Weaviate** | Self-hosted/Cloud | Millions | Hybrid search, modules | Enterprise |
| **Qdrant** | Self-hosted/Cloud | Millions | Rich filtering, Rust speed | High-performance |
| **pgvector** | PostgreSQL extension | Millions | SQL integration, ACID | Existing Postgres |
| **Chroma** | Embedded | Thousands | Simple API, local-first | Prototyping |

### Pinecone
```python
from pinecone import Pinecone

pc = Pinecone(api_key="YOUR_KEY")
index = pc.Index("my-index")

# Upsert
index.upsert(vectors=[
    {"id": "doc1", "values": embedding, "metadata": {"source": "manual.pdf", "page": 5}},
])

# Query with metadata filter
results = index.query(
    vector=query_embedding,
    top_k=10,
    filter={"source": {"$eq": "manual.pdf"}},
    include_metadata=True,
)
```

### pgvector (PostgreSQL)
```sql
CREATE EXTENSION vector;

CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB,
    embedding vector(1536)
);

-- Create index (IVFFlat for speed, HNSW for quality)
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);

-- Similarity search
SELECT id, content, 1 - (embedding <=> $1::vector) AS similarity
FROM documents
WHERE metadata->>'source' = 'manual.pdf'
ORDER BY embedding <=> $1::vector
LIMIT 10;
```

## 5. Hybrid Search (Dense + Sparse)

```python
# Combine vector similarity with BM25 keyword matching
from langchain.retrievers import EnsembleRetriever
from langchain_community.retrievers import BM25Retriever

# Sparse retriever (keyword-based)
bm25_retriever = BM25Retriever.from_documents(documents)
bm25_retriever.k = 10

# Dense retriever (embedding-based)
vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 10})

# Ensemble with Reciprocal Rank Fusion
ensemble_retriever = EnsembleRetriever(
    retrievers=[bm25_retriever, vector_retriever],
    weights=[0.4, 0.6],  # Tune based on use case
)

results = ensemble_retriever.invoke("What is the return policy?")
```

## 6. Reranking

### Cohere Rerank
```python
import cohere

co = cohere.Client("YOUR_KEY")

# First: retrieve top 20 with vector search (fast but imprecise)
initial_results = vectorstore.similarity_search(query, k=20)

# Then: rerank with cross-encoder (slower but much more accurate)
reranked = co.rerank(
    model="rerank-english-v3.0",
    query=query,
    documents=[doc.page_content for doc in initial_results],
    top_n=5,  # Return only top 5
)

# Use reranked results for generation
final_docs = [initial_results[r.index] for r in reranked.results]
```

### Why Two-Stage Retrieval?
```
Stage 1: Vector search (retrieve 20-50 candidates)
  - Fast: ~10ms for millions of docs
  - Good recall, moderate precision

Stage 2: Cross-encoder rerank (rerank to top 5-10)
  - Slow: ~100ms per candidate
  - Excellent precision (considers query-doc interaction)

Result: Best of both worlds — fast AND accurate
```

## 7. Advanced RAG Patterns

### HyDE (Hypothetical Document Embeddings)
```python
# Instead of embedding the question, generate a hypothetical answer
# and embed THAT — often retrieves better results

def hyde_retrieval(query: str) -> list[Document]:
    # Step 1: Generate hypothetical answer
    hypothetical = llm.invoke(
        f"Write a short paragraph that answers: {query}"
    )
    # Step 2: Embed the hypothetical answer
    embedding = embed(hypothetical.content)
    # Step 3: Search with hypothetical embedding
    return vectorstore.similarity_search_by_vector(embedding, k=5)
```

### Multi-Query Retrieval
```python
from langchain.retrievers import MultiQueryRetriever

# Generates multiple reformulations of the query
retriever = MultiQueryRetriever.from_llm(
    retriever=vectorstore.as_retriever(),
    llm=llm,
)

# "What is the return policy?" generates:
# 1. "How can I return an item?"
# 2. "What are the conditions for refunds?"
# 3. "Is there a time limit for returns?"
# Retrieves results for all 3, deduplicates
```

### Self-Query (Metadata Filtering)
```python
from langchain.retrievers import SelfQueryRetriever

retriever = SelfQueryRetriever.from_llm(
    llm=llm,
    vectorstore=vectorstore,
    document_contents="Product documentation",
    metadata_field_info=[
        {"name": "category", "type": "string", "description": "Product category"},
        {"name": "year", "type": "integer", "description": "Publication year"},
    ],
)

# "Show me electronics products from 2024"
# → Automatically creates filter: category="electronics" AND year=2024
```

### Contextual Compression
```python
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor

compressor = LLMChainExtractor.from_llm(llm)
retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=vectorstore.as_retriever(search_kwargs={"k": 10}),
)

# Retrieved docs are compressed to only query-relevant parts
```

## 8. Prompt Construction

### Template with Sources
```python
RAG_PROMPT = """Answer the question based on the following context.
If the context doesn't contain enough information, say "I don't have enough information."

Context:
{context}

Question: {question}

Instructions:
- Use ONLY information from the context
- Cite sources using [Source: filename, page X] format
- If multiple sources agree, synthesize them
- If sources conflict, mention the discrepancy

Answer:"""
```

### Citation & Source Tracking
```python
def generate_with_citations(query: str, docs: list[Document]) -> str:
    # Build context with source markers
    context_parts = []
    for i, doc in enumerate(docs):
        source = doc.metadata.get("source", "unknown")
        page = doc.metadata.get("page", "?")
        context_parts.append(f"[{i+1}] (Source: {source}, Page {page})\n{doc.page_content}")

    context = "\n\n".join(context_parts)
    response = llm.invoke(RAG_PROMPT.format(context=context, question=query))
    return response.content
```

## 9. Evaluation (RAGAS)

```python
from ragas import evaluate
from ragas.metrics import (
    faithfulness,       # Is the answer grounded in context?
    answer_relevancy,   # Does the answer address the question?
    context_precision,  # Are the right docs retrieved?
    context_recall,     # Are all relevant docs retrieved?
)

# Prepare evaluation dataset
eval_data = {
    "question": ["What is the return policy?"],
    "answer": ["Items can be returned within 30 days..."],
    "contexts": [["Our return policy allows 30 days..."]],
    "ground_truth": ["The return policy is 30 days for all items."],
}

results = evaluate(
    dataset=eval_data,
    metrics=[faithfulness, answer_relevancy, context_precision, context_recall],
)

# Target scores:
# Faithfulness > 0.8 (answer doesn't hallucinate)
# Answer Relevancy > 0.8 (answer is on-topic)
# Context Precision > 0.7 (retrieved docs are relevant)
# Context Recall > 0.7 (all relevant docs found)
```

## 10. Production Checklist

- [ ] **Chunking**: Tested multiple strategies, measured retrieval quality
- [ ] **Embedding**: Chosen model matches language and domain
- [ ] **Vector DB**: Indexed with appropriate algorithm (HNSW vs IVFFlat)
- [ ] **Hybrid search**: Combined dense + sparse for better recall
- [ ] **Reranking**: Cross-encoder rerank on top-k results
- [ ] **Metadata filtering**: Structured filters reduce search space
- [ ] **Caching**: Cache embeddings, cache frequent queries
- [ ] **Incremental indexing**: Update/delete docs without full re-index
- [ ] **Evaluation**: RAGAS pipeline running on test set
- [ ] **Monitoring**: Track retrieval quality, latency, token usage
- [ ] **Guardrails**: Block off-topic queries, detect hallucinations
