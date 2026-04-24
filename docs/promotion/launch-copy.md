# ChatType Launch Copy

Use this as source material. Adapt each post to the platform instead of copying the same text everywhere.

## Core Positioning

One-liner:

> ChatType lets ChatGPT/Codex Desktop users on macOS press F5, speak, and paste the transcript into the current input box when safe.

Short description:

> ChatType is a native macOS menu bar dictation app for people who already use ChatGPT or Codex Desktop on the same Mac. The default path uses the local desktop login state, so the normal workflow does not require a separate API key or local model download. It records with a single F5 trigger, transcribes, then pastes only when a focused editable target is detected. If paste is not safe, the result stays in the clipboard for manual Cmd+V.

Risk boundary:

> ChatType v1 depends on a local signed-in desktop session and an upstream private transcription path. It is a personal productivity tool, not a stable enterprise API integration.

## Xiaohongshu Note 1: Pain Point

Title options:

- 我受够了在 Codex 里手打长句，做了个 F5 语音输入
- Mac 上用 ChatGPT/Codex，我想要一个最短的语音输入路径
- 不想多买听写订阅：F5 说话，自动回填

Body:

> 我经常在 Codex / ChatGPT Desktop 里写很长的中文需求，手打会打断思路。
>
> 所以做了一个很小的 macOS 工具：ChatType。
>
> 路径很直接：
>
> 1. 光标放到 Codex、Notes、Slack、Mail 等输入框
> 2. 按 F5 开始录音
> 3. 再按 F5 停止
> 4. 有可编辑输入框就回填，没有就留在剪贴板
>
> 它不是另一个聊天应用，也不是企业 API 封装。默认就是复用这台 Mac 上已经登录的 ChatGPT/Codex Desktop 状态。
>
> 我现在先把它作为开源项目放出来，想找同样在 Mac 上高频用 AI 工具的人试试：这个路径是否真的更顺手？
>
> GitHub: https://github.com/longbiaochen/chat-type

Tags:

`#Mac效率工具 #ChatGPT #Codex #AI工具 #开源项目 #语音输入 #独立开发`

## Xiaohongshu Note 2: Demo

Title options:

- 30 秒看懂 ChatType：F5 录音，F5 停止，结果回填
- 给 Mac 做了一个极简听写工具，专门服务 ChatGPT/Codex
- 光标在这里，声音就到这里：我的 F5 工作流

Body:

> 这是 ChatType 的最小使用路径：
>
> - 装到 `/Applications/ChatType.app`
> - 登录好 ChatGPT/Codex Desktop
> - 第一次录音给麦克风权限
> - 想自动回填就给 Accessibility 权限
> - F5 开始，F5 结束
>
> 我刻意把粘贴做得保守：只有检测到当前焦点是可编辑输入框时才粘贴。否则不会乱打字，只把最终文本留在剪贴板，手动 Cmd+V 就行。
>
> v0.1.2 还加了 TypeWhisper 术语导入，适合经常念工具名、文件名、项目名的人。
>
> 下载和代码都在 GitHub release。

Tags:

`#Mac软件 #效率工具 #ChatGPT技巧 #Codex #语音转文字 #AI工作流`

## Xiaohongshu Note 3: Builder Story

Title options:

- 为什么我只给 ChatType 设计一个按键：F5
- 一个很窄的开源 Mac 工具：只解决说话到输入框
- 做 ChatType 时，我删掉了很多“看起来更完整”的功能

Body:

> ChatType 不是想做全能听写平台。
>
> 我给它设了几个很窄的边界：
>
> - 一个触发键：F5 开始，F5 停止
> - 默认不要求 API key
> - 默认不下载本地模型
> - 不在主路径里做第二轮 AI 清洗
> - 不确定能不能粘贴时，只放剪贴板
>
> 这些限制反而让它更像一个每天能用的小工具。
>
> 如果你也在 Mac 上用 ChatGPT/Codex 写需求、写邮件、写笔记，欢迎试一下，也欢迎直接提 issue。
>
> GitHub: https://github.com/longbiaochen/chat-type

Tags:

`#独立开发 #开源 #Mac效率 #产品设计 #AI工具 #ChatGPT`

## Jike

> 做了一个很窄的开源 Mac 工具：ChatType。
>
> 面向已经在本机登录 ChatGPT/Codex Desktop 的人。按 F5 录音，再按 F5 停止；检测到当前焦点是输入框就回填，否则留在剪贴板。
>
> 我不想把它包装成泛用 AI SaaS。它就是解决一个日常痛点：在 Codex、ChatGPT、Notes、Slack 里想说长段中文时，不想慢慢打。
>
> GitHub: https://github.com/longbiaochen/chat-type

## V2EX

Node: `分享创造`

Title:

> [开源] ChatType：给 macOS + ChatGPT/Codex Desktop 做的 F5 听写回填工具

Body:

> 大家好，我做了一个很窄的 macOS 菜单栏工具：ChatType。
>
> 它面向已经在这台 Mac 上登录 ChatGPT / Codex Desktop 的用户，目标是把 `F5 -> 说话 -> 回填` 这条链路做短。
>
> 当前行为：
>
> - F5 开始录音，F5 停止录音
> - 默认复用本机桌面登录态，不要求单独 API key
> - 检测到当前焦点是可编辑目标时才粘贴
> - 如果不适合粘贴，就把最终文本留在剪贴板
> - v0.1.2 支持从 TypeWhisper 导入术语表，做本地确定性术语对齐
>
> 明确边界：
>
> - 依赖本机已登录的 ChatGPT/Codex Desktop 状态
> - 不是稳定公开 API，也不是企业级集成
> - 目前是本地签名、未 notarize 的 macOS app
>
> GitHub: https://github.com/longbiaochen/chat-type
> Landing page: https://longbiaochen.github.io/chat-type/
>
> 想请大家帮忙试两个点：第一，F5 这个单键录音/停止是否顺手；第二，保守粘贴/剪贴板兜底是否比“总是粘贴”更符合预期。

## Zhihu / Juejin Long Form Outline

Title:

> 为什么我做了一个只服务 F5 的 Mac 听写工具

Structure:

1. Problem: long prompts and Chinese notes are slow to type in Codex/ChatGPT.
2. Constraint: existing desktop login is already there; avoid adding a second subscription or local model.
3. Product choice: one global trigger, no floating feature pile.
4. Safety choice: paste only into editable targets; clipboard fallback otherwise.
5. Technical boundary: private desktop transcription path, not a public API promise.
6. Current release: v0.1.2, TypeWhisper terminology import, GitHub release.
7. Feedback request: F5 workflow, permission onboarding, paste behavior, terminology accuracy.

## Hacker News

Wait until the release page, landing page, README, install instructions, and demo are ready.

Title:

> Show HN: ChatType - F5 dictation for ChatGPT/Codex desktop users on macOS

Maker comment:

> I built ChatType because I often write long Chinese prompts and notes in Codex/ChatGPT Desktop and wanted a shorter path than typing everything by hand.
>
> It is a native macOS menu bar app. Press F5 to start recording, press F5 again to stop, then it transcribes through the local desktop login path and pastes only when the focused target looks editable. Otherwise it leaves the transcript in the clipboard.
>
> The main caveat is important: this v1 depends on a signed-in local ChatGPT/Codex Desktop session and an upstream private transcription path. I am not presenting it as a stable public API integration.
>
> I would especially like feedback on the interaction model: single F5 trigger, conservative paste behavior, and permission onboarding.

## Product Hunt

Tagline:

> F5 dictation for ChatGPT/Codex Desktop users on macOS

Description:

> ChatType is a native macOS menu bar app that turns F5 into a fast speak-to-paste workflow for people already using ChatGPT or Codex Desktop. It records, transcribes through the local desktop login path, pastes only when a focused editable target is detected, and keeps the result in the clipboard when paste is not safe.

Maker comment:

> I built ChatType for my own daily AI workflow on macOS. The problem was simple: long prompts and Chinese notes take too much attention to type, especially while using Codex or ChatGPT Desktop.
>
> ChatType keeps the path intentionally narrow: F5 starts recording, F5 stops, and the transcript goes into the current input box only when that is safe. If not, it stays in the clipboard.
>
> This is not a general-purpose SaaS launch. The v1 default path depends on a local signed-in ChatGPT/Codex Desktop session, so I am keeping that limitation explicit and looking for feedback from users with the same setup.

## AI Directory Submission Fields

Name:

> ChatType

Website:

> https://longbiaochen.github.io/chat-type/

GitHub:

> https://github.com/longbiaochen/chat-type

Category:

> Productivity, Speech to Text, macOS, Developer Tools

Short description:

> Native macOS F5 dictation for ChatGPT/Codex Desktop users, with safe paste and clipboard fallback.

Long description:

> ChatType is an open-source macOS menu bar dictation app for people who already use ChatGPT or Codex Desktop on the same Mac. Press F5 to record, press F5 again to stop, then ChatType transcribes through the local desktop login path and pastes only when the focused target is editable. If paste is not safe, the transcript remains in the clipboard for manual Cmd+V. It also supports local TypeWhisper terminology import for deterministic post-transcription term alignment.

Pricing:

> Free / Open source

Limitations:

> Requires macOS and a local signed-in ChatGPT/Codex Desktop session for the default path. Advanced OpenAI-compatible recovery is available for users who configure their own endpoint and credentials.
