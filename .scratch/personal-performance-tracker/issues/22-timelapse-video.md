# 22 — Timelapse

**What to build:** a geração automática de um mini-vídeo/timelapse a partir das fotos registradas, rodando em um job diário no servidor, substituindo o vídeo anterior a cada execução.

**Blocked by:** 21 — Fotos.

**Status:** ready-for-agent

- [ ] Um job diário no servidor gera um timelapse a partir das fotos registradas no período, usando FFmpeg.
- [ ] Cada execução do job apaga o vídeo anterior antes de gerar o novo — nunca acumula vídeos antigos.
- [ ] O usuário consegue consultar o status do timelapse (pronto / gerando / falhou / ainda não gerado) ao abrir a tela de relatórios.
- [ ] O usuário consegue assistir ao timelapse mais recente pela tela de relatórios.
