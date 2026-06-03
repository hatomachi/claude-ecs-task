なるほど！「Cloud Codeの機能（VS Code拡張）を使って開発する」という意味ではなく、「コンテナの中で Anthropicの公式CLIツール（`claude` コマンド）の `claude -p -dangerously-skip-permission` を使って、EFS上のファイルをコンテキストとして読み込ませて非インタラクティブに処理させる」という意味だったのですね！

完全に行き違い失礼しました。おっしゃる通り、CLIの `claude` コマンド（特に `-dangerously-skip-permission` フラグ）を使えば、コンテナにマウントしたEFSのファイル群（Git同期エリア）をそのままAIのコンテキストに叩き込んで、非インタラクティブに一発で結果を出力させるバッチ処理が作れます。将来的にStep Functionsから呼び出す構成としても、最高にシンプルで強力な実装です。

Mac（Dockerインストール済）のローカル環境で、まずはこの「Claude CLI入りのバッチ用コンテナ」を動かす最初の一歩を組みましょう！

---

## 🛠️ 1. ローカルの準備（ディレクトリ構造）

まずはMac上で以下のようにフォルダを作ります。

```text
claude-ecs-task/
├── efs-mock/              # EFS（Git同期）を模したローカルディレクトリ
│   ├── src/               # 解析させたいソースコードなど
│   └── output.txt         # 処理結果の出力先（任意）
├── Dockerfile             # Claude CLI入りのコンテナ定義
└── env.txt                # AnthropicのAPIキーを入れるファイル（Git管理外推奨）

```

---

## 🛠️ 2. 各種ファイルの作成

### ① `Dockerfile`

Node.js環境ベースに、Anthropicの公式Claude CLI（`@anthropic-ai/claude-cli`）をインストールします。

```dockerfile
FROM node:20-slim

# Claude CLIのインストール
RUN npm install -g @anthropic-ai/claude-cli

# 本番のEFSマウント先（コンテナ内）を想定したディレクトリを作成
RUN mkdir -p /mnt/efs

WORKDIR /mnt/efs

# コンテナ起動時に、マウントされたEFSのファイルを指定してclaudeコマンドを実行する
# -p (prompt): プロンプトの指定
# -dangerously-skip-permission: CLIがローカルファイルへアクセスする際の確認をスキップ（非インタラクティブ用）
CMD ["claude", "-p", "src/ の中にあるソースコードをレビューして、バグや改善点を箇条書きで出力してください。", "-dangerously-skip-permission"]

```

### ② `env.txt` (環境変数ファイル)

Claude CLIを動かすには `ANTHROPIC_API_KEY` が必要です。ローカルテスト用に、Mac側でファイルを用意しておきます。

```text
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxx

```

### ③ `efs-mock/src/sample.js` (テスト用ファイル)

AIに読み込ませるための、適当なファイルを `efs-mock/src/` の中に置いておきます。

```javascript
function add(a, b) {
    // バグ埋め込み用の適当なコード
    console.log("Adding numbers");
    return a + b
}

```

---

## 🛠️ 3. Macのローカルで一歩目を動かす（実行）

ターミナルを開き、`claude-ecs-task` ディレクトリに移動して、以下の2つのコマンドを叩きます。

### 1. コンテナのビルド

```bash
docker build -t claude-ecs-task .

```

### 2. 非インタラクティブ実行（EFSマウント ＆ APIキー注入）

```bash
docker run --rm \
  --env-file env.txt \
  -v $(pwd)/efs-mock:/mnt/efs \
  claude-ecs-task

```

これでコンテナが起動し、コンテナ内の `/mnt/efs/src/`（Mac上の `efs-mock/src/`）のファイルをClaude CLIが自動でコンテキストとして読み込み、リクエストが完了したら自動的にコンテナが終了（非インタラクティブ）します！

---

## 💡 将来的な AWS (Step Functions / ECS) への展望

このローカル構成が動けば、本番化は目の前です。

* **Step Functionsからの制御**:
CMD（プロンプト内容など）をStep Functions側から動的に変えたい場合は、Step Functionsの `RunTask` APIにある `ContainerOverrides` の `command` パラメータを使って、実行時にプロンプト（`-p "〇〇"`）を上書きして注入できます。
* **APIキーの管理**:
本番環境（ECS）では `env.txt` ではなく、AWS Secrets ManagerやSSMパラメータストアにAPIキーを保存し、ECSのタスク定義経由で環境変数 `ANTHROPIC_API_KEY` に安全に注入します。