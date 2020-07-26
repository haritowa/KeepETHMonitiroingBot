import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return req.telegramClient.sendMessage(chatID: 194580859, text: "Heelo").map { _ in "123" }
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
}
