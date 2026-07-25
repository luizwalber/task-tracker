# 23 — Infraestrutura de produção + CI + README final

**What to build:** o app pronto pra ser mostrado como projeto vitrine: stack de produção rodando num Portainer local, backup do banco, pipeline de CI, e o README final posicionando o projeto para um recrutador.

**Blocked by:** 20 — Visão anual + relatórios agregados, 22 — Timelapse.

**Status:** ready-for-agent

- [ ] A stack completa (API, Postgres, volumes de fotos/vídeos) sobe como uma stack no Portainer local, com variáveis de ambiente e segredos configurados fora do controle de versão.
- [ ] Existe uma rotina de backup do Postgres (ex. dump agendado) escrevendo num volume separado.
- [ ] Um pipeline de CI roda lint, testes (unitários de domínio + integração) e build a cada push, e passa verde numa branch limpa.
- [ ] O README final explica o projeto, a stack e as decisões de arquitetura de forma que um recrutador entenda o propósito e o nível técnico em cerca de 30 segundos.
