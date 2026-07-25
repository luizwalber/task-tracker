Status: ready-for-agent

# Tracker Pessoal de Desempenho Diário

> Spec derivado do mapa de wayfinder "Personal Performance Tracker — Architecture Spec" (`.scratch/personal-performance-tracker/map.md`). O detalhamento completo de arquitetura, com diagramas e exemplos de código, vive em `.scratch/personal-performance-tracker/architecture-spec.md` — este documento é o PRD que alimenta o próximo passo (`/to-tickets`).

## Problem Statement

Eu sou um engenheiro sênior (Java/Spring, NestJS, Flutter, AWS, microsserviços) construindo um projeto vitrine para GitHub/LinkedIn. Quero um tracker pessoal de desempenho diário para academia, estudos/programação, dieta e peso corporal — mas as ferramentas genéricas de hábito que existem por aí tratam "pulei um dia" e "não fiz nada" como a mesma coisa, ou tratam toda folga como sucesso, o que destrói o propósito de qualquer sistema de acompanhamento honesto. Além do uso pessoal, o código em si precisa ser exemplar o bastante para eu defender cada decisão numa entrevista técnica: camadas bem separadas, regra de negócio nunca vazando pra controller ou widget, testável de ponta a ponta.

## Solution

Um app pessoal (Flutter Web + Desktop, backend NestJS) cuja tela principal é um calendário mensal de marcação rápida: o dia atual já vem selecionado, um clique muda o dia, e cada tarefa daquele dia tem um slider de 10 em 10% que salva sozinho ao ser arrastado — sem botão de confirmar. O desempenho de cada dia é uma média ponderada pelos pesos das tarefas, e cada tarefa carrega sua própria cota de folgas legítimas: dentro da cota, a folga pontua como sucesso; além da cota, pontua como fracasso — nunca é possível "zerar o ano de verde" só marcando folga todo dia. As ocorrências são virtuais (só existe registro no banco quando algo é de fato marcado), a recorrência de uma tarefa é versionada no tempo (editar não reescreve silenciosamente o passado), e peso corporal, fotos e um timelapse mensal completam o quadro de acompanhamento.

## User Stories

1. Como usuário, quero fazer login com minha conta (Firebase Auth), para que meus dados fiquem isolados de qualquer outro usuário do sistema.
2. Como usuário, quero criar uma tarefa com nome, peso (0.5–2), tipo (comum ou acompanhamento de peso), data de início e data de término opcional, para que eu possa modelar qualquer hábito que eu queira acompanhar.
3. Como usuário, quero escolher uma regra de recorrência para cada tarefa (diária, dias específicos da semana, dia fixo do mês — incluindo "último dia", ou a cada N dias), para que a tarefa apareça só nos dias em que ela realmente é esperada.
4. Como usuário, quero definir uma cota de folgas por semana ou por mês numa tarefa, para que eu tenha dispensas legítimas sem que isso vire uma forma de nunca falhar.
5. Como usuário, quero pausar uma tarefa temporariamente (viagem, lesão) e retomá-la depois, para que esses períodos não contem nem como esperados nem consumam minha cota de folga.
6. Como usuário, quero editar a recorrência de uma tarefa sem que isso mude os percentuais que eu já vi no passado, para que meu histórico seja confiável mesmo quando eu ajusto minha rotina.
7. Como usuário, quero abrir o app e já ver o calendário do mês atual com o dia de hoje selecionado, para que eu não precise navegar pra começar a registrar.
8. Como usuário, quero clicar em qualquer dia do mês para ver as tarefas daquele dia, para que eu possa registrar ou revisar qualquer data.
9. Como usuário, quero arrastar um slider de 10 em 10% pra cada tarefa do dia selecionado e ver o valor salvar sozinho, para que marcar meu dia seja rápido e sem fricção.
10. Como usuário, quero ver um indicador de "salvando"/"salvo" enquanto arrasto o slider, para que eu saiba que meu registro não se perdeu.
11. Como usuário, quero que, se a rede falhar durante o autosave, o valor que eu arrastei não desapareça da tela, para que eu não precise refazer o gesto.
12. Como usuário, quero marcar um dia como "folga" em vez de um percentual, para que eu registre uma dispensa legítima sem forçar um número artificial.
13. Como usuário, quero anexar uma foto opcional a uma ocorrência, para que eu tenha um registro visual do meu progresso.
14. Como usuário, quero que minhas fotos sejam redimensionadas, convertidas e tenham metadados removidos automaticamente, para que eu não precise me preocupar com tamanho de arquivo ou vazamento de dados de EXIF (localização, dispositivo).
15. Como usuário, quero que minhas fotos só sejam acessíveis por mim, autenticado, para que ninguém mais consiga adivinhar ou acessar um link pra elas.
16. Como usuário, quero ver cada dia do calendário mensal colorido conforme meu desempenho agregado daquele dia, para que eu identifique padrões visualmente.
17. Como usuário, quero que um dia ainda não preenchido apareça em branco (não vermelho, não colorido como 0%), para que eu diferencie "não registrei" de "registrei e fui mal".
18. Como usuário, quero ver uma visão anual com os 12 meses coloridos pela mesma escala, para que eu enxergue tendências de longo prazo.
19. Como usuário, quero que meses ainda em curso ou futuros apareçam neutros na visão anual (não coloridos como se já tivessem terminado), para que eu não confunda "em andamento" com "concluído e ruim".
20. Como usuário, quero ver, ao lado do nome de cada mês na visão anual, meu peso de abertura e de fechamento daquele mês, para que eu acompanhe a evolução do peso sem precisar abrir um gráfico separado.
21. Como usuário, quero registrar meu peso semanalmente através da mesma tarefa de acompanhamento de peso (com foto de espelho na mesma pose), para que eu tenha uma série temporal consistente.
22. Como usuário, quero que o sistema me lembre de pesar no último dia do mês quando esse dia não coincidir com meu dia normal de pesagem, para que eu sempre tenha uma leitura de fechamento de mês.
23. Como usuário, quero que esse lembrete de fechamento de mês não seja contado contra mim se eu não pesar nesse dia extra, para que eu não seja penalizado por um compromisso que nunca assumi.
24. Como usuário, quero ver meu peso de abertura/fechamento de um mês mesmo que eu tenha ficado alguns meses sem pesar, para que o componente continue útil mesmo com lacunas no meu registro.
25. Como usuário, quero ver relatórios de desempenho mensal e anual, tanto geral quanto por tarefa específica, para que eu entenda onde estou indo bem ou mal.
26. Como usuário, quero ver quantas folgas usei por mês e por tarefa, e quantas ainda restam na minha cota, para que eu saiba meu "saldo" de dispensas.
27. Como usuário, quero ver um gráfico de evolução do meu peso corporal ao longo do tempo, independente do calendário, para que eu acompanhe minha tendência de peso isoladamente.
28. Como usuário, quero um mini-vídeo/timelapse automático gerado a partir das minhas fotos de um período, para que eu veja minha evolução física de forma compacta e visual.
29. Como usuário, quero que o timelapse seja regenerado diariamente e substitua o anterior, para que eu sempre tenha a versão mais atual sem acumular vídeos antigos ocupando espaço.
30. Como usuário, quero saber se o timelapse de hoje já está pronto, gerando ou falhou, para que eu saiba se devo esperar ou tentar mais tarde.
31. Como usuário, quero que todas as datas do sistema respeitem o fuso horário de São Paulo de forma consistente, para que "hoje" nunca varie por causa do relógio do meu dispositivo estar configurado errado.
32. Como usuário, quero que a semana, para fins de cota de folga e exibição do calendário, comece no domingo (não na segunda, como o padrão ISO), para que bata com a forma como eu penso em semana no dia a dia.
33. Como usuário, quero que uma semana que atravessa a virada do mês ainda tenha sua cota de folga tratada como uma semana só, para que eu não seja punido ou beneficiado artificialmente por causa de onde a semana cai no calendário.
34. Como usuário, quero usar o mesmo app tanto no navegador quanto como aplicativo desktop, com a mesma experiência, para que eu registre meu dia de onde for mais conveniente.
35. Como usuário (também na posição de revisor técnico), quero que a arquitetura separe claramente domínio, aplicação, infraestrutura e apresentação em ambos os lados (backend e frontend), para que eu consiga apontar e justificar cada decisão numa entrevista.
36. Como usuário, quero que meus dados de um usuário nunca sejam acessíveis por outro usuário, mesmo que eu tente adivinhar ids de tarefas ou ocorrências de outra conta, para que a privacidade dos meus registros seja garantida estruturalmente, não por sorte.

## Implementation Decisions

**Camadas**: Clean Architecture nos dois lados. Backend em `domain / application / infrastructure / presentation`; frontend Flutter organizado por módulo (`flutter_modular`), cada módulo replicando `domain / data / presentation`. O domínio nunca depende de infraestrutura ou apresentação, em nenhum dos dois lados.

**Modelo de domínio central**:
- `Task` é o agregado raiz: nome, tipo (`REGULAR` ou `WEIGHT`), peso (0.5–2, padrão 1), política de folga opcional (`{ count, per: 'WEEK' | 'MONTH' }`, pertence à Task, não à recorrência), data de início e término opcional.
- A regra de recorrência é um value object puro com um único método de consulta ("essa data é esperada?"), operando só sobre data local (sem UTC/timezone real dentro do VO). Os padrões suportados são: diário, dias específicos da semana, dia fixo do mês (incluindo "último dia do mês", correto em meses de 28 a 31 dias), intervalo de N dias, e um padrão de pausa (nunca esperado, usado pra viagens/lesões).
- Em vez de a tarefa guardar uma única regra de recorrência mutável, ela guarda uma lista ordenada e não sobreposta de versões dessa regra, cada uma com sua própria janela de vigência. Editar a recorrência fecha a versão vigente e abre uma nova a partir de hoje — nunca sobrescreve. Isso garante que o histórico nunca mude retroativamente quando a recorrência é editada, mesmo dentro do mês corrente ainda em curso. Pausar/retomar uma tarefa é modelado como mais uma versão dessa mesma lista, sem entidade nova.
- Uma ocorrência (registro de um dia para uma tarefa) só existe quando algo foi de fato registrado — nunca é pré-criada. Ela guarda: percentual (múltiplo de 10) OU estado de folga, foto opcional, peso corporal (só quando a tarefa é do tipo peso), e uma marca de origem (gerada pela recorrência normal, ou derivada automaticamente pelo sistema).
- Uma regra de domínio separada e stateless decide, dada a lista de folgas já usadas no período (semana ou mês) até a data em questão, se aquela folga está dentro ou além da cota. Ela não pertence à Task nem ao serviço de cálculo de desempenho — é sua própria peça, testável isoladamente.
- O serviço central de cálculo de desempenho é isolado e trocável: para cada dia, considera só as tarefas esperadas naquele dia (via a lista de versões de recorrência) que não sejam de origem derivada; ocorrências inexistentes ficam de fora do cálculo (não contam como 0%); percentuais registrados entram diretamente; folgas são avaliadas pela regra de cota (dentro = 100%, além = 0%; tarefa sem política de folga trata toda folga como 100%); o resultado final é a média ponderada pelo peso de cada tarefa. Se nenhuma tarefa é esperada e pontuável naquele dia, o resultado é "sem dado", não zero.
- O agrupamento de dias em semanas começando no domingo (para a cota semanal e para a exibição do calendário) é uma função pura da aplicação sobre datas já carregadas — nunca uma agregação no banco (evita a semântica de semana ISO/segunda-feira que o Postgres usa por padrão).
- Peso corporal é um campo na própria ocorrência da tarefa de peso (não um agregado separado), já que nasce sempre do mesmo fluxo de registro de ocorrência; a série temporal de peso é consultada de forma independente do calendário por um filtro simples sobre a mesma tabela. Peso de abertura/fechamento de um mês busca a leitura mais recente disponível, cascateando para meses anteriores se o mês adjacente não tiver nenhuma leitura; o estado verdadeiramente vazio (nenhuma leitura em nenhum mês anterior) aparece como um marcador explícito de ausência, nunca como zero.
- No último dia do mês, o sistema injeta uma ocorrência derivada da tarefa de peso como lembrete de fechamento, exceto quando esse dia já coincide com a recorrência semanal normal (nesse caso a ocorrência normal já cobre o papel). Essa ocorrência derivada nunca entra no denominador do cálculo de desempenho do dia — é um lembrete, não um compromisso assumido — mas, se preenchida, o peso registrado ainda conta pra série temporal normalmente.

**Isolamento por usuário**: autenticação via Firebase (validação do token no backend); nenhuma camada de Row-Level Security no Postgres foi adotada — a defesa é estrutural, através de um objeto de acesso a dados que não consegue montar consulta nenhuma sem o identificador do usuário autenticado explicitamente propagado (nunca por estado ambiente). Toda ocorrência de acesso negado por escopo de usuário responde como "não encontrado", nunca como "acesso negado", para não vazar a existência do recurso.

**Modelo de dados**: chave primária natural (usuário + tarefa + data) na tabela de ocorrências, não um id sintético — isso é o que torna o upsert idempotente pela própria natureza da tabela. Datas são persistidas como data pura, sem componente de hora ou fuso horário — o único ponto do sistema que converte hora real em data local (fuso fixo de São Paulo, não configurável por usuário) é um único adaptador de relógio injetado onde for necessário saber "qual dia é hoje". Nenhuma agregação de data é feita em SQL (nada de `date_trunc`/`generate_series`) — toda expansão de recorrência e agrupamento de semana acontece em memória na aplicação, porque o volume de dados de um único usuário torna isso mais simples sem custo de performance real.

**Contrato de leitura**: a lista de tarefas do usuário é obtida separadamente do detalhe de um mês específico do calendário, porque muda com frequências muito diferentes — tarefas raramente, ocorrências o tempo todo. A leitura de um mês do calendário inclui uma folga de dias nas duas pontas (até a semana completa que toca o primeiro/último dia do mês), para que o cálculo de cota semanal tenha contexto completo mesmo em semanas que cruzam a virada do mês. O salvamento de uma ocorrência (arrastar o slider) devolve, na própria resposta, o percentual recalculado daquele dia — o cliente nunca precisa buscar o mês inteiro de novo depois de um autosave.

**Fotos**: processadas de forma síncrona no próprio request de upload (redimensionamento limitando o lado maior a ~1600px, conversão para WebP com qualidade ~85, remoção de metadados EXIF), a partir de um buffer em memória — o arquivo original nunca é persistido em disco em nenhum momento, nem mesmo temporariamente. O caminho de armazenamento no volume espelha a própria chave natural da ocorrência. O serving de fotos passa pela mesma autenticação e mesmo escopo de usuário do resto da API — sem mecanismo de URL assinada separado.

**Timelapse**: gerado por um job diário no servidor, sem gatilho de geração sob demanda pelo usuário — como consequência, não há necessidade de nenhum mecanismo de streaming de progresso (nem polling, nem eventos, nem socket); o cliente só consulta um status simples (pronto / gerando / falhou / ainda não gerado) quando abre a tela de relatórios. O job apaga o vídeo anterior antes de gerar o novo.

**Infraestrutura**: Postgres no mesmo compose com volume persistente e healthcheck; migrations versionadas rodando automaticamente na subida do container da API (nunca sincronização automática de schema); fotos e vídeos em volumes locais separados; variáveis de ambiente incluem a string de conexão do banco, as credenciais do Firebase Admin, e o fuso horário fixo como constante documentada (não pensado como configurável por usuário).

## Testing Decisions

Um bom teste aqui verifica comportamento externo observável — o resultado de uma consulta de recorrência, o percentual final de um dia, a resposta HTTP de um endpoint — nunca detalhes internos de implementação (não testar "qual método privado foi chamado", e sim "qual foi o resultado").

Como o projeto é greenfield (não há código nem testes existentes para servir de prior art), os seams de teste são definidos aqui, do mais alto para o mais baixo:

1. **Domínio puro, sem I/O**: a regra de recorrência (incluindo o caso do "último dia do mês" em meses de tamanhos diferentes) e o serviço de cálculo de desempenho (incluindo folga dentro/além da cota e dia não preenchido) recebem a maior parte da cobertura de testes, por serem regra de negócio pura e a peça mais crítica de defender numa entrevista.
2. **Um único seam de integração HTTP**, não um teste por repositório: requests reais contra os endpoints, rodando contra um Postgres real, cobrindo a garantia de isolamento por usuário (um usuário nunca alcança dado de outro) e a idempotência do upsert de ocorrência.
3. **No Flutter, o seam é o Bloc** (eventos de entrada, estados de saída), não testes de widget — a exceção é um teste mínimo de "golden path" cobrindo a tela de calendário renderizando e reagindo ao evento de arrastar o slider, sem testar cada detalhe visual.

## Out of Scope

- Row-Level Security no Postgres — avaliada e descartada conscientemente; o isolamento é inteiramente por código.
- Correção retroativa de histórico para edições de peso (`weight`) ou de política de folga (`restPolicy`) de uma tarefa — só a regra de recorrência é versionada; mudar o peso ou a cota de uma tarefa hoje pode, sim, alterar como dias passados são recalculados. Gap aceito e documentado, não corrigido nesta versão.
- Geração de timelapse sob demanda pelo usuário — só existe o job automático diário.
- Configuração de fuso horário por usuário — o fuso é fixo (America/Sao_Paulo) para todo o sistema, independente de onde o usuário esteja fisicamente.
- Qualquer forma de cache offline no frontend — o app assume conexão sempre disponível.
- Preocupações de escala multiusuário/SaaS (a arquitetura é multiusuário no sentido de isolamento de dados, mas o dimensionamento e as decisões de performance assumem uso pessoal de baixo volume, não uma base de usuários grande).

## Further Notes

- O detalhamento completo de arquitetura — diagramas Mermaid, o modelo de dados com a primeira migration, o contrato REST endpoint a endpoint, a árvore de pastas do monorepo, os módulos Flutter, a stack de infraestrutura, os exemplos de código de segurança, os testes reais escritos por extenso, o roadmap de fatias verticais e as 5 decisões mais discutíveis com defesa de entrevista — vive em `.scratch/personal-performance-tracker/architecture-spec.md`. Esse documento deve ser consultado como referência viva ao longo da implementação, mesmo que ele não seja a fonte de verdade para tickets (esse papel é do `/to-tickets` a partir deste spec).
- O rastro completo de por que cada decisão foi tomada (incluindo as alternativas descartadas e o raciocínio) vive nos 13 tickets resolvidos em `.scratch/personal-performance-tracker/issues/`.
- O roadmap sugerido corta o trabalho em fatias verticais entregáveis, começando pela tela principal (calendário + slider + autosave) funcionando ponta a ponta sem recorrência complexa, cota de folga, peso, fotos ou vídeo — esses entram em fatias subsequentes. Isso é uma sugestão de sequenciamento pro `/to-tickets`, não uma imposição rígida.
