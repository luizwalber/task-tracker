# 20 — Visão anual + relatórios agregados

**What to build:** a visão anual (grade dos 12 meses coloridos pela mesma escala do mês, com o peso de abertura/fechamento ao lado do nome de cada mês) e os relatórios agregados de desempenho e folgas, mensal e anual, geral e por tarefa.

**Blocked by:** 17 — Cota de folga, 19 — Peso corporal.

**Status:** ready-for-agent

- [ ] O usuário vê uma grade própria com os 12 meses do ano, cada um colorido conforme o desempenho médio daquele mês.
- [ ] Somente meses já encerrados recebem cor — o mês corrente e meses futuros aparecem neutros, sinalizados por um flag explícito vindo da API (não deduzido pelo frontend a partir da data do dispositivo).
- [ ] Ao lado do nome de cada mês, aparece o peso de abertura (fim do mês anterior) e de fechamento (fim do mês corrente).
- [ ] O usuário vê relatórios de desempenho mensal e anual, tanto geral quanto por tarefa específica.
- [ ] O usuário vê quantas folgas usou por mês e por tarefa, e quantas ainda restam na cota — nunca somadas com percentuais de conclusão real na mesma métrica.
