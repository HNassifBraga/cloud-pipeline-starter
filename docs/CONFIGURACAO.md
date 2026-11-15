# Guia de configuração do laboratório (AWS Ubuntu + GitHub Actions)

## 1. Repositório
1. Crie um novo repositório a partir deste starter (com o histórico próprio do grupo).
2. Ative Actions e mantenha `main` protegida quando o plano da conta permitir.
3. Crie branch `feature/...`, envie PR e só integre após CI passar.

## 2. AWS EC2
1. Crie instância **Ubuntu Server 24.04 LTS**, arquitetura x86_64, com IP público e chave SSH. Verifique preços/limites/créditos antes de iniciar.
2. Security Group: HTTP TCP/80 de fontes permitidas para testar; SSH TCP/22 **apenas de endereços confiáveis**. Para runner GitHub hospedado (IPs variáveis), use runner auto-hospedado em rede permitida ou implemente acesso de implantação temporário/restrito com supervisão docente. **Não deixe SSH aberto para toda a internet.**
3. Conecte com SSH e execute `bash scripts/setup-ec2-ubuntu.sh` (copie o script ou clone o repositório na instância). Faça logout/login e teste `docker ps` sem sudo.
4. Certifique-se que a porta 80 está livre. Execute deploy manual primeiro, se necessário.

## 3. GitHub (estratégia adotada: self-hosted runner na EC2)
O CD (`.github/workflows/cd.yml`) roda com `runs-on: [self-hosted, linux, x64, ec2-deploy]`, ou seja, **dentro da EC2**. Por isso:
- não existem secrets `EC2_SSH_KEY`/`EC2_KNOWN_HOSTS`/`EC2_HOST`: nenhuma chave privada sai da máquina do aluno;
- o Security Group não precisa liberar SSH para o GitHub; a porta 22 fica restrita ao IP do aluno e ao prefixo do EC2 Instance Connect da região;
- o `docker pull` no GHCR usa o `GITHUB_TOKEN` efêmero do job (`packages: read`), com `docker logout` ao final.

Passos:
1. Settings > Actions > Runners > **New self-hosted runner** (Linux x64). Copie os comandos exibidos e execute-os na EC2 como `ubuntu`, adicionando o label `ec2-deploy` no `config.sh` (`--labels ec2-deploy`). Alternativa: `bash scripts/setup-runner-ec2.sh <URL_REPO> <TOKEN>`. O token de registro é temporário e **não deve ser versionado**.
2. Instale como serviço: `sudo ./svc.sh install ubuntu && sudo ./svc.sh start`.
3. Settings > Environments: crie `production` com *deployment branches* restrito a `main`.
4. Settings > Actions > General: em *Fork pull request workflows*, exija aprovação para todos os colaboradores externos (repositório público + runner self-hosted).

## 4. Registry GHCR
A CI publica imagem `ghcr.io/OWNER/REPO:COMMIT_SHA` após `push` na main (a imagem também recebe `APP_VERSION=<SHA>`, exposto em `/version`). O CD autentica no GHCR com o token efêmero do job, então o pacote pode continuar privado; torná-lo **Public** é opcional. Não publique dados sensíveis na imagem.

## 5. Validação
- Crie PR: apenas testes/build; sem publicação ou deploy.
- Merge para `main`: CI publica imagem; evento `workflow_run` inicia CD.
- Acesse `http://IP_PUBLICO/health`, `http://IP_PUBLICO/tasks`.
- Faça nova mudança pela branch e PR e comprove novo deploy automático.
- Faça screenshot dos runs e registre URL/commit no relatório.

## 6. Diagnóstico
- Actions falhou em `docker push`: verifique `packages: write`, permissões de Actions e configuração GHCR.
- `docker pull` falhou na EC2: confira se pacote está público e se tag SHA existe.
- Job de CD "Waiting for a runner": verifique `sudo ./svc.sh status` em `~/actions-runner` e o label `ec2-deploy`.
- Falha HTTP: verifique SG porta 80, endereço, `docker ps` e `docker logs cloud-tasks-api`.
- **Atenção:** runner público do GitHub não possui IP fixo. Não altere o SG para 0.0.0.0/0 só para fazer o CD passar. O professor deve providenciar um runner com acesso controlado ou outra estratégia de deploy (ex.: SSM), antes da avaliação do CD.

## 7. Custos e encerramento
Desligar nem sempre elimina custo de EBS e IP; após a apresentação, exclua instância, volumes e recursos alocados conforme orientação docente.
