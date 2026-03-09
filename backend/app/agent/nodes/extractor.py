"""
Node A: 结构化抽取节点.

接收 OCR 原始文本，通过大模型进行：
1. 错别字纠错 (OCR 常见问题)
2. 文本重组为结构化条款列表
3. 初步分类每条条款可能关联的风险类别
"""

from __future__ import annotations

from loguru import logger

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
请以 JSON 数组的形式输出，每个元素包含:
- clause_index: 条款序号 (从 1 开始)
- title: 条款标题
- content: 条款完整内容 (已纠错)
- category: 风险分类 (如果不涉及上述分类，设为 null)

只输出 JSON，不要添加任何额外说明。
"""


async def extract_clauses(state: AgentState) -> AgentState:
    """
    Node A: 结构化提取节点.

    将 OCR 原始文本转换为结构化条款列表。
    当前为骨架实现，后续接入 LLM 进行真正的智能提取。
    """
    logger.info(f"📝 [Node A] 开始结构化提取 | 合同ID: {state.contract_id}")
    state.current_node = "extractor"

    try:
        raw = state.raw_text.strip()

        # ── TODO: 接入 LLM 进行智能结构化提取 ──
        # 当前使用简单的段落分割作为占位实现
        # 正式版将调用: langchain_openai.ChatOpenAI + 结构化输出

        paragraphs = [p.strip() for p in raw.split("\n\n") if p.strip()]

        clauses: list[ExtractedClause] = []
        for i, paragraph in enumerate(paragraphs, start=1):
            # 简单启发式: 尝试从段落中提取标题
            lines = paragraph.split("\n", 1)
            title = lines[0][:50] if lines else f"条款 {i}"
            content = paragraph

            clauses.append(
                ExtractedClause(
                    clause_index=i,
                    title=title,
                    content=content,
                    category=None,  # LLM 接入后会自动分类
                )
            )

        state.corrected_text = raw
        state.extracted_clauses = clauses

        logger.info(f"✅ [Node A] 提取完成 | 共 {len(clauses)} 条条款")

    except Exception as e:
        error_msg = f"[Node A] 结构化提取失败: {e}"
        logger.error(error_msg)
        state.errors.append(error_msg)

    return state
