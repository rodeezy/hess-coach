class Phase < ApplicationRecord
  belongs_to :trainer
  has_many :block_presets, dependent: :destroy
end
