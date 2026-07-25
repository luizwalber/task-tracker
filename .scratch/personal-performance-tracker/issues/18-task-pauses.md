# 18 — Pausas de tarefa

**What to build:** a possibilidade de pausar uma tarefa temporariamente (viagem, lesão) e retomá-la depois, sem que o período de pausa conte como esperado nem consuma a cota de folga.

**Blocked by:** 16 — Recorrência completa + versionamento.

**Status:** ready-for-agent

- [ ] O usuário pode pausar uma tarefa a partir de uma data e retomá-la depois.
- [ ] Enquanto pausada, a tarefa não aparece como esperada em nenhum dia — não entra no denominador do desempenho do dia nem consome cota de folga.
- [ ] Retomar a tarefa volta ao padrão de recorrência normal a partir da data de retomada, sem afetar como os dias antes da pausa foram classificados.
- [ ] A pausa reaproveita o mesmo mecanismo de versionamento da fatia anterior — nenhuma entidade nova foi criada só para isso.
