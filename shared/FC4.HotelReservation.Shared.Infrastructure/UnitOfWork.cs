using FC4.HotelReservation.Shared.Application;
using FC4.HotelReservation.Shared.Domain;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace FC4.HotelReservation.Shared.Infrastructure;

public class UnitOfWork(HotelDbContext dbContext, IMediator mediator) : IUnitOfWork
{
    public async Task CommitAsync(CancellationToken cancellationToken)
    {
        var domainEvents = dbContext.ChangeTracker
            .Entries<AggregateRoot>()
            .SelectMany(e => e.Entity.Events)
            .ToList();

        foreach (var entry in dbContext.ChangeTracker.Entries<AggregateRoot>())
        {
            entry.Entity.ClearEvents();
        }

        foreach (var domainEvent in domainEvents)
        {
            await mediator.Publish(domainEvent, cancellationToken);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}