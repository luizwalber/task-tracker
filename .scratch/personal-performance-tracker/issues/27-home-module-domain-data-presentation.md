# 27 — Dar ao módulo home a mesma forma do auth

**What to build:** o módulo `home` ganha a separação `domain/data/presentation` que todo outro módulo do frontend segue — hoje `HomePage` chama `inject<ApiClient>()` direto, pulando domínio e camada de dados por inteiro. O objetivo é ter um template consistente antes do ticket 15 (tela principal) ser construído em cima do que já existe.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] Existe uma interface de repositório no domínio do módulo `home` (`MeRepository`, em `domain/repositories/me_repository.dart`) que expõe a operação de buscar a projeção do usuário autenticado — sem `package:http` nem `ApiClient` importado no domínio.
- [x] A implementação concreta (`MeRepositoryImpl`, na camada `data`) é o único lugar do módulo `home` que fala com `ApiClient`.
- [x] `HomePage` (presentation) não importa mais `core/api_client.dart` diretamente — depende só da interface de domínio, resolvida via Modular por padrão, mas aceitando um `MeRepository` opcional pelo construtor pra ficar testável sem tocar no container de DI.
- [x] O tratamento de erro que já existe hoje (mostrar a falha em vez de girar o spinner pra sempre) continua funcionando depois da refatoração.
- [x] Testes no novo seam: `MeRepositoryImpl` (2 testes, com `ApiClient` mockado) e um golden-path de widget pra `HomePage` (2 testes, com `MeRepository` fake) — nenhum depende de rede real.
- [x] `flutter test` limpo (12/12). `flutter analyze` tem 1 aviso `info` (`prefer_initializing_formals`), aceito deliberadamente: o campo privado `_meRepository` e o parâmetro público `meRepository` têm nomes diferentes de propósito (API pública limpa), e a forma sugerida pelo linter forçaria o nome do parâmetro externo a levar underscore.

## Implementation notes

`/code-review` (Standards + Spec) rodado antes de fechar, em duas rodadas. Achados reais corrigidos: (1) faltava o teste golden-path de widget pra `HomePage` — nosso próprio `commits-and-naming.mdc` exige um por tela; adicionado `home_page_test.dart`, o que exigiu dar ao `HomePage` um jeito de receber `MeRepository` por construtor (fallback pro `inject<T>()` do Modular quando omitido) já que ele não tinha DI testável antes; (2) o `build()` checava `snapshot.hasError`, mas `_fetchMe` já captura toda falha e nunca deixa a Future rejeitar — esse branch era código morto, removido. Achados sinalizados e aceitos sem alteração: `MeRepository.getMe()` devolve a string crua do corpo da resposta em vez de uma entidade de domínio tipada (Primitive Obsession) — aceitável enquanto a tela for só um smoke test do token, não fica assim quando `/me` precisar exibir campos de verdade; `HomePage` acessa o repositório direto (sem Bloc), diferente do padrão do `auth` — permitido explicitamente pelo próprio ticket dado que a tela ainda não tem estado complexo.
