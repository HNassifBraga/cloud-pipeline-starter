#!/usr/bin/env bash
# Instala o GitHub Actions self-hosted runner na EC2 (executar como usuario ubuntu).
# Uso: bash scripts/setup-runner-ec2.sh https://github.com/OWNER/REPO TOKEN_DE_REGISTRO
# O TOKEN e o "registration token" temporario (expira em 1h) exibido em
# Settings > Actions > Runners > New self-hosted runner. Nunca versione esse token.
set -euo pipefail
REPO_URL="${1:?Informe a URL do repositorio}"
REG_TOKEN="${2:?Informe o registration token}"
RUNNER_VERSION="${RUNNER_VERSION:-2.329.0}"
mkdir -p "$HOME/actions-runner" && cd "$HOME/actions-runner"
curl -fsSL -o runner.tar.gz \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
tar xzf runner.tar.gz && rm runner.tar.gz
./config.sh --unattended --url "$REPO_URL" --token "$REG_TOKEN" \
  --name "ec2-cloud-tasks" --labels "ec2-deploy" --replace
sudo ./svc.sh install "$USER"
sudo ./svc.sh start
echo "Runner instalado como servico. Verifique em Settings > Actions > Runners."
