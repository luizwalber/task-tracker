# 28 — Disparar o AuthCheckRequested na raiz do app

**What to build:** ao abrir o app, ele checa se já existe uma sessão Firebase válida antes de decidir mostrar a tela de login — hoje `AuthCheckRequested` é testado isoladamente no `AuthBloc` mas nunca é disparado por ninguém, então um usuário que já logou sempre vê a tela de login de novo.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] **Correção sobre o critério original**: `AuthCheckRequested` é disparado por um `AuthGatePage` novo — o próprio conteúdo da rota `/` — em vez de literalmente em `app_widget.dart`/`main.dart`. É funcionalmente equivalente ("antes da primeira rota ser decidida" no sentido de que dispara assim que a única rota inicial monta, antes de qualquer tela de negócio aparecer) e evita acoplar `main.dart` ao Bloc de auth. `app_module.dart` registra `AuthGatePage` (não mais `LoginPage`) na rota `/`.
- [x] Enquanto a checagem está em andamento (`AuthInitial`), o app mostra um estado de carregamento — não a tela de login piscando antes de redirecionar.
- [x] Se já existe uma sessão válida (`AuthAuthenticated`), o app navega direto pra `/home`, sem nunca renderizar `LoginPage`.
- [x] Se não existe sessão (`AuthUnauthenticated`), o app mostra a `LoginPage` normalmente. `AuthLoading`/`AuthError` (que só ocorrem durante uma tentativa de login já em andamento na própria `LoginPage`) também mostram `LoginPage` — o `switch` é exaustivo sobre os 5 estados do `AuthState` (sealed class), então isso é explícito, não um "senão" implícito.
- [x] Dois testes de widget (`auth_gate_page_test.dart`) comprovam os dois casos: sem sessão → formulário de login aparece; com sessão → formulário nunca aparece e o callback de navegação é chamado.

## Implementation notes

`/code-review` (Standards + Spec) rodado antes de fechar. Removido o listener de navegação duplicado que existia em `LoginPage` (ela reagia a `AuthAuthenticated` e navegava sozinha) — agora `AuthGatePage` é o único lugar que decide navegação por auth, `LoginPage` virou só formulário + submit. Achado real corrigido: a lógica original do gate era "se não for Initial/Authenticated, mostra LoginPage" (um `senão` implícito que mascararia silenciosamente um estado novo do `AuthState` no futuro) — trocado por `switch` exaustivo sobre o sealed class, que o compilador obriga a cobrir todo caso nomeado explicitamente. Achado aceito sem alteração: o teste tem 2 `testWidgets` em vez de 1 (a regra do `commits-and-naming.mdc` fala em "um" golden-path por tela) — defensável porque o motivo de existir do gate é exatamente o desvio entre os dois caminhos, então um teste só não cobriria "a interação principal".
