# AGENTS.md — Monolith

## Quick start

```bash
just setup       # migrate + seed
just api         # build & run (Swagger at http://localhost:5077)
just test        # dotnet test IntegrationTests
```

All dev commands are in the `justfile`. Use `just --list` to see them. Direct `dotnet` equivalents work too.

## Project structure

- **`src/`** — ASP.NET Core 8 Minimal API entrypoint
- **`modules/{Catalog,Guests,Payments,Reservations}/`** — domain slices, each with `.Domain`, `.Application`, `.Infra.Data`
- **`shared/`** — shared kernel (base classes, `HotelDbContext`, `UnitOfWork`)
- **`tests/`** — xUnit + Testcontainers integration tests (single project)

Single PostgreSQL database (`hotel_reservation`, user `postgres`, password `Test1234`). EF Core migrations live in `shared/FC4.HotelReservation.Shared.Infrastructure`.

## Architecture notes

- Modular monolith with DDD/Clean Architecture — one solution, one database, in-process MediatR dispatch
- Cross-module async messaging via MassTransit (PostgreSQL transport, same DB)
- Synchronous cross-module calls only happen through `Reservations.Adapters` -> `Catalog.Application`
- `PostgresMigrationHostedService` applies EF migrations automatically on startup (dev only)
- API routes all under `/v1/`

## Testing

```bash
just test
```

Requires Docker (Testcontainers spins up a throwaway PostgreSQL). Test project uses `WebApplicationFactory<Program>`, Bogus for test data, FluentAssertions. `Reservations.Domain` uses `InternalsVisibleTo(IntegrationTests)`.

## Migrations

```bash
just add-migration "Name"   # create
just migrate                # apply
just remove-migration       # revert last
just list-migrations        # list all
just rollback               # revert all
just rollback-to "Name"     # revert to named
```

No linter, formatter, or typechecker is configured.

## Known quirks

- `Dockerfile.prd` references stale project names (`HelloWorldSolution.sln`) — update before production use.
- `tools/FC4.HotelReservation.SeedTool/` does not exist yet; `just seed` will fail until it's created.
- No CI/CD workflows in repo.
