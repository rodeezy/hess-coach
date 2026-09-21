class Current < ActiveSupport::CurrentAttributes
  attribute :auth_session
  delegate :trainer, to: :auth_session, allow_nil: true
end
