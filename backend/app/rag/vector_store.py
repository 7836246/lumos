"""
向量数据库管理.

使用 ChromaDB 作为本地向量库:
- 首次启动时自动从 law_corpus 加载法条并向量化
- 支持语义检索最相关的法律条文
- 使用 sentence-transformers 本地嵌入 (无需 API Key)
"""

from __future__ import annotations

import hashlib
import json
from functools import lru_cache
from pathlib import Path

import chromadb
from chromadb.config import Settings as ChromaSettings
from loguru import logger

from app.core.config import get_settings
from app.rag.law_corpus import ALL_LAWS


def _get_chroma_path() -> str:
    """获取 ChromaDB 持久化路径."""
    settings = get_settings()
    # 存在 backend/data/chroma_db/
    base = Path(settings.database_url.split("///")[-1]).parent if ":///" in settings.database_url else Path(".")
    chroma_dir = base / "chroma_db"
    chroma_dir.mkdir(parents=True, exist_ok=True)
    return str(chroma_dir)


@lru_cache
def get_chroma_client() -> chromadb.ClientAPI:
    """获取 ChromaDB 客户端 (单例)."""
    chroma_path = _get_chroma_path()
    logger.info(f"📦 ChromaDB 路径: {chroma_path}")

    client = chromadb.PersistentClient(
        path=chroma_path,
        settings=ChromaSettings(anonymized_telemetry=False),
    )
    return client


def _compute_corpus_hash() -> str:
    """计算法条库的内容哈希，用于判断是否需要重新加载."""
    content = json.dumps(ALL_LAWS, ensure_ascii=False, sort_keys=True)
    return hashlib.md5(content.encode()).hexdigest()[:12]  # noqa: S324


def get_law_collection() -> chromadb.Collection:
    """获取或创建法律条文集合."""
    client = get_chroma_client()
    collection_name = "labor_laws"

    # 检查是否已有集合且数据是最新的
    try:
        collection = client.get_collection(collection_name)
        metadata = collection.metadata or {}

        current_hash = _compute_corpus_hash()
        if metadata.get("corpus_hash") == current_hash:
            logger.info(f"✅ 法律向量库已是最新 | 条文: {collection.count()} 条")
            return collection

        # 数据有变化，需要重新加载
        logger.info("🔄 法条库已更新，重新加载向量…")
        client.delete_collection(collection_name)
    except Exception:
        logger.info("🆕 首次创建法律向量库…")

    # 创建新集合并加载数据
    return _build_collection(client, collection_name)


def _build_collection(client: chromadb.ClientAPI, name: str) -> chromadb.Collection:
    """构建法律条文向量集合."""
    corpus_hash = _compute_corpus_hash()

    collection = client.create_collection(
        name=name,
        metadata={
            "description": "中国劳动法核心条文知识库",
            "corpus_hash": corpus_hash,
            "hnsw:space": "cosine",
        },
    )

    # 准备数据
    documents = []
    metadatas = []
    ids = []

    for i, law in enumerate(ALL_LAWS):
        # 文档内容: 法律名 + 条文号 + 内容 + 关键词
        doc_text = (
            f"《{law['law_name']}》{law['article']}\n"
            f"{law['content']}\n"
            f"关键词: {', '.join(law['keywords'])}"
        )
        documents.append(doc_text)

        metadatas.append({
            "law_name": law["law_name"],
            "article": law["article"],
            "category": law.get("category", ""),
            "keywords": ", ".join(law["keywords"]),
        })

        ids.append(f"law_{i:04d}")

    # 批量写入 (ChromaDB 内置 embedding 函数)
    collection.add(
        documents=documents,
        metadatas=metadatas,
        ids=ids,
    )

    logger.info(f"✅ 法律向量库构建完成 | 共 {len(documents)} 条法条")
    return collection


def search_laws(
    query: str,
    n_results: int = 5,
    category: str | None = None,
) -> list[dict]:
    """
    语义检索相关法律条文.

    Args:
        query: 查询文本 (比如合同条款内容)
        n_results: 返回结果数量
        category: 可选的风险分类过滤

    Returns:
        匹配的法条列表, 每条包含 law_name, article, content, score
    """
    collection = get_law_collection()

    # 构建过滤条件
    where = {"category": category} if category else None

    results = collection.query(
        query_texts=[query],
        n_results=n_results,
        where=where,
        include=["documents", "metadatas", "distances"],
    )

    if not results["documents"] or not results["documents"][0]:
        return []

    matches = []
    for doc, meta, distance in zip(
        results["documents"][0],
        results["metadatas"][0],
        results["distances"][0],
    ):
        # ChromaDB cosine distance: 0 = 完全匹配, 2 = 完全不匹配
        similarity = 1 - (distance / 2)

        matches.append({
            "law_name": meta["law_name"],
            "article": meta["article"],
            "content": doc.split("\n")[1] if "\n" in doc else doc,  # 提取纯条文内容
            "keywords": meta.get("keywords", ""),
            "category": meta.get("category", ""),
            "similarity": round(similarity, 4),
        })

    return matches


def init_vector_store() -> None:
    """初始化向量库 (应用启动时调用)."""
    try:
        collection = get_law_collection()
        logger.info(f"⚖️ 法律向量库就绪 | 共 {collection.count()} 条法条可供检索")
    except Exception as e:
        logger.error(f"❌ 向量库初始化失败: {e}")
        raise
