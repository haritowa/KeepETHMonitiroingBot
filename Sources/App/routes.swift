import Vapor

func routes(_ app: Application) throws {
    app.get("hello") { _ in "Hello" }
    
    app.post("telegram", "webhook", .constant(app.telegramBotAPIKey), use: TelegramWebhookController.handle)
}
