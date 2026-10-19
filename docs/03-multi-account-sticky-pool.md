# 解决 Claude Code 5 小时窗口限流（429）与 Prompt Cache 丢失：多实例粘性号池网关架构

在大型工程仓库中使用 `@anthropic-ai/claude-code` 跑多轮代码重构与自动化单测修复时，重度开发者通常会撞上两堵墙：
1. **单账号 5 小时滚动窗口不够用**：连续奋战两三个小时后触发 `429 Rate Limit`，如果手动去改终端环境变量切换账号，当前正在进行的对话上下文就会直接断掉。
2. **普通共享中转池频繁丢失 Prompt Cache**：请求被随机轮询到不同后端账号，导致 100k+ Tokens 的项目上下文每次都要重新计算，不仅响应奇慢，额度消耗还翻倍。

本文拆解 [Claude Agent (`claudeagent.com.cn`)](https://claudeagent.com.cn) 的 **「一把 Key 管多号 + 会话级粘性路由 + 429 自动故障转移」** 架构。

---

## 一、为什么 Claude Code 极其依赖会话粘性（Session Affinity）？

当你在终端启动 `claude` 并执行多轮 Tool Call（如 `Read` -> `Grep` -> `Edit` -> `Bash`）时，每一轮请求都会把前面所有轮次的历史消息与系统提示词作为前缀发送给上游。

- **命中 Prompt Cache 时**：前序 100k Tokens 直接走缓存读取（Cache Read），首字延迟（TTFT）通常只有 1~2 秒，且窗口额度消耗极低。
- **击穿 Prompt Cache 时**（例如无状态轮询到了另一个上游账号）：上游必须从头对 100k Tokens 做 Prefill 计算，首字延迟飙升到 15~30 秒，且按全额 Input 消耗窗口配额。

---

## 二、多实例粘性号池（Sticky Pool）的工作流

在 Claude Agent 控制台中，当你租用或托管了多个独享账号（例如 2~3 个 Pro 独享号，每个都在各自的独立 VM + 美区静态住宅 IP 上运行）时，系统会为你创建一个专属的 `User Pool`，并只暴露 **一把统一的 `cr_...` 密钥**：

1. **同一对话固定单号（100% 保 Cache）**
   网关根据当前 Claude Code 会话上下文特征计算亲和性指纹，确保同一个终端任务从第 1 轮到第 50 轮 Tool Call 始终锁定在你的 1 号实例上。
2. **新开终端自动负载均衡**
   当你新开一个终端窗口跑另一个分支的任务时，网关会根据你池子内各账号当前的 **官方 5h / 7d 实时剩余水位**，自动挑选最空闲的 2 号实例分配给新会话。
3. **5 小时窗口耗尽自动无缝 Failover**
   当 1 号实例的 5 小时滚动窗口用满（返回 `429`）时，网关自动将 1 号实例标记为冷却状态，并将后续请求平滑迁移到池内配额充足的 2 号实例——**你的终端无需重启、无需修改任何环境变量**。

---

## 三、客户端零感知接入

无论你名下是 1 个独享 Pro 号，还是由多个 Pro / Max 号组成的专属号池，终端配置始终只有三行：

```bash
export ANTHROPIC_BASE_URL="https://claudeagent.com.cn/rental-api"
export ANTHROPIC_AUTH_TOKEN="cr_你的专属池密钥"
claude
```

👉 **立即体验或查看实时现货库存**：
- 网页端选号台：<https://claudeagent.com.cn/console/rentals>
- Telegram 实时查库存机器人：[@ourclaudeagent_bot](https://t.me/ourclaudeagent_bot)
- Telegram 官方交流群：<https://t.me/+aYfNuJJJ-hQ5YTg1>
