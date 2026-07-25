# 24 — Fechar o buraco de escrita no UserScopedRepository

**What to build:** `UserScopedRepository.saveForUser` deixa de chamar `repo.save` direto e passa a validar posse antes de escrever — nenhum método da classe consegue mais montar uma escrita que atravesse o dono de outro usuário, do mesmo jeito que já vale pra leitura.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] Se `entity.id` já existe e pertence a outro usuário, `saveForUser` rejeita a escrita (`OwnershipViolationError`, um erro simples de domínio — não vaza a existência da linha, cabe à camada de apresentação mapear pra 404, nunca 403) em vez de sobrescrever o `userId` da linha existente.
- [x] Se `entity.id` não existe ainda, ou pertence ao próprio `userId`, a escrita segue normalmente (upsert continua idempotente pela chave natural, sem regressão de comportamento).
- [x] A verificação de posse usa uma query própria (`assertOwnership`), não `scoped(userId)` — isso foi uma correção sobre o critério original: `scoped(userId)` já filtra pelo dono, então não serve pra descobrir se a linha pertence a *outro* usuário (retornaria "não encontrado" tanto pra "não existe" quanto pra "existe mas não é seu", que é exatamente a distinção que precisa ser feita aqui).
- [x] O teste de contrato reutilizável (`itIsolatesByUser` em `test/support/isolation-contract.ts`) ganhou o caso novo: `saveForUser` como `user-b` sobre um id que pertence a `user-a` falha, sem alterar a linha original.
- [x] Os testes de integração existentes (`user-scoped-repository.integration.spec.ts`, `me.integration.spec.ts`) continuam passando sem alteração de comportamento pros casos que já cobriam — 6 testes de integração no total agora (era 5).

## Implementation notes

`/code-review` (Standards + Spec) rodado antes de fechar. Achado real corrigido: a checagem de posse lançava `NotFoundException` do `@nestjs/common` direto da infraestrutura — um tipo de exceção HTTP vazando pra dentro da camada errada (`.claude/clean-architecture.mdc`: infra "must not contain HTTP concerns"). Trocado por `OwnershipViolationError`, um erro simples de domínio exportado do mesmo arquivo; mapear pra 404 fica a cargo de quem chamar `saveForUser` a partir de um endpoint real (nenhum existe ainda). Achado sinalizado mas não corrigido agora: o architecture-spec.md coloca esse arquivo em `infrastructure/persistence/typeorm/`, mas ele vive em `infrastructure/persistence/` — mismatch pré-existente, fora do escopo deste ticket.
