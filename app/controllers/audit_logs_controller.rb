class AuditLogsController < ApplicationController
  require_permission "view_audit_logs"

  def index
  end
end
