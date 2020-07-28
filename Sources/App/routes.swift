import Vapor

func routes(_ app: Application) throws {
    app.post("telegram", "webhook", .constant(app.telegramBotAPIKey), use: TelegramWebhookController.handle)
}
