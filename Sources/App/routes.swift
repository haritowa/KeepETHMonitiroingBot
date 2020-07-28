import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "123"
    }

    app.get("hello") { req -> String in
        return "Hi"
    }
    
    app.post("telegram", "webhook", use: TelegramWebhookController.handle)
}
