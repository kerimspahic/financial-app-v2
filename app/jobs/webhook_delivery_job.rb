class WebhookDeliveryJob < ApplicationJob
  queue_as :default

  def perform(webhook_id, event_name, payload)
    webhook = Webhook.find_by(id: webhook_id)
    return unless webhook

    WebhookDeliveryService.deliver(webhook, event_name, payload)
  end
end
