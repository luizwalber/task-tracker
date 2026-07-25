# 21 — Fotos

**What to build:** anexar uma foto opcional a qualquer ocorrência, processada automaticamente (redimensionada, convertida, com metadados removidos) e servida apenas para o próprio usuário autenticado.

**Blocked by:** 15 — Tela principal ponta a ponta.

**Status:** ready-for-agent

- [ ] O usuário consegue anexar uma foto opcional ao registrar uma ocorrência de qualquer tarefa.
- [ ] A foto é processada de forma síncrona no próprio upload: redimensionada limitando o lado maior a ~1600px, convertida para WebP, com metadados EXIF removidos.
- [ ] O arquivo original nunca é persistido em disco, nem mesmo temporariamente.
- [ ] A foto só é acessível pelo próprio usuário autenticado, através de um endpoint que reaproveita o mesmo isolamento de usuário do resto da API — nenhum caminho público adivinhável.
- [ ] O usuário consegue visualizar a foto anexada ao reabrir a ocorrência depois.
