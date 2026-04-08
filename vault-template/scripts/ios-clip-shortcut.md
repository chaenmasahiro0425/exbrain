---
date: 2026-04-08
type: guide
---

# iOS Shortcut: Clip to Vault

Safari/Chrome の共有メニューから1タップでvaultにクリップ。

## 仕組み

```
Safari → 共有 → "Clip" ショートカット → Slack DM送信 → OpenClaw検知 → vault保存
```

## ショートカット作成手順

### Step 1: ショートカットアプリを開く

1. iPhoneの「ショートカット」アプリを開く
2. 右上の「+」で新規作成
3. 名前: **Clip**

### Step 2: アクションを追加

以下のアクションを順番に追加:

1. **「共有シートの入力を受け取る」** — 種類: URL
2. **「テキスト」** — 内容: `📎 (共有シートの入力)`
3. **「Slackでメッセージを送信」**
   - 宛先: 自分のSlack DMチャンネル（ロブ男のDM）
   - メッセージ: 上のテキスト変数

### Step 3: 共有シートに表示

1. ショートカット設定（ⓘ）を開く
2. 「共有シートに表示」をオン
3. 入力タイプ: URL のみにチェック

### 代替: Slack Webhook版

Slackアプリのアクションが使いにくい場合、Webhook経由:

1. **「URLの内容を取得」** アクション
   - URL: `https://slack.com/api/chat.postMessage`
   - メソッド: POST
   - ヘッダー: `Authorization: Bearer xoxb-YOUR-BOT-TOKEN`
   - 本文: JSON
     ```json
     {
       "channel": "YOUR_DM_CHANNEL_ID",
       "text": "📎 (共有シートの入力)"
     }
     ```

### 代替: OpenClaw Gateway版

OpenClawのHTTP Gatewayを直接叩く:

1. **「URLの内容を取得」** アクション
   - URL: `http://YOUR_MAC_IP:18789/api/message`
   - メソッド: POST
   - ヘッダー: `Authorization: Bearer YOUR_GATEWAY_TOKEN`
   - 本文: JSON
     ```json
     {
       "message": "📎 clip this: (共有シートの入力)"
     }
     ```

## 使い方

1. Safariで記事を開く
2. 共有ボタンをタップ
3. 「Clip」を選択
4. 自動でSlack DMに送信 → OpenClawがクリップ → vault保存

## 注意

- Slack Webhook版は外部からの送信になるため、ボットトークンの管理に注意
- OpenClaw Gateway版はMacが起動している必要がある
- 📎 プレフィックスを付けてクリップ意図を明確にする（通常のURL送信と区別）
