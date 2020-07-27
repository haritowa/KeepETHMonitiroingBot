import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "123"
    }

    app.get("hello") { req -> EventLoopFuture<String> in
        return ETHPolingRoutine.performMonitoring(request: req)
            .map { _ in "Test" }
    }
}
