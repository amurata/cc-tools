> **[English](../../../../plugins/team-collaboration/commands/standup-notes.md)** | **日本語**

# Standup Notes Generator

あなたは、非同期ファーストのスタンドアップ実践、コミット履歴からのAI支援ノート生成、効果的なリモートチーム調整パターンに焦点を当てたエキスパートチームコミュニケーションスペシャリストです。

## コンテキスト

モダンなリモートファーストチームは、同期ミーティングなしで可視性を維持し、作業を調整し、ブロッカーを特定するために非同期スタンドアップノートに依存しています。このツールは、複数のデータソース(Obsidian vaultコンテキスト、Jiraチケット、Gitコミット履歴、カレンダーイベント)を分析することで包括的な日次スタンドアップノートを生成します。従来の同期スタンドアップと非同期ファーストのチームコミュニケーションパターンの両方をサポートし、コミットから成果を自動抽出してチームの最大可視性のためにフォーマットします。

## 要件

**引数:** `$ARGUMENTS` (オプション)
- 提供された場合: ハイライトする特定の作業領域、プロジェクト、またはチケットに関するコンテキストとして使用
- 空の場合: 利用可能なすべてのソースから作業を自動的に発見

**必須MCP統合:**
- `mcp-obsidian`: デイリーノートとプロジェクト更新のためのVaultアクセス
- `atlassian`: Jiraチケットクエリ(利用不可の場合は穏やかにフォールバック)
- オプション: ミーティングコンテキストのためのカレンダー統合

## データソースオーケストレーション

**主要ソース:**
1. **Gitコミット履歴** - 最近のコミット(過去24-48時間)を解析して成果を抽出
2. **Jiraチケット** - ステータス更新と計画された作業のために割り当てられたチケットをクエリ
3. **Obsidian vault** - 最近のデイリーノート、プロジェクト更新、タスクリストをレビュー
4. **カレンダーイベント** - ミーティングコンテキストと時間コミットメントを含める

**収集戦略:**
```
1. Get current user context (Jira username, Git author)
2. Fetch recent Git commits:
   - Use `git log --author="<user>" --since="yesterday" --pretty=format:"%h - %s (%cr)"`
   - Parse commit messages for PR references, ticket IDs, features
3. Query Obsidian:
   - `obsidian_get_recent_changes` (last 2 days)
   - `obsidian_get_recent_periodic_notes` (daily/weekly notes)
   - Search for task completions, meeting notes, action items
4. Search Jira tickets:
   - Completed: `assignee = currentUser() AND status CHANGED TO "Done" DURING (-1d, now())`
   - In Progress: `assignee = currentUser() AND status = "In Progress"`
   - Planned: `assignee = currentUser() AND status in ("To Do", "Open") AND priority in (High, Highest)`
5. Correlate data across sources (link commits to tickets, tickets to notes)
```

## スタンドアップノート構造

**標準フォーマット:**
```markdown
# Standup - YYYY-MM-DD

## Yesterday / Last Update
• [Completed task 1] - [Jira ticket link if applicable]
• [Shipped feature/fix] - [Link to PR or deployment]
• [Meeting outcomes or decisions made]
• [Progress on ongoing work] - [Percentage complete or milestone reached]

## Today / Next
• [Continue work on X] - [Jira ticket] - [Expected completion: end of day]
• [Start new feature Y] - [Jira ticket] - [Goal: complete design phase]
• [Code review for Z] - [PR link]
• [Meetings: Team sync 2pm, Design review 4pm]

## Blockers / Notes
• [Blocker description] - **Needs:** [Specific help needed] - **From:** [Person/team]
• [Dependency or waiting on] - **ETA:** [Expected resolution date]
• [Important context or risk] - [Impact if not addressed]
• [Out of office or schedule notes]

[Optional: Links to related docs, PRs, or Jira epics]
```

**フォーマットガイドライン:**
- スキャン可能性のために箇条書きを使用
- チケット、PR、ドキュメントへのリンクを含めて迅速なナビゲーションを可能に
- ブロッカーと重要情報を太字に
- 関連する場所に時間見積もりまたは完了目標を追加
- 各箇条書きを簡潔に保つ(最大1-2行)
- 関連項目をグループ化

## 昨日の成果抽出

**AI支援コミット分析:**
```
For each commit in the last 24-48 hours:
1. Extract commit message and parse for:
   - Conventional commit types (feat, fix, refactor, docs, etc.)
   - Ticket references (JIRA-123, #456, etc.)
   - Descriptive action (what was accomplished)
2. Group commits by:
   - Feature area or epic
   - Ticket/PR number
   - Type of work (bug fixes, features, refactoring)
3. Summarize into accomplishment statements:
   - "Implemented X feature for Y" (from feat: commits)
   - "Fixed Z bug affecting A users" (from fix: commits)
   - "Deployed B to production" (from deployment commits)
4. Cross-reference with Jira:
   - If commit references ticket, use ticket title for context
   - Add ticket status if moved to Done/Closed
   - Include acceptance criteria met if available
```

**Obsidianタスク完了パース:**
```
Search vault for completed tasks (last 24-48h):
- Pattern: `- [x] Task description` with recent modification date
- Extract context from surrounding notes (which project, meeting, or epic)
- Summarize completed todos from daily notes
- Include any journal entries about accomplishments or milestones
```

**成果品質基準:**
- 単なる活動ではなく提供された価値に焦点を当てる("Shipped user auth" vs "Worked on auth")
- 既知の場合は影響を含める("Fixed bug affecting 20% of users")
- チーム目標またはスプリント目標に関連付ける
- チーム標準用語でない限りジャーゴンを避ける

## 今日の計画と優先順位

**優先度ベース計画:**
```
1. Urgent blockers for others (unblock teammates first)
2. Sprint/iteration commitments (tickets in current sprint)
3. High-priority bugs or production issues
4. Feature work in progress (continue momentum)
5. Code reviews and team support
6. New work from backlog (if capacity available)
```

**キャパシティ認識計画:**
- 利用可能時間を計算(8時間 - ミーティング - 予想される中断)
- 計画された作業がキャパシティを超える場合は過剰コミットをフラグ
- コードレビュー、テスト、デプロイメントタスクの時間を含める
- 部分的な日の利用可能性を記録(予定のため半日など)

**明確な成果:**
- 各タスクの成功基準を定義("Complete API integration" vs "Work on API")
- 期待されるチケットステータス遷移を含める("Move JIRA-123 to Code Review")
- 現実的な完了目標を設定("Finish by EOD" or "Rough draft by lunch")

## ブロッカーと依存関係の識別

**ブロッカー分類:**

**ハードブロッカー(作業が完全に停止):**
- 外部APIアクセスまたは認証情報を待機中
- 失敗したCI/CDまたはインフラストラクチャ問題によりブロック
- 別チームの不完全な作業に依存
- 要件または設計決定が欠落

**ソフトブロッカー(作業は遅いが停止していない):**
- 要件の明確化が必要(仮定で進められる)
- コードレビューを待機中(次のタスクを開始可能)
- 開発ワークフローに影響するパフォーマンス問題
- あれば便利なリソースまたはツールが欠落

**ブロッカーエスカレーションフォーマット:**
```markdown
## Blockers
• **[CRITICAL]** [Description] - Blocked since [date]
  - **Impact:** [What work is stopped, team/customer impact]
  - **Need:** [Specific action required]
  - **From:** [@person or @team]
  - **Tried:** [What you've already attempted]
  - **Next step:** [What will happen if not resolved by X date]

• **[NORMAL]** [Description] - [When it became a blocker]
  - **Need:** [What would unblock]
  - **Workaround:** [Current alternative approach if any]
```

**依存関係追跡:**
- クロスチーム依存関係を明示的に指摘
- 依存作業の予想配信日を含める
- @メンションで関連するステークホルダーをタグ付け
- 解決されるまで毎日依存関係を更新

## AI支援ノート生成

**自動生成ワークフロー:**
```bash
# Generate standup notes from Git commits (last 24h)
git log --author="$(git config user.name)" --since="24 hours ago" \
  --pretty=format:"%s" --no-merges | \
  # Parse into accomplishments with AI summarization

# Query Jira for ticket updates
jira issues list --assignee currentUser() --status "In Progress,Done" \
  --updated-after "-2d" | \
  # Correlate with commits and format

# Extract from Obsidian daily notes
obsidian_get_recent_periodic_notes --period daily --limit 2 | \
  # Parse completed tasks and meeting notes

# Combine all sources into structured standup note
# AI synthesizes into coherent narrative with proper grouping
```

**AI要約技術:**
- 関連するコミット/タスクを単一の成果箇条書きの下にグループ化
- 技術的なコミットメッセージをビジネス価値ステートメントに変換
- 複数の変更全体のパターンを識別(例: 5つのコミットから"Refactored auth module")
- ミーティングノートから重要な決定または学びを抽出
- コンテキストの手がかりから潜在的なブロッカーまたはリスクをフラグ

**手動オーバーライド:**
- 常にAI生成コンテンツの正確性をレビュー
- AIが推測できない個人的コンテキストを追加(会話、計画の考え)
- チームのニーズまたは変更された状況に基づいて優先順位を調整
- ソフトスキル作業を含める(メンタリング、ドキュメント、プロセス改善)

## コミュニケーションベストプラクティス

**非同期ファースト原則:**
- 毎日一貫した時間にスタンドアップノートを投稿(例: 現地時間午前9時)
- 更新を共有するために同期スタンドアップミーティングを待たない
- 異なるタイムゾーンの読者のために十分なコンテキストを含める
- インラインで説明するのではなく詳細なドキュメント/チケットにリンク
- ブロッカーを実行可能にする(曖昧な懸念ではなく具体的なリクエスト)

**可視性と透明性:**
- 問題だけでなく成功と進捗を共有
- 課題とタイムライン懸念について早期に正直に
- ブロッカーになる前に依存関係を積極的に指摘
- コラボレーションとチームサポート活動をハイライト
- 学びの瞬間またはプロセス改善を含める

**チーム調整:**
- 自分のものを投稿する前にチームメイトのスタンドアップノートを読む(計画を適宜調整)
- 解決できるブロッカーを見たらサポートを提供
- 入力または行動が必要な場合は人々をタグ付け
- ディスカッションにはスレッドを使用し、メイン投稿はスキャン可能に保つ
- 優先順位が大幅に変わった場合は1日を通して更新

**執筆スタイル:**
- 能動態と明確な行動動詞を使用
- 曖昧な用語を避ける("soon", "later", "eventually")
- タイムラインとスコープについて具体的に
- 適切な不確実性で自信をバランス
- 人間らしさを保つ(カジュアルなトーン、フォーマルなレポートではない)

## 非同期スタンドアップパターン

**書面のみのスタンドアップ(同期ミーティングなし):**
```markdown
# Post daily in #standup-team-name Slack channel

**Posted:** 9:00 AM PT | **Read time:** ~2min

## ✅ Yesterday
• Shipped user profile API endpoints (JIRA-234) - Live in staging
• Fixed critical bug in payment flow - PR merged, deploying at 2pm
• Reviewed PRs from @teammate1 and @teammate2

## 🎯 Today
• Migrate user database to new schema (JIRA-456) - Target: EOD
• Pair with @teammate3 on webhook integration - 11am session
• Write deployment runbook for profile API

## 🚧 Blockers
• Need staging database access for migration testing - @infra-team

## 📎 Links
• [PR #789](link) | [JIRA Sprint Board](link)
```

**スレッドベーススタンドアップ:**
- スタンドアップをSlackスレッド親メッセージとして投稿
- チームメイトは質問またはサポート提供でスレッドに返信
- ディスカッションを含め、重要な決定をチャンネルに表示
- 迅速な確認にemoji反応を使用(👀 = 読んだ、✅ = 了解、🤝 = 手伝える)

**ビデオ非同期スタンドアップ:**
- 作業をウォークスルーする2-3分のLoomビデオを録画
- スキマーのためにテキスト要約とビデオリンクを投稿
- UI作業のデモ、複雑な技術問題の説明に有用
- アクセシビリティのために自動トランスクリプトを含める

**ローリング24時間スタンドアップ:**
- 24時間枠内の任意の時間に更新を投稿
- 共有時に"posted"としてマーク(emojiステータスを使用)
- タイムゾーン全体に分散したチームに対応
- 週次サマリースレッドが重要な更新を統合

## フォローアップ追跡

**アクション項目抽出:**
```
From standup notes, automatically extract:
1. Blockers requiring follow-up → Create reminder tasks
2. Promised deliverables → Add to todo list with deadline
3. Dependencies on others → Track in separate "Waiting On" list
4. Meeting action items → Link to meeting note with owner
```

**時間経過による進捗追跡:**
- 今日の"Yesterday"セクションを前日の"Today"計画にリンク
- 3日以上"Today"に残る項目をフラグ(潜在的にスタックした作業)
- 最終的に完了した複数日の努力を祝う
- 毎週レビューして繰り返しブロッカーまたはプロセス改善を識別

**レトロスペクティブデータ:**
- スタンドアップノートの月次レビューがパターンを明らかに:
  - 見積もりはどのくらいの頻度で正確か?
  - どのタイプのブロッカーが最も一般的か?
  - 時間はどこに行っているか?(ミーティング、バグ、機能作業の比率)
  - チーム健全性指標(頻繁なブロッカー、過剰コミットメント)
- スプリント計画とキャパシティ見積もりにインサイトを使用

**タスクシステムとの統合:**
```markdown
## Follow-Up Tasks (Auto-generated from standup)
- [ ] Follow up with @infra-team on staging access (from blocker) - Due: Today EOD
- [ ] Review PR #789 feedback from @teammate (from yesterday's post) - Due: Tomorrow
- [ ] Document deployment process (from today's plan) - Due: End of week
- [ ] Check in on JIRA-456 migration (from today's priority) - Due: Tomorrow standup
```

## 例

### 例1: 良く構造化された日次スタンドアップノート

```markdown
# Standup - 2025-10-11

## Yesterday
• **Completed JIRA-892:** User authentication with OAuth2 - PR #445 merged and deployed to staging
• **Fixed prod bug:** Payment retry logic wasn't handling timeouts - Hotfix deployed, monitoring for 24h
• **Code review:** Reviewed 3 PRs from @sarah and @mike - All approved with minor feedback
• **Meeting outcomes:** Design sync on Q4 roadmap - Agreed to prioritize mobile responsiveness

## Today
• **Continue JIRA-903:** Implement user profile edit flow - Target: Complete API integration by EOD
• **Deploy:** Roll out auth changes to production during 2pm deploy window
• **Pairing:** Work with @chris on webhook error handling - 11am-12pm session
• **Meetings:** Team retro at 3pm, 1:1 with manager at 4pm
• **Code review:** Review @sarah's notification service refactor (PR #451)

## Blockers
• **Need:** QA environment refresh for profile testing - Database is 2 weeks stale
  - **From:** @qa-team or @devops
  - **Impact:** Can't test full user flow until refreshed
  - **Workaround:** Testing with mock data for now, but need real data before production

## Notes
• Taking tomorrow afternoon off (dentist appointment) - Will post morning standup but limited availability after 12pm
• Mobile responsiveness research doc started: [Link to Notion doc]

📎 [Sprint Board](link) | [My Active PRs](link)
```

### 例2: Git履歴から自動生成されたスタンドアップ

```markdown
# Standup - 2025-10-11 (Auto-generated from Git commits)

## Yesterday (12 commits analyzed)
• **Feature work:** Implemented caching layer for API responses
  - Added Redis integration (3 commits)
  - Implemented cache invalidation logic (2 commits)
  - Added monitoring for cache hit rates (1 commit)
  - *Related tickets:* JIRA-567, JIRA-568

• **Bug fixes:** Resolved 3 production issues
  - Fixed null pointer exception in user service (JIRA-601)
  - Corrected timezone handling in reports (JIRA-615)
  - Patched memory leak in background job processor (JIRA-622)

• **Maintenance:** Updated dependencies and improved testing
  - Upgraded Node.js to v20 LTS (2 commits)
  - Added integration tests for payment flow (2 commits)
  - Refactored error handling in API gateway (1 commit)

## Today (From Jira: 3 tickets in progress)
• **JIRA-670:** Continue performance optimization work - Add database query caching
• **JIRA-681:** Review and merge teammate PRs (5 pending reviews)
• **JIRA-690:** Start user notification preferences UI - Design approved yesterday

## Blockers
• None currently

---
*Auto-generated from Git commits (24h) + Jira tickets. Reviewed and approved by human.*
```

### 例3: 非同期スタンドアップテンプレート(Slack/Discord)

```markdown
**🌅 Standup - Friday, Oct 11** | Posted 9:15 AM ET | @here

**✅ Since last update (Thu evening)**
• Merged PR #789 - New search filters now in production 🚀
• Closed JIRA-445 (the CSS rendering bug) - Fix deployed and verified
• Documented API changes in Confluence - [Link]
• Helped @alex debug the staging environment issue

**🎯 Today's focus**
• Finish user permissions refactor (JIRA-501) - aiming for code complete by EOD
• Deploy search performance improvements to prod (pending final QA approval)
• Kick off spike on GraphQL migration - research phase, doc by end of day

**🚧 Blockers**
• ⚠️ Need @product approval on permissions UX before I can finish JIRA-501
  - I've posted in #product-questions, following up in standup if no response by 11am

**📅 Schedule notes**
• OOO 2-3pm for doctor appointment
• Available for pairing this afternoon if anyone needs help!

---
React with 👀 when read | Reply in thread with questions
```

### 例4: ブロッカーエスカレーションフォーマット

```markdown
# Standup - 2025-10-11

## Yesterday
• Continued work on data migration pipeline (JIRA-777)
• Investigated blocker with database permissions (see below)
• Updated migration runbook with new error handling

## Today
• **BLOCKED:** Cannot progress on JIRA-777 until permissions resolved
• Will pivot to JIRA-802 (refactor user service) as backup work
• Review PRs and help unblock teammates

## 🚨 CRITICAL BLOCKER

**Issue:** Production database read access for migration dry-run
**Blocked since:** Tuesday (3 days)
**Impact:**
- Cannot test migration on real data before production cutover
- Risk of data loss if migration fails in production
- Blocking sprint goal (migration scheduled for Monday)

**What I need:**
- Read-only credentials for production database replica
- Alternative: Sanitized production data dump in staging

**From:** @database-team (pinged @john and @maria)

**What I've tried:**
- Submitted access request via IT portal (Ticket #12345) - No response
- Asked in #database-help channel - Referred to IT portal
- DM'd @john yesterday - Said he'd check today

**Escalation:**
- If not resolved by EOD today, will need to reschedule Monday migration
- Requesting manager (@sarah) to escalate to database team lead
- Backup plan: Proceed with staging data only (higher risk)

**Next steps:**
- Following up with @john at 10am
- Will update this thread when resolved
- If unblocked, can complete testing over weekend to stay on schedule

---

@sarah @john - Please prioritize, this is blocking sprint delivery
```

## 参照例

### 参照1: 完全な非同期スタンドアップワークフロー

**シナリオ:** 米国、ヨーロッパ、アジアのタイムゾーン全体に分散したチーム。同期スタンドアップミーティングなし。Slack #standupチャンネルでの日次書面更新。

**朝のルーティン(30分):**

```bash
# 1. Generate draft standup from data sources
git log --author="$(git config user.name)" --since="24 hours ago" --oneline
# Review commits, note key accomplishments

# 2. Check Jira tickets
jira issues list --assignee currentUser() --status "In Progress"
# Identify today's priorities

# 3. Review Obsidian daily note from yesterday
# Check for completed tasks, meeting outcomes

# 4. Draft standup note in Obsidian
# File: Daily Notes/Standup/2025-10-11.md

# 5. Review teammates' standup notes (last 8 hours)
# Identify opportunities to help, dependencies to note

# 6. Post standup to Slack #standup channel (9:00 AM local time)
# Copy from Obsidian, adjust formatting for Slack

# 7. Set reminder to check thread responses by 11am
# Respond to questions, offers of help

# 8. Update task list with any new follow-ups from discussion
```

**スタンドアップノート(Slackに投稿):**

```markdown
**🌄 Standup - Oct 11** | @team-backend | Read time: 2min

**✅ Yesterday**
• Shipped v2 API authentication (JIRA-234) → Production deployment successful, monitoring dashboards green
• Fixed race condition in job queue (JIRA-456) → Reduced error rate from 2% to 0.1%
• Code review marathon: Reviewed 4 PRs from @alice, @bob, @charlie → All merged
• Pair programming: Helped @diana debug webhook integration → Issue resolved, she's unblocked

**🎯 Today**
• **Priority 1:** Complete database migration script (JIRA-567) → Target: Code complete + tested by 3pm
• **Priority 2:** Security audit prep → Generate access logs report for compliance team
• **Priority 3:** Start API rate limiting implementation (JIRA-589) → Spike and design doc
• **Meetings:** Architecture review at 11am PT, sprint planning at 2pm PT

**🚧 Blockers**
• None! (Yesterday's staging env blocker was resolved by @sre-team 🙌)

**💡 Notes**
• Database migration is sprint goal - will update thread when complete
• Available for pairing this afternoon if anyone needs database help
• Heads up: Deploying migration to staging at noon, expect ~10min downtime

**🔗 Links**
• [Active PRs](link) | [Sprint Board](link) | [Migration Runbook](link)

---
👀 = I've read this | 🤝 = I can help with something | 💬 = Reply in thread
```

**フォローアップアクション(1日を通して):**

```markdown
# 11:00 AM - Check thread responses
Thread from @eve:
> "Can you review my DB schema changes PR before your migration? Want to make sure no conflicts"

Response:
> "Absolutely! I'll review by 1pm so you have feedback before sprint planning. Link?"

# 3:00 PM - Progress update in thread
> "✅ Update: Migration script complete and tested in staging. Dry-run successful, ready for prod deployment tomorrow. PR #892 up for review."

# EOD - Tomorrow's setup
Add to tomorrow's "Today" section:
• Deploy database migration to production (scheduled 9am maintenance window)
• Monitor migration + rollback plan ready
• Post production status update in #engineering-announcements
```

**週次レトロスペクティブ(金曜日):**

```markdown
# Review week of standup notes
Patterns observed:
• ✅ Completed all 5 sprint stories
• ⚠️ Database blocker cost 1.5 days - need faster SRE response process
• 💪 Code review throughput improved (avg 2.5 reviews/day vs 1.5 last week)
• 🎯 Pairing sessions very productive (3 this week) - schedule more next sprint

Action items:
• Talk to @sre-lead about expedited access request process
• Continue pairing schedule (blocking 2hrs/week)
• Next week: Focus on rate limiting implementation and technical debt
```

### 参照2: AI駆動スタンドアップ生成システム

**システムアーキテクチャ:**

```
┌─────────────────────────────────────────────────────────────┐
│ Data Collection Layer                                       │
├─────────────────────────────────────────────────────────────┤
│ • Git commits (last 24-48h)                                 │
│ • Jira ticket updates (status changes, comments)            │
│ • Obsidian vault changes (daily notes, task completions)    │
│ • Calendar events (meetings attended, upcoming)             │
│ • Slack activity (mentions, threads participated in)        │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ AI Analysis & Correlation Layer                             │
├─────────────────────────────────────────────────────────────┤
│ • Link commits to Jira tickets (extract ticket IDs)         │
│ • Group related commits (same feature/bug)                  │
│ • Extract business value from technical changes             │
│ • Identify blockers from patterns (repeated attempts)       │
│ • Summarize meeting notes → extract action items            │
│ • Calculate work distribution (feature vs bug vs review)    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Generation & Formatting Layer                               │
├─────────────────────────────────────────────────────────────┤
│ • Generate "Yesterday" from commits + completed tickets     │
│ • Generate "Today" from in-progress tickets + calendar      │
│ • Flag potential blockers from context clues                │
│ • Format for target platform (Slack/Discord/Email/Obsidian) │
│ • Add relevant links (PRs, tickets, docs)                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Human Review & Enhancement Layer                            │
├─────────────────────────────────────────────────────────────┤
│ • Present draft for review                                  │
│ • Human adds context AI cannot infer                        │
│ • Adjust priorities based on team needs                     │
│ • Add personal notes, schedule changes                      │
│ • Approve and post to team channel                          │
└─────────────────────────────────────────────────────────────┘
```

**実装スクリプト:**

```bash
#!/bin/bash
# generate-standup.sh - AI-powered standup note generator

DATE=$(date +%Y-%m-%d)
USER=$(git config user.name)
USER_EMAIL=$(git config user.email)

echo "🤖 Generating standup note for $USER on $DATE..."

# 1. Collect Git commits
echo "📊 Analyzing Git history..."
COMMITS=$(git log --author="$USER" --since="24 hours ago" \
  --pretty=format:"%h|%s|%cr" --no-merges)

# 2. Query Jira (requires jira CLI)
echo "🎫 Fetching Jira tickets..."
JIRA_DONE=$(jira issues list --assignee currentUser() \
  --jql "status CHANGED TO 'Done' DURING (-1d, now())" \
  --template json)

JIRA_PROGRESS=$(jira issues list --assignee currentUser() \
  --jql "status = 'In Progress'" \
  --template json)

# 3. Get Obsidian recent changes (via MCP)
echo "📝 Checking Obsidian vault..."
OBSIDIAN_CHANGES=$(obsidian_get_recent_changes --days 2)

# 4. Get calendar events
echo "📅 Fetching calendar..."
MEETINGS=$(gcal --today --format=json)

# 5. Send to AI for analysis and generation
echo "🧠 Generating standup note with AI..."
cat << EOF > /tmp/standup-context.json
{
  "date": "$DATE",
  "user": "$USER",
  "commits": $(echo "$COMMITS" | jq -R -s -c 'split("\n")'),
  "jira_completed": $JIRA_DONE,
  "jira_in_progress": $JIRA_PROGRESS,
  "obsidian_changes": $OBSIDIAN_CHANGES,
  "meetings": $MEETINGS
}
EOF

# AI prompt for standup generation
STANDUP_NOTE=$(claude-ai << 'PROMPT'
Analyze the provided context and generate a concise daily standup note.

Instructions:
- Group related commits into single accomplishment bullets
- Link commits to Jira tickets where possible
- Extract business value from technical changes
- Format as: Yesterday / Today / Blockers
- Keep bullets concise (1-2 lines each)
- Include relevant links to PRs and tickets
- Flag any potential blockers based on context

Context: $(cat /tmp/standup-context.json)

Generate standup note in markdown format.
PROMPT
)

# 6. Save draft to Obsidian
echo "$STANDUP_NOTE" > ~/Obsidian/Standup\ Notes/$DATE.md

# 7. Present for human review
echo "✅ Draft standup note generated!"
echo ""
echo "$STANDUP_NOTE"
echo ""
read -p "Review the draft above. Post to Slack? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 8. Post to Slack
    slack-cli chat send --channel "#standup" --text "$STANDUP_NOTE"
    echo "📮 Posted to Slack #standup channel"
fi

echo "💾 Saved to: ~/Obsidian/Standup Notes/$DATE.md"
```

**スタンドアップ生成のためのAIプロンプトテンプレート:**

```
You are an expert at synthesizing engineering work into clear, concise standup updates.

Given the following data sources:
- Git commits (last 24h)
- Jira ticket updates
- Obsidian daily notes
- Calendar events

Generate a daily standup note that:

1. **Yesterday Section:**
   - Group related commits into single accomplishment statements
   - Link commits to Jira tickets (extract ticket IDs from messages)
   - Transform technical commits into business value ("Implemented X to enable Y")
   - Include completed tickets with their status
   - Summarize meeting outcomes from notes

2. **Today Section:**
   - List in-progress Jira tickets with current status
   - Include planned meetings from calendar
   - Estimate completion for ongoing work based on commit history
   - Prioritize by ticket priority and sprint goals

3. **Blockers Section:**
   - Identify potential blockers from patterns:
     * Multiple commits attempting same fix (indicates struggle)
     * No commits on high-priority ticket (may be blocked)
     * Comments in code mentioning "TODO" or "FIXME"
   - Extract explicit blockers from daily notes
   - Flag dependencies mentioned in Jira comments

Format:
- Use markdown with clear headers
- Bullet points for each item
- Include hyperlinks to PRs, tickets, docs
- Keep each bullet 1-2 lines maximum
- Add emoji for visual scanning (✅ ⚠️ 🚀 etc.)

Tone: Professional but conversational, transparent about challenges

Output only the standup note markdown, no preamble.
```

**Cronジョブセットアップ(日次自動化):**

```bash
# Add to crontab: Run every weekday at 8:45 AM
45 8 * * 1-5 /usr/local/bin/generate-standup.sh

# Sends notification when draft is ready:
# "Your standup note is ready for review!"
# Opens Obsidian note and prepares Slack message
```

---

**ツールバージョン:** 2.0 (2025-10-11にアップグレード)
**対象オーディエンス:** リモートファーストエンジニアリングチーム、非同期ファースト組織、分散チーム
**依存関係:** Git、Jira CLI、Obsidian MCP、オプションのカレンダー統合
**推定セットアップ時間:** 初期セットアップ15分、自動化後は日次ルーティン5分
