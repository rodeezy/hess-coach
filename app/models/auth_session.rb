# A login session. Named AuthSession so the domain keeps `Session` for training
# sessions, which is what the spec's data model calls them.
class AuthSession < ApplicationRecord
  belongs_to :trainer
end
