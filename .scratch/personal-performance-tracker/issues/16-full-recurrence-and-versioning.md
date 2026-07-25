# 16 — Recorrência completa + versionamento

**What to build:** os demais padrões de recorrência (dias específicos da semana, dia fixo do mês incluindo "último dia", intervalo de N dias) e o versionamento da regra de recorrência no tempo, de forma que editar a recorrência de uma tarefa nunca reescreva retroativamente quais dias já passados eram esperados — mesmo dentro do mês corrente ainda em curso.

**Blocked by:** 15 — Tela principal ponta a ponta.

**Status:** ready-for-agent

- [ ] Uma tarefa pode ser criada com recorrência diária, dias específicos da semana, dia fixo do mês (incluindo "último dia do mês", correto em meses de 28 a 31 dias), ou a cada N dias.
- [ ] A consulta "essa data é esperada para esta tarefa?" é uma função pura, sem I/O, testável isoladamente — incluindo um teste que cobre especificamente fevereiro bissexto vs. não bissexto para o caso de "último dia do mês".
- [ ] Editar a recorrência de uma tarefa fecha a versão vigente e abre uma nova a partir de hoje, sem sobrescrever a versão anterior.
- [ ] Editar a recorrência hoje não altera o percentual de desempenho de nenhum dia já passado — incluindo dias do mês corrente ainda em curso, anteriores à edição.
- [ ] O calendário mensal e o slider (da fatia anterior) continuam funcionando corretamente para tarefas com qualquer um dos novos padrões de recorrência.
