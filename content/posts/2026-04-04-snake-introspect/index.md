---
title: "贪吃蛇望清明"
date: "2026-04-04 19:42:52"
modified: "2026-04-04 22:32:16"
status: publish
published: true
author: "杰西卡尔"
author_bio: "全栈开发者，专注于开发工具和自动化"
excerpt: "探讨Claude Code和dscli工具调用机制，分析大语言模型输出token限制问题及解决方案"
categories: ["技术", "人工智能"]
primary_category: "技术"
tags: ["Claude Code", "dscli", "大语言模型", "工具调用", "token限制"]
tech_stack: ["Docker"]
difficulty: "beginner"
estimated_reading_minutes: 5
meta_title: "贪吃蛇望清明 - Claude Code与dscli工具调用机制分析"
meta_description: "深入分析Claude Code和dscli工具调用机制，探讨大语言模型输出token限制问题及创新解决方案"
og_image: ""
og_description: "探讨Claude Code和dscli工具调用机制，分析大语言模型输出token限制问题及解决方案"
wordpress_post_format: "standard"
table_of_contents: true
license: "CC BY-NC-SA 4.0"
---
---

# 贪吃蛇望清明

## Claude Code 香农渊源

  `Claude Code` 中的 `Claude` 为致敬克劳德·艾尔伍德·香农（Claude
   Elwood Shannon）。香农大多数学术成果在上世纪60年代前完成，然后，他
   就去玩别的去了，具体大概有


    ```
    ╔══════════════════════╗
    ║     机器老鼠闯迷宫    ║
    ║  ┌──────────────┐   ║
    ║  │  🐭 →  🧀     │   ║
    ║  │  │  ┌──┐     │   ║
    ║  │  └──┤  │     │   ║
    ║  │     └──┘     │   ║
    ║  └──────────────┘   ║
    ╚══════════════════════╝
    ```
    香农有篇论文，“介绍一个走迷宫的机器”，1951年。

    ```
    ╔══════════════════════╗
    ║        独轮车        ║
    ║      ╭─────╮        ║
    ║     ╱       ╲       ║
    ║    ╱    ○    ╲      ║
    ║   ╱           ╲     ║
    ║  ╱    🚲       ╲    ║
    ║ ╱               ╲   ║
    ║╱                 ╲  ║
    ╚══════════════════════╝
    ```

    狂热独轮车爱好者！

    ```
    ╔══════════════════════╗
    ║    三球抛接游戏      ║
    ║                      ║
    ║      ●               ║
    ║     ╱ ╲              ║
    ║    ●   ●             ║
    ║   ╱     ╲            ║
    ║  👨      👨          ║
    ║                      ║
    ╚══════════════════════╝
    ```

    最后一次表演在1985年的英国国际信息理论研讨会上。

    > 您无忧无虑的原因是什么？一位采访者在香农临终前采访他，我一生顺其
    > 自然，实用性不是我的主要目标。香农回答。

## 输出超过最大词元数

   ```
   POST /v1/chat/completions
   {
    model:       "",    # 模型
    messages:    {...}  # 上下文
    tools:       {...}  # 工具调用
    max_tokens:  4096   # Deepseek 默认4096
   }
   ```

   API调用时候参数 max tokens 4096 是规定大语言模型的输出词元数，不要
   超过 4096 。大语言模型一般也是想到哪是哪，哪里会管这个。万一超过会
   有一个截断，结束原因设为 length 

   ```json
   POST /v1/chat/completions
   { ... ,  max_tokens: 4096 } # 请求
   {                          # 响应
    id: "..."                 # ID
    choices:
     [{message:
       { role: "assistant",
         content: "...",    # 返回消息, 可能截断
         tool_calls: [...], # 工具调用，可能截断
       },
      finish_reason: "length"},
      {...}],
   }
   ```
## Claude Code对finish_reason=length的应对

   愚人节 Claude Code 源码泄漏，使我们知道它大致的应对

   ```
   1. 第一次遇到finish_reason=length, 假设
     1. max tokens=4096, 那就设 max tokens=8192，然后
     2. 不做任何解释重试，
   2. 8192 其实就是 deepseek 能设 max tokens最大值了，
   3. 重试还遇到finish_reason=length, 那就
      1. 记下截断的content, 并告诉模型
      2. Output token limit hit. Resume directly — no apology,
         no recap of what you were doing. Pick up mid-thought...
   ```

   解释一下 `no apology` 。的确应该道歉，因为输出超过 max tokens，输出
   截断，可能截断在 content ，也可能截断在 tool calls。第一次重试的
   tokens 就等于浪费，用户需要为这些浪费的词元付费。不但如此，第二次又
   截断，而且这次 token 还更多，因为 max tokens 已经设到最大。按情理应
   该道歉。

   但Claude Code Harness说，不必愧疚，不要重述已经做的，从中间开始。

    ```
              ╭─────╮
             ╱  😔  ╲
            ╱  ┌─┐  ╲
           ╱   │ │   ╲
          ╱    └─┘    ╲
         ╱    /   \    ╲
        ╱    /     \    ╲
       ╱    ╱       ╲    ╲
      ╱    ╱         ╲    ╲
     ╱    ╱           ╲    ╲
    ╱    ╱             ╲    ╲
    ╲    ╲             ╱    ╱
     ╲    ╲           ╱    ╱
      ╲    ╲         ╱    ╱
       ╲    ╲       ╱    ╱
        ╲    \     /    ╱
         ╲    \   /    ╱
          ╲    ───    ╱
           ╲         ╱
            ╲       ╱
             ╲     ╱
              ╲   ╱
               ╲ ╱
                V
    ```

## Claude Code Harness

   我理解Claude Code Harness如下

    ```
        ╭───────╮
       ╱         ╲
      ╱    🐎     ╲
     ╱   ┌───┐    ╲
    ╱    │   │     ╲
   ╱     │   │      ╲
  ╱      └───┘       ╲
 ╱      /     \       ╲
╱      /       \       ╲
╲─────╱         ╲──────╱
 ╲   ╱           ╲   ╱
  ╲ ╱             ╲ ╱
   █               █
   █     🚗        █
   █  ┌─────┐      █
   █  │  →  │      █
   █  └─────┘      █
   █               █
   █████████████████
    ```

## 贪吃蛇凯旋

   儿子说，贪吃蛇不能吃个没完，游戏么，要一级一级往上升才有意思，吃到
   100分比如，要有一个凯旋门出来，贪吃蛇可以撤离。

   Dscli 按设计做了。

   儿子说，这一级一级往上升AI也要帮忙才成，靠人谁吃得了100分？太难的游
   戏谁玩？

   Dscli 按设计做了。

   儿子说，要有音效，要有奖励，奖励要有动画。

   Dscli 按设计做，文件越来越大，终于碰到了 finish reason = length 问题

   > Output token limit hit.
   
## Dscli Harness

   穷苦人出身，来自农村理工男，可惜 token 钱，解法与 Claude Code 不同。
   工具调用的设计

    ```
    ╔══════════════════════╗
    ║    🧠 LLM Agent      ║
    ╠══════════════════════╣
    ║  ┌──────────────┐   ║
    ║  │    Args      │←──║
    ║  └──────────────┘   ║
    ║         │           ║
    ║         ▼           ║
    ║  ┌──────────────┐   ║
    ║  │  Tool Call   │   ║
    ║  └──────────────┘   ║
    ║         │           ║
    ║         ▼           ║
    ║   ┌──┐ ┌──┐ ┌──┐   ║
    ║   │✅│ │💡│ │❌│   ║
    ║   └──┘ └──┘ └──┘   ║
    ╚══════════════════════╝
    ```

    在对（✅）错（❌）之间，加了个提示（💡）。把截断的内容修复，当成好
    的用，并提示大语言模型，输出超出max token 上限，内容截断已修复，无
    需道歉，但要感激我帮你改正错误，避免token浪费，下次输出从截断点开
    始，注意不要再次超过。

    千叮咛万嘱咐，帮AI完成大词元输出。这是我理解的Harness，好像本该如此。
