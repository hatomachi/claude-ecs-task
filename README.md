# claude-ecs-task

Claude Code CLI をコンテナ内で非インタラクティブに実行するサンプルです。  
EFS（本番）をローカルディレクトリで模倣し、マウントしたファイルを Claude に解析させます。

## 動作確認済み環境

- Docker がインストールされた Mac / Linux

## ディレクトリ構成

```
claude-ecs-task/
├── Dockerfile          # node:20-slim + Claude Code CLI（非rootユーザーで実行）
├── env.txt             # APIキー設定ファイル（Git管理外・要作成）
├── efs-mock/
│   └── src/
│       └── sample.js   # Claudeに解析させるサンプルコード
└── README.md
```

## セットアップ

### 1. APIキーファイルを作成する

`env.txt`（`.gitignore` 済み）をルートに作成し、Anthropic API キーを記入します。

```bash
echo "ANTHROPIC_API_KEY=sk-ant-xxxxxx" > env.txt
```

APIキーは https://console.anthropic.com で発行できます。

### 2. コンテナをビルドする

```bash
docker build -t claude-ecs-task .
```

### 3. 実行する

```bash
docker run --rm \
  --env-file env.txt \
  -v $(pwd)/efs-mock:/mnt/efs \
  claude-ecs-task
```

`efs-mock/src/` 内のファイルを Claude がレビューし、結果を標準出力に表示して終了します。

## 解析対象ファイルを変えるには

`efs-mock/src/` に解析したいファイルを置いてから実行してください。  
プロンプトを変えたい場合は `Dockerfile` の `CMD` を編集します。

```dockerfile
CMD ["claude", "-p", "任意のプロンプト", "--dangerously-skip-permissions"]
```
