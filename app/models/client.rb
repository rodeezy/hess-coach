class Client < ApplicationRecord
  belongs_to :trainer
  belongs_to :current_phase, class_name: "Phase", optional: true
end
