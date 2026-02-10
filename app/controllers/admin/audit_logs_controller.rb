module Admin
  class AuditLogsController < BaseController
    before_action -> { set_section(:audit_logs) }

    def index
    end
  end
end
