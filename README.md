# reduce-hallucinations

为 Claude Code 默认开启**反幻觉协议**。安装后无需手动触发，Claude 在每次实质性回答前会自动「先取证、再作答、最后自检」。

依据：Anthropic 官方文档《减少幻觉》
<https://platform.claude.com/docs/zh-CN/test-and-evaluate/strengthen-guardrails/reduce-hallucinations>

---

## 快速安装

### macOS / Linux / Git Bash

```bash
git clone https://github.com/Erics-yan/reduce-hallucinations.git
cd reduce-hallucinations
./install.sh
```

### Windows PowerShell

```powershell
git clone https://github.com/Erics-yan/reduce-hallucinations.git
cd reduce-hallucinations
./install.ps1
```

安装脚本做两件事：

1. 把 `skills/factcheck/` 复制到 `~/.claude/skills/factcheck/`
2. 把反幻觉规则**追加**到 `~/.claude/CLAUDE.md`（不存在则创建；已存在不会覆盖原有内容）

重复运行安装脚本是安全的 —— 规则块用 `<!-- factcheck:begin -->` / `<!-- factcheck:end -->` 标记，再次安装会原地更新而不会重复追加。

---

## 安装后的效果

**不需要**用户输入任何命令。Claude 会自动：

- 每次回答前先用工具取证（Read / Grep / WebFetch），不凭记忆
- 引用代码必带 `file:line`，引用文档必带刚抓到的 URL
- 不确定的地方明说「我没有足够信息」而不是编造
- 用户说「真的吗 / 你确定吗 / 核一下」时，自动回头审上一条

同时仍提供两个手动入口（高强度场景用）：

- `/factcheck` — 审上一条回复，输出「声明清单 + 验证结论 + 更正」
- `/factcheck <问题>` — 在严格协议下回答指定问题

---

## 仓库结构

```
reduce-hallucinations/
├── CLAUDE.md                 # 要追加到全局 ~/.claude/CLAUDE.md 的规则片段
├── skills/
│   └── factcheck/
│       └── SKILL.md          # /factcheck 技能定义
├── install.sh                # macOS / Linux / Git Bash 安装脚本
├── install.ps1               # Windows PowerShell 安装脚本
├── uninstall.sh              # 卸载脚本
├── README.md
└── LICENSE
```

---

## 卸载

```bash
./uninstall.sh        # macOS / Linux / Git Bash
```

会移除规则块（保留你 CLAUDE.md 里其他内容）并删除 `~/.claude/skills/factcheck/`。

---

## 适用范围

- Claude Code CLI（任意版本，支持 `~/.claude/` 目录约定）
- 全局生效，所有项目自动应用
- 项目级 `CLAUDE.md` / 用户当次明确指令优先级更高，可临时覆盖

---

## 协议

MIT
