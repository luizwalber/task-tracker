# 17 — Cota de folga

**What to build:** a possibilidade de marcar um dia como "folga" em vez de um percentual, com uma cota (por semana ou por mês) que define quantas folgas são legítimas antes de passarem a punir o desempenho — e a contagem de folgas usadas/restantes visível ao usuário.

**Blocked by:** 16 — Recorrência completa + versionamento.

**Status:** ready-for-agent

- [ ] Uma tarefa pode ter uma política de folga opcional (quantidade tolerada por semana ou por mês).
- [ ] Na tela do dia, o usuário pode marcar "folga" em vez de arrastar o slider.
- [ ] Uma folga dentro da cota do período pontua como 100% no cálculo de desempenho do dia; uma folga além da cota pontua como 0%; uma tarefa sem política de folga trata toda folga como 100%.
- [ ] O agrupamento de folgas por semana usa domingo como início (não a semana ISO/segunda-feira), inclusive quando a semana atravessa a virada do mês — a cota pertence à semana inteira, mesmo cruzando dois meses.
- [ ] Existe um teste isolado (sem I/O) da regra que decide se uma folga está dentro ou além da cota, dado o histórico de folgas do período.
- [ ] O usuário consegue ver quantas folgas já usou e quantas ainda restam na cota de uma tarefa no período corrente.
