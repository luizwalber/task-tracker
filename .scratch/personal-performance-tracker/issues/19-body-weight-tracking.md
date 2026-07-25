# 19 — Peso corporal

**What to build:** a tarefa canônica de acompanhamento de peso (pesagem semanal + foto na mesma pose), o lembrete automático de fechamento de mês, e um gráfico de evolução do peso independente do calendário.

**Blocked by:** 16 — Recorrência completa + versionamento.

**Status:** ready-for-agent

- [ ] Existe uma única tarefa de tipo "acompanhamento de peso", com recorrência semanal, onde o usuário registra peso + foto opcional na mesma pose.
- [ ] Registrar um peso marca automaticamente a ocorrência como 100% concluída — não existe slider manual para essa tarefa.
- [ ] No último dia do mês, o sistema injeta automaticamente um lembrete de pesagem de fechamento, exceto quando esse dia já coincide com o dia normal de pesagem da semana.
- [ ] Esse lembrete de fechamento nunca entra no cálculo de desempenho do dia, mesmo que o usuário efetivamente pese nesse dia (o peso ainda conta para a série temporal, só não afeta o percentual do dia).
- [ ] O usuário vê um gráfico de evolução do peso ao longo do tempo, consultado independentemente do calendário.
- [ ] O peso de abertura/fechamento de um mês busca a leitura mais recente disponível, cascateando para meses anteriores se necessário; se não houver nenhuma leitura em nenhum mês anterior, aparece um estado vazio explícito (nunca zero).
