# The account. One row in the MVP; every other table hangs off it directly or
# through its parent so multi-trainer later is a permissions change, not a
# rewrite (spec section 2).
class Trainer < ApplicationRecord
  has_secure_password
  has_many :auth_sessions, dependent: :destroy

  has_many :clients,           dependent: :destroy
  has_many :exercises,         dependent: :destroy
  has_many :phases,            dependent: :destroy
  has_many :block_presets,     dependent: :destroy
  has_many :presentations,     dependent: :destroy
  has_many :workout_templates, dependent: :destroy
  has_many :metric_types,      dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true
  validates :unit_system, inclusion: { in: %w[lb kg] }

  def display_unit = unit_system
end
