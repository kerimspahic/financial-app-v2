require "net/http"
require "openssl"

class WebhookDeliveryService
  def self.deliver(webhook, event_name, payload)
    new(webhook, event_name, payload).deliver
  end

  def initialize(webhook, event_name, payload)
    @webhook = webhook
    @event_name = event_name
    @payload = payload
  end

  def deliver
    return unless @webhook.active?
    return unless @webhook.subscribes_to?(@event_name)

    body = @payload.to_json
    signature = compute_signature(body)

    uri = URI.parse(@webhook.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["X-Webhook-Signature"] = signature
    request["X-Webhook-Event"] = @event_name
    request["User-Agent"] = "FinancialApp-Webhooks/1.0"
    request.body = body

    response = http.request(request)

    @webhook.update_column(:last_triggered_at, Time.current)

    Rails.logger.info "[WebhookDelivery] #{@event_name} -> #{@webhook.url} (#{response.code})"
    response
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
    Rails.logger.warn "[WebhookDelivery] Failed #{@event_name} -> #{@webhook.url}: #{e.message}"
    nil
  end

  private

  def compute_signature(body)
    OpenSSL::HMAC.hexdigest("SHA256", @webhook.secret, body)
  end
end
