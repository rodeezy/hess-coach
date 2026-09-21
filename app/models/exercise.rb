class Exercise < ApplicationRecord
  belongs_to :trainer
  belongs_to :exercise_type

  has_many :exercise_muscle_groups, dependent: :destroy
  has_many :muscle_groups, through: :exercise_muscle_groups

  scope :active,   -> { where(is_archived: false) }
  scope :on_menu,  -> { where(on_menu: true) }
  scope :in_order, -> { order(:sort_order, :name) }

  delegate :main_pattern, :default_block, to: :exercise_type

  # Convenience for specs and the library view: { "Chest" => "primary", ... }
  def muscle_group_roles
    exercise_muscle_groups.includes(:muscle_group).to_h { |m| [m.muscle_group.name, m.role] }
  end

  def primary_muscle_groups   = exercise_muscle_groups.select { |m| m.role == "primary" }
  def secondary_muscle_groups = exercise_muscle_groups.select { |m| m.role == "secondary" }
end
