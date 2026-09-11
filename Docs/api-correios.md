# Integração com a API dos Correios

O app consome a **API Rastro** dos Correios, descrita no
[Portal de desenvolvedores](https://www.correios.com.br/atendimento/developers) (Manual de
Integração). É uma **API restrita**: exige cadastro no Meu Correios e o serviço Rastro habilitado
no cartão de postagem ou contrato. Não existe acesso anônimo — sem credenciais válidas o app não
consulta nada.

| Arquivo | Papel |
| --- | --- |
| `MCTrackingServicing` | Protocolo (`trackPackage(code:) async throws -> MCPackage`) + `MCTrackingError` |
| `MCCorreiosAuthService` | Obtém e mantém em memória o token Bearer |
| `MCCorreiosTrackingService` | Consulta o rastreamento e converte a resposta para o domínio |
| `MCRastroDTO` | Structs `Decodable` que espelham o JSON da API |
| `MCMockTrackingService` | Implementação falsa e determinística, usada nos previews |
| `MCCorreiosDateFormatter` | Parse das datas no formato da API |
| `MCTrackingStatus+Classification` | Reduz dezenas de códigos de evento a 6 status |

## Ambientes

| Ambiente | Base URL |
| --- | --- |
| Produção | `https://api.correios.com.br` |
| Homologação | `https://apihom.correios.com.br` |

Selecionável em **Ajustes → Ambiente** (`MCCorreiosEnvironment`).

## Autenticação

`POST {base}/token/v1/autentica[/contrato|/cartaopostagem]` com **Basic Auth**
(`usuario:senha` em Base64). O sufixo e o corpo dependem do modo escolhido em Ajustes:

| Modo (`AuthMode`) | Path | Corpo JSON | Campos obrigatórios |
| --- | --- | --- | --- |
| `simples` | `/token/v1/autentica` | — | usuário, senha |
| `contrato` | `.../contrato` | `{"numero", "dr"}` | + contrato, DR |
| `cartaoPostagem` | `.../cartaopostagem` | `{"numero", "contrato", "dr"}` | + cartão, contrato, DR |

`MCCorreiosCredentials.isComplete` valida essa matriz antes de qualquer requisição; se faltar
algo, o app nem sai para a rede e lança `.missingCredentials`.

A resposta traz `token` e `expiraEm`. O `MCCorreiosAuthService` guarda ambos **em memória**
(nunca em disco) e reaproveita o token enquanto faltarem mais de **30 segundos** para expirar —
margem para a requisição seguinte não estourar no meio do caminho. Como o cache é de instância e
o serviço é criado junto com o ViewModel, reiniciar o app sempre gera um token novo.

## Consulta de rastreamento

```
GET {base}/srorastro/v1/objetos/{codigo}?resultado=T
Authorization: Bearer {token}
Accept: application/json
```

`resultado=T` pede a lista **completa** de eventos (o padrão devolveria só o último).

O código é normalizado (trim + maiúsculas) e validado contra `^[A-Z]{2}[0-9]{9}[A-Z]{2}$` antes
do envio. Tratamento de resposta:

| Situação | Erro lançado | Mensagem ao usuário |
| --- | --- | --- |
| Código fora do formato | `.invalidCode` | "Código de rastreio inválido. Use o formato AA123456789BR." |
| HTTP 404, ou JSON sem objetos | `.notFound` | "Não encontramos informações para esse código." |
| Credenciais incompletas | `.missingCredentials` | "Configure suas credenciais da API dos Correios em Ajustes." |
| Falha na autenticação (status ≠ 2xx ou JSON inesperado) | `.authenticationFailed` | "Não foi possível autenticar…" |
| Erro de transporte ou outro status | `.requestFailed` | "Falha ao consultar o rastreamento…" |

## Mapeamento DTO → domínio

```
MCRastroObjeto.codObjeto                      → MCPackage.id
MCRastroEvento.dtHrCriado                     → MCTrackingEvent.date
MCRastroEvento.descricao                      → MCTrackingEvent.description
unidade.endereco.cidade + "/" + …uf           → MCTrackingEvent.location
classify(codigo:descricao:)                   → MCTrackingEvent.status
```

- **Datas**: a API envia `yyyy-MM-dd'T'HH:mm:ss` sem timezone, em horário de Brasília.
  `MCCorreiosDateFormatter` interpreta com `America/Sao_Paulo`; a exibição usa o fuso do aparelho.
  Data que não parseia vira `Date()` — o evento aparece, mas com a data errada.
- **Local**: cidade e UF são opcionais no JSON; quando faltam, o resultado é uma string vazia ou
  parcial (o app não inventa placeholder).
- **Apelido**: a API não conhece apelido. O serviço devolve `nickname: ""` e quem preenche é o
  ViewModel, com o que o usuário digitou.

## Classificação de status

A API tem dezenas de códigos de evento. Em vez de mapear código a código, o app classifica pela
**descrição** — que continua sendo exibida na íntegra — apenas para escolher ícone e cor de
resumo. A comparação ignora acentos e caixa, e a **ordem importa**: a primeira regra que casar vence.

| Ordem | Contém | Status |
| --- | --- | --- |
| 1 | `nao entregue`, `tentativa`, `ausente`, `extraviado`, `avaria` | `.fracassado` |
| 2 | `entregue` | `.entregue` |
| 3 | `saiu para entrega`, `rota de entrega` | `.saiuParaEntrega` |
| 4 | `postado`, `recebido pelos correios` | `.postado` |
| 5 | `unidade de distribuicao`, `aguardando retirada`, `chegou` | `.naUnidade` |
| — | qualquer outra coisa | `.emTransito` (padrão) |

**A falha é testada antes do sucesso de propósito**: a comparação é por substring e
"objeto **nao entregue**" contém "entregue". Na ordem inversa, toda descrição de falha nessa forma
seria classificada como entregue, com ícone verde de concluído. Ao mexer nessas regras, mantenha
as negações na frente.

O status classificado é reavaliado a cada atualização: o merge do store sobrescreve o `status` do
evento salvo, então mudanças nessa tabela valem para o histórico já gravado.

## Serviço falso (`MCMockTrackingService`)

Gera uma linha do tempo determinística: soma os valores unicode do código para derivar um seed e
com ele escolhe de 2 a 5 etapas de um roteiro fixo (postado → em trânsito → na unidade → saiu para
entrega → entregue), com uma data por dia retroativo. O mesmo código sempre produz o mesmo
resultado, e há um `Task.sleep` de 0,5 s para exercitar os estados de carregamento.

É o serviço usado por todos os `#Preview`. Para rodar o app inteiro sem credenciais, troque o
padrão do `MCPackageListViewModel`:

```swift
self.service = service ?? MCMockTrackingService()
```

## Segurança

- As credenciais ficam **no Chaveiro** (`MCKeychainStore`, `kSecClassGenericPassword`,
  acessível `AfterFirstUnlock`), serializadas como JSON de `MCCorreiosCredentials`. Nunca em
  `UserDefaults`, nunca no banco do SwiftData.
- O token só existe em memória.
- Usuário, senha e token não são escritos em log em nenhum ponto do app.
