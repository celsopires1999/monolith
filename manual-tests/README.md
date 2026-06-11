# Testes Manuais — FC4.HotelReservation

Arquivos de teste manual para a API do monólito de reservas de hotel.

## Pré-requisitos

- [VS Code](https://code.visualstudio.com/) com a extensão
  [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
- API rodando em `http://localhost:5077`
- PostgreSQL com o banco `hotel_reservation` criado e migrations aplicadas

## Quick Start

```bash
# 1. Aplicar as migrations (se ainda não foi feito)
dotnet ef database update --project src/FC4.HotelReservation.WebApi

# 2. Seed dos dados de referência
psql -h localhost -U postgres -d hotel_reservation -f manual-tests/seed.sql

# 3. Iniciar a API
dotnet run --project src/FC4.HotelReservation.WebApi

# 4. Abrir manual-tests/api.http no VS Code e clicar em "Send Request"
```

## Arquivos

| Arquivo | Descrição |
|---|---|
| `api.http` | Testes manuais com todos os endpoints da API |
| `seed.sql` | Script para popular dados de referência (RoomType, Hotel, Inventory, Rates) |

## Organização dos Testes

O arquivo `api.http` está organizado em seções que devem ser executadas em ordem:

### 1. Hotels (`POST/GET /v1/hotels`)

| Request | Descrição | Dependência |
|---|---|---|
| `createHotel` | Cria um hotel (retorna ID) | Nenhuma |
| `getHotel (seed)` | Busca hotel do seed | `seed.sql` executado |
| `getHotel (created)` | Busca hotel recém-criado | `createHotel` executado |
| `getHotelNotFound` | Busca hotel inexistente (espera 404) | Nenhuma |

### 2. Guests (`POST /v1/guests`)

| Request | Descrição | Dependência |
|---|---|---|
| `createGuest` | Cria um hóspede e captura `guestId` | Nenhuma |

### 3. Rooms (`POST/GET /v1/rooms`)

| Request | Descrição | Dependência |
|---|---|---|
| `createRoom` | Cria um quarto | `seed.sql` (RoomType + Hotel) |
| `getRoom` | Busca quarto recém-criado | `createRoom` executado |
| `getRoomNotFound` | Busca quarto inexistente (espera 404) | Nenhuma |

### 4. Rates (`GET /v1/rates`)

| Request | Descrição | Dependência |
|---|---|---|
| `getRates` | Calcula diárias para período | `seed.sql` (RoomTypeRate + Hotel) |

### 5. Reservations (`CRUD /v1/reservations`)

| Request | Descrição | Dependência |
|---|---|---|
| `createReservation` | Cria reserva e captura `reservationId` | `createGuest` + `seed.sql` |
| `getReservation` | Busca reserva por ID | `createReservation` executado |
| `listReservationsByGuest` | Lista reservas do hóspede | `createReservation` executado |
| `cancelReservation` | Cancela reserva (exclui) | `createReservation` executado |
| `createReservationInvalidGuest` | Erro: guestId inexistente (espera 422) | Nenhuma |

### 6. Payments (`PATCH /v1/payments/{id}`)

| Request | Descrição | Dependência |
|---|---|---|
| `paymentProcessing` | Pending → Processing | Payment existente no banco |
| `paymentCompleted` | Processing → Completed | `paymentProcessing` executado (mesmo payment) |
| `paymentRefunded` | Completed → Refunded | `paymentCompleted` executado (mesmo payment) |
| `paymentFailed` | Processing → Failed | Payment diferente em status Processing |
| `paymentInvalidStatus` | Erro: Pending → Pending (espera 422) | Nenhuma |

## Obtendo o Payment ID

O Payment é criado automaticamente quando uma reserva é feita (via
integration event do MassTransit). Como não há endpoint para listar payments,
você precisa consultar o banco para obter o ID:

```sql
SELECT id, reservation_id, status, processed_at
FROM payments
ORDER BY processed_at DESC
LIMIT 5;
```

Copie o `id` de um payment com status `Pending` e substitua o GUID
`5f3ad118-39f1-455f-9c63-3ba6875c25b2` nas URLs dos testes de pagamento
no `api.http`.

### Transições de status válidas

```
Pending → Processing → Completed → Refunded
                    ↘ Failed
```

Os status são representados como inteiros no JSON:
`1=Pending`, `2=Processing`, `3=Completed`, `4=Failed`, `5=Refunded`

## Respostas de Erro Esperadas

| Endpoint | Condição | Status | Formato |
|---|---|---|---|
| `GET /v1/hotels/{id}` | ID inexistente | 404 | `ProblemDetails` |
| `GET /v1/rooms/{id}` | ID inexistente | 404 | `ProblemDetails` |
| `POST /v1/reservations` | Guest ID inexistente | 422 | `ProblemDetails` |
| `POST /v1/reservations` | Quartos insuficientes | 422 | `ProblemDetails` |
| `PATCH /v1/payments/{id}` | Transição inválida | 422 | `ProblemDetails` |
| `PATCH /v1/payments/{id}` | Payment ID inexistente | 404 | `ProblemDetails` |
| `POST /v1/hotels` | Campos inválidos/vazios | 400 | `ProblemDetails` |

## Dicas

- Use **`Send Request`** no VS Code para executar cada requisição
- As variáveis (`{{createGuest.response.body.id}}`) são resolvidas
  automaticamente pelo REST Client, desde que o request `@name` correspondente
  tenha sido executado na mesma sessão
- Para resetar o banco entre execuções: `dotnet ef database drop` + `dotnet ef database update`
- Para executar a API com hot reload: `dotnet watch run --project src/FC4.HotelReservation.WebApi`
