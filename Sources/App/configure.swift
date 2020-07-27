import Vapor

import Fluent
import FluentPostgresDriver

import Queues
import QueuesRedisDriver

// configures your application
public func configure(_ app: Application) throws {
    try setupDatabase(app: app)
    try setupQueues(app: app)
    try setupRoutes(app: app)
}

private func setupDatabase(app: Application) throws {
    app.databases.use(.postgres(hostname: "localhost", username: "haritowa", password: "", database: "haritowa"), as: .psql)
    
    app.migrations.add(CreateAlertMonitor())
}

private func setupQueues(app: Application) throws {
    try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
    
    app.queues.schedule(ETHPolingJob())
        .hourly()
        .at(0)
    
    try app.queues.startScheduledJobs()
}

private func setupRoutes(app: Application) throws {
    try routes(app)
}
