class WebhooksController < ApplicationController
  require_permission "manage_webhooks"

  before_action :set_webhook, only: [ :edit, :update, :destroy ]

  def index
    @webhooks = current_user.webhooks.order(created_at: :desc)
  end

  def new
    @webhook = current_user.webhooks.build(active: true, events: [])
  end

  def create
    @webhook = current_user.webhooks.build(webhook_params)
    @webhook.secret = SecureRandom.hex(32) if @webhook.secret.blank?

    if @webhook.save
      redirect_to webhooks_path, notice: "Webhook was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @webhook.update(webhook_params)
      redirect_to webhooks_path, notice: "Webhook was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @webhook.destroy
    redirect_to webhooks_path, notice: "Webhook was successfully deleted."
  end

  private

  def set_webhook
    @webhook = current_user.webhooks.find(params[:id])
  end

  def webhook_params
    params.expect(webhook: [ :url, :active, :secret, events: [] ])
  end
end
