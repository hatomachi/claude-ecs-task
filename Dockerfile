FROM node:20-slim

RUN npm install -g @anthropic-ai/claude-code

RUN mkdir -p /mnt/efs && \
    useradd -m -s /bin/bash claudeuser && \
    chown -R claudeuser:claudeuser /mnt/efs

USER claudeuser
WORKDIR /mnt/efs

CMD ["claude", "-p", "src/ の中にあるソースコードをレビューして、バグや改善点を箇条書きで出力してください。", "--dangerously-skip-permissions"]
