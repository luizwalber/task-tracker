# 26 — Tirar AuthenticatedUser da camada de infraestrutura

**What to build:** `AuthenticatedUser` deixa de morar em `infrastructure/auth` e passa a morar no domínio — a única camada que tanto `presentation` quanto `infrastructure` já têm permissão de depender, sem violar a regra de dependência do architecture-spec (`presentation → application → domain ← infrastructure`, sem aresta `presentation → infrastructure`).

**Blocked by:** None — can start immediately.

**Status:** done

- [x] `AuthenticatedUser` (antes em `backend/src/infrastructure/auth/authenticated-user.ts`) agora vive em `backend/src/domain/auth/authenticated-user.ts` — arquivo antigo apagado.
- [x] `backend/src/presentation/current-user.decorator.ts` importa `AuthenticatedUser` do domínio, não de `infrastructure/auth`. Também parou de importar o tipo `RequestWithUser` da infraestrutura — define seu próprio tipo mínimo local (`HasAuthenticatedUser`), já que só precisa do campo `.user`, não do `Request` inteiro do Express.
- [x] `backend/src/infrastructure/auth/firebase-auth.guard.ts` continua produzindo um `AuthenticatedUser` (adapta pra ele), mas não é mais o dono do tipo.
- [x] **Correção sobre o critério original**: sobrou uma exceção literal — `me.controller.ts` continua importando `FirebaseAuthGuard` de `infrastructure/auth/`. Isso é esperado e correto: o NestJS exige que o controller referencie a classe do guard pra aplicá-lo via `@UseGuards(FirebaseAuthGuard)` — não tem como aplicar um guard sem importar sua classe. O alvo real deste ticket (e da revisão de arquitetura que o originou) era o *tipo de dado* `AuthenticatedUser` vazando entre camadas, não a referência ao guard, que é o mecanismo padrão de composição do framework. O critério como escrito era rígido demais.
- [x] Testes existentes (`firebase-auth.guard.spec.ts`, `me.integration.spec.ts`) continuam passando sem precisar de ajuste de import (nenhum dos dois referenciava o tipo diretamente).

## Implementation notes

`/code-review` (Standards + Spec) rodado antes de fechar. Dois achados reais corrigidos: (1) `RequestWithUser` era o mesmo nome usado em `infrastructure` (`Request & {user}`) e em `presentation` (`{user}` só) pra formas diferentes — renomeado o da presentation pra `HasAuthenticatedUser` pra não ler como o mesmo tipo; (2) `firebase-auth.guard.ts` importava `AuthenticatedUser` como valor quando só era usado como tipo — trocado pra `import type`.
