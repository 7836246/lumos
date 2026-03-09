# ✨ Lumos · 契光鉴微 —— 技术设计方案

> 版本：v0.4.0
> 日期：2026-03-09
> 状态：架构调整 (Flutter 客户端 + Python AI 服务端)
> 设计原则：**端侧顺滑体验、强悍的 AI Agent 大脑、数据隐私优先**

---

## 1. 为什么采用「Flutter 前端 + Python 后端」的双栈工作流？

在反复推演打工人的实际使用场景后，我们确立了系统的终极形态：**一个需要具备"复杂法律分析思考"能力的强大 Agent。** 

因此我们选择了**最优解组合**：
1. **APP 客户端 (Flutter)**：负责颜值、动画、跨平台、拍照、以及第一层**端侧 OCR 脱敏**（极度重要，保证用户真实隐私不上传）。
2. **AI 后端引擎 (Python + FastAPI)**：负责深度的 AI Agent 思考链路。因为排查合同不是简单的一问一答，而是复杂的流式分析（提取信息 -> 检索劳动法条款库 (RAG) -> 多轮论证 -> 得出严谨的谈判话术）。这个场景下，Python 生态（LangGraph, PydanticAI）的工程化能力碾压其他语言。

---

## 2. 核心技术栈

### 2.1 客户端 (Client-Side) - 极致感官篇
| 层 | 库/方案 | 作用与优势 |
|--------|--------|------------|
| **UI 框架** | **Flutter 3.x (Dart)** | Impeller 引擎提供丝滑的扫描光效动画。 |
| **状态/路由**| **Riverpod + go_router**| 类型安全的状态管理与深度链接。 |
| **硬件能力** | **camera + mlkit** | 调取镜头，利用 ML Kit 实现强大的全本地 OCR。 |
| **网络请求** | **Dio** | 与 Python 后端进行 HTTP/SSE (Server-Sent Events) 流式通信。 |
| **本地缓存** | **sqflite** | 离线缓存历史审查记录。 |

### 2.2 服务端 (Server-Side) - 智能大脑篇
| 层 | 库/方案 | 作用与优势 |
|--------|--------|------------|
| **基础框架** | **FastAPI (Python 3.12)**| 速度极快，自带 Swagger 文档，与 Pydantic 完美契合。 |
| **AI 编排** | **LangGraph / PydanticAI** | 支持构建循环节点（Cyclic Graphs），让模型"懂思考、会改错"。 |
| **模型对接** | **LangChain / OpenAI SDK** | 无缝支持 DeepSeek、Claude、通义千问等兼容性接口。 |
| **文档进阶** | **LlamaIndex** | 用于复杂 PDF/Word 版式的提取与知识图谱构建。 |
| **数据库** | **SQLModel (SQLite/PG)** | FastAPI 原生作者开发的 ORM，无缝对接。 |

---

## 3. 系统架构设计

系统设计为云管端（Cloud/Client）架构：

```text
┌────────────────────────────────────────────────────────┐
│               Lumos Client (Flutter APP)               │
│                                                        │
│  [UI 表现层] 扫描合同 -> 播放极光动画 -> 展示风险卡片       │
│                                                        │
│  [端侧前置层] camera -> mlkit (OCR) -> 脱密正则替换       │
│                                                        │
│  [通信层] Dio Streaming (SSE接收分析过程)                │
└──────────────────────────┬─────────────────────────────┘
                           │ (脱敏后的合同纯文本)
                           ▼
┌────────────────────────────────────────────────────────┐
│               Lumos Server (Python AI Agent)           │
│                                                        │
│  [API 网关] FastAPI Endpoints                          │
│                                                        │
│  [Agent 思考引擎 (LangGraph / PydanticAI)]               │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 1. 结构化抽取 Node: 将乱序文本抽取为标准字段表单        │  │
│  │ 2. 法规检索 Node (RAG): 根据提取的关键点查询判例库      │  │
│  │ 3. 风险审查 Node: 多维度打分并生成谈判话术            │  │
│  │ 4. 输出格式化 Node: 严格转为 JSON Stream 吐出前端      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  [数据持久化] SQLModel (User Contracts / Chat History)   │
└────────────────────────────────────────────────────────┘
```

---

## 4. 核心工作流大解剖

### 步骤一：端侧智能脱敏 (Flutter 端)
APP 调用摄像头连续排下合同 1-10 页。`google_mlkit` 在**手机本地（完全不消耗网络）**识别出文字。
在把文本发给 Python 后端前，Flutter 端执行前置函数：
`TextCleaner.maskSensitive(text)` -> 将所有身份信息、银行卡、疑似私人公章抹除。

### 步骤二：流式上传与 Agent 启动 (Python 端)
FastAPI 接收到脱敏文本，触发 LangGraph 的工作流起点。
**之所以选 LangGraph，是因为合同审核必须严谨，一步不能错：**
- **Node A (纠错与对齐)**：大模型把 OCR 可能识别错的错别字修正，组合成结构化条款。
- **Node B (RAG 法规对照)**：大模型发现"试用期薪资 70%"，立刻挂起，去后台的向量数据库查询《劳动合同法》，确认为违法。
- **Node C (话术生成)**：基于上述结论，自动生成给 HR 的建议话术。

### 步骤三：SSE 流式响应与动画呈现 (双端配合)
Python 后端使用 Server-Sent Events (SSE) 将 Agent 思考的进度、风险的级别一点点推给前端。
Flutter 前端利用接收到的流，配合 `AnimationController`，在屏幕上挨个点亮红黄绿灯，给用户呈现极具科技感的"排雷"过程。

---

## 5. 目录结构规划

我们采用 Monorepo 思想，将前后端放于同一仓库：

```
lumos/
├── README.md
├── docs/                   # 文档
├── backend/                # Python 服务端
│   ├── app/
│   │   ├── api/            # FastAPI 路由 Controllers
│   │   ├── agent/          # LangGraph 核心智能体链
│   │   │   ├── nodes/      # 拆分的单步逻辑
│   │   │   └── tools/      # RAG 检索等自定义大模型工具
│   │   ├── core/           # 设置与 DB 连接
│   │   └── models/         # SQLModel 数据校验
│   ├── pyproject.toml      # Poetry / uv
│   └── Dockerfile
│
└── client/                 # Flutter 客户端
    ├── android/
    ├── ios/
    ├── lib/
    │   ├── core/           # 主题、路由、API Client
    │   ├── features/       # 业务模块 (scanner, report)
    │   └── shared/         # Widget 库
    └── pubspec.yaml
```

---

## 6. 后续规划

- **部署极简性**：后端使用现代化的 `uv` 搭配 Docker，一行代码 `docker-compose up` 就能在服务器启动专属的 AI 大脑。
- **本地降级方案**：未来可通过让 Python 节点直接调用本地的 Ollama，实现彻底的本地私海域审查。
