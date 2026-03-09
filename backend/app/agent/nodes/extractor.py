"""
Node A: 结构化抽取节点.

接收 OCR 原始文本，通过大模型进行：
1. 错别字纠错 (OCR 常见问题)
2. 文本重组为结构化条款列表
3. 初步分类每条条款可能关联的风险类别
"""

from __future__ import annotations

import json

from loguru import logger

from app.agent.llm import get_chat_llm
from app.agent.state import AgentState, ExtractedClause
from app.models.analysis import RiskCategory

# ── 结构化提取的系统提示词 ──────────────────────────────────────

EXTRACTOR_SYSTEM_PROMPT = """\
你是一位专业的劳动合同分析助手。你的任务是将 OCR 识别出的劳动合同原始文本进行结构化处理。

## 你需要完成以下工作:

1. **纠错**: OCR 识别可能存在错别字、错误标点、段落断裂等问题，请修正这些错误。
2. **结构化提取**: 将合同文本拆分为独立的条款，每条包含标题和内容。
3. **初步分类**: 判断每条条款是否涉及以下 10 类风险，如果涉及请标注分类:
   - non_compete: 竞业禁止/竞业限制
   - probation_salary: 试用期薪资
   - probation_insurance: 试用期社保
   - salary_deduction: 扣薪/罚款条款
   - job_description: 岗位职责/工作内容
   - obedience_clause: 服从安排/无条件调岗
   - resignation: 离职/辞职条件
   - leave_rights: 休假/年假/病假
   - jurisdiction: 争议管辖/仲裁地
   - training_bond: 培训服务期/违约金

## 输出格式要求:
请严格以 JSON 数组的形式输出，每个元素包含:
- clause_index: 条款序号 (从 1 开始, 整数)
- title: 条款标题 (字符串)
- content: 条款完整内容 (已纠错, 字符串)
- category: 风险分类 (如果不涉及上述分类，设为 null)

只输出合法的 JSON 数组，不要添加 markdown 代码块标记或任何额外说明。
"""


async def extract_clauses(state: AgentState) -> AgentState:
    """
    Node A: 结构化提取节点.

    将 OCR 原始文本转换为结构化条款列表。
    """
    logger.info(f"📝 [Node A] 开始结构化提取 | 合同ID: {state.contract_id}")
    state.current_node = "extractor"

    try:
        raw = state.raw_text.strip()
        llm = get_chat_llm()

        # 调用大模型进行结构化提取
        messages = [
            {"role": "system", "content": EXTRACTOR_SYSTEM_PROMPT},
            {"role": "user", "content": f"请对以下劳动合同文本进行结构化提取:\n\n{raw}"},
        ]

        response = await llm.ainvoke(messages)
        content = response.content.strip()

        # 清理可能的 markdown 代码块标记
        if content.startswith("```"):
            content = content.split("\n", 1)[-1]
        if content.endswith("```"):
            content = content.rsplit("```", 1)[0]
        content = content.strip()

        # 解析 JSON
        parsed = json.loads(content)

        clauses: list[ExtractedClause] = []
        for item in parsed:
            category = None
            if item.get("category"):
                try:
                    category = RiskCategory(item["category"])
                except ValueError:
                    logger.warning(f"  ⚠️ 未知分类: {item['category']}, 跳过")

            clauses.append(
                ExtractedClause(
                    clause_index=item["clause_index"],
                    title=item["title"],
                    content=item["content"],
                    category=category,
                )
            )

        state.corrected_text = raw
        state.extracted_clauses = clauses

        logger.info(f"✅ [Node A] 提取完成 | 共 {len(clauses)} 条条款")

    except json.JSONDecodeError as e:
        error_msg = f"[Node A] LLM 返回的 JSON 解析失败: {e}"
        logger.error(error_msg)
        state.errors.append(error_msg)

        # 降级: 简单段落分割
        logger.info("  ⬇️ 降级为段落分割模式")
        paragraphs = [p.strip() for p in raw.split("\n\n") if p.strip()]
        state.extracted_clauses = [
            ExtractedClause(
                clause_index=i,
                title=p.split("\n", 1)[0][:50],
                content=p,
                category=None,
            )
            for i, p in enumerate(paragraphs, 1)
        ]

    except Exception as e:
        error_msg = f"[Node A] 结构化提取失败: {e}"
        logger.error(error_msg)
        state.errors.append(error_msg)

        # 降级
        paragraphs = [p.strip() for p in raw.split("\n\n") if p.strip()]
        state.extracted_clauses = [
            ExtractedClause(
                clause_index=i,
                title=p.split("\n", 1)[0][:50],
                content=p,
                category=None,
            )
            for i, p in enumerate(paragraphs, 1)
        ]

    return state
