import Vapor

import Fluent
import FluentPostgresDriver

import Queues
import QueuesRedisDriver

import Bugsnag

// configures your application
public func configure(_ app: Application) throws {
    try setupDatabase(app: app)
    try setupQueues(app: app)
    setupBugsnap(app: app)
    try setupRoutes(app: app)
}

private func setupDatabase(app: Application) throws {
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "haritowa",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "haritowa"
    ), as: .psql)
    
    app.migrations.add(CreateAlertMonitor())
    app.migrations.add(AddLatestReportedValue())
    app.migrations.add(CreateCollateralizationLastKnownBlock())
}

private func setupQueues(app: Application) throws {
    try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
    
    app.queues.schedule(ETHPolingJob())
        .hourly()
        .at(0)
    
    app.queues.schedule(ETHPolingJob())
        .at(Date(timeIntervalSinceNow: 10))
    
    app.queues.schedule(SetTelegramCommandsJob())
        .at(Date(timeIntervalSinceNow: 5))
    
    app.queues.schedule(CollateralizationFetchJob())
        .hourly()
        .at(10)
    
    app.queues.schedule(CollateralizationFetchJob())
        .at(Date(timeIntervalSinceNow: 30))
    
    try app.queues.startScheduledJobs()
}

private func setupRoutes(app: Application) throws {
    try routes(app)
}

private func setupBugsnap(app: Application) {
    guard let bugsnapAPIKey = Environment.get("BUGSNAP_API_KEY") else {
        print("Warning: not using bugsnap")
        return
    }
    
    app.bugsnag.configuration = .init(
        apiKey: bugsnapAPIKey,
        releaseStage: app.environment.name,
        shouldReport: app.environment.name != "local"
    )

    // Add Bugsnag middleware.
    app.middleware.use(BugsnagMiddleware())
}
