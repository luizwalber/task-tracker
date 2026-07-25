# 15 — Tela principal ponta a ponta

**What to build:** o loop central do app: cadastrar uma tarefa simples, ver o calendário do mês atual com o dia de hoje já selecionado, e marcar o desempenho do dia arrastando um slider que salva sozinho. Recorrência fica limitada a "todo dia" nesta fatia — os demais padrões de recorrência, cota de folga e pausas entram em tickets seguintes.

**Blocked by:** 14 — Scaffolding + Autenticação.

**Status:** ready-for-agent

- [ ] O usuário cria, lista e edita uma tarefa (nome, peso de 0.5 a 2, tipo comum, data de início, data de término opcional) — recorrência fixa em "todo dia" nesta fatia.
- [ ] Ao abrir o app, o calendário do mês atual aparece com o dia de hoje já selecionado; um clique seleciona outro dia.
- [ ] Selecionar um dia revela as tarefas esperadas naquele dia, cada uma com seu slider de 10 em 10%.
- [ ] Arrastar o slider salva automaticamente (sem botão de confirmar), com debounce, feedback visual de "salvando"/"salvo", e o valor arrastado nunca se perde se a rede falhar durante o salvamento.
- [ ] O endpoint de salvamento é um upsert idempotente, chaveado por usuário + tarefa + data (não por id sintético), e devolve o percentual recalculado do dia na própria resposta — o cliente não refaz a busca do mês inteiro após o autosave.
- [ ] A célula de cada dia no calendário é colorida conforme o desempenho agregado daquele dia; um dia ainda não preenchido aparece em branco, visualmente distinto de um dia com 0%.
- [ ] Fechar e reabrir o app preserva os valores já registrados.
