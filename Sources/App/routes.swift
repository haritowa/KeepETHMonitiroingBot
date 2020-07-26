import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "123"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
}
