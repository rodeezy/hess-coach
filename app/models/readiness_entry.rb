# The 15-second readiness check that opens a session (SL-2). One row per client
# per date; the logger fills it in phase 4.
class ReadinessEntry < ApplicationRecord
  belongs_to :client
  belongs_to :session, optional: true
end
