class Client < ApplicationRecord
  belongs_to :trainer
  belongs_to :current_phase, class_name: "Phase", optional: true

  has_many :notes,            dependent: :destroy
  has_many :metric_entries,   dependent: :destroy
  has_many :tracked_metrics,  class_name: "ClientTrackedMetric", dependent: :destroy
  has_many :metric_types,     through: :tracked_metrics
  has_many :goals,            dependent: :destroy
  has_many :sessions,         dependent: :destroy
  has_many :readiness_entries, dependent: :destroy
  has_many :reports,          dependent: :destroy

  validates :first_name, presence: true

  blanks_to_nil :disc_type, :sex, :email, :phone, :last_name

  scope :active,   -> { where(status: "active") }
  scope :archived, -> { where(status: "archived") }

  def full_name = [first_name, last_name].compact_blank.join(" ")

  # Archive hides a client and keeps all their data (CL-1).
  def archive!  = update!(status: "archived")
  def unarchive! = update!(status: "active")
  def archived? = status == "archived"

  def height_m = height_cm && (height_cm.to_d / 100)

  def age_on(date = Date.current)
    return nil if date_of_birth.blank?

    date.year - date_of_birth.year - (date.strftime("%m%d") < date_of_birth.strftime("%m%d") ? 1 : 0)
  end

  # Whole weeks since the phase started, plus 1 (spec 6.4). Information only:
  # the app never advances a phase on its own (CL-6).
  def weeks_in_phase(as_of = Date.current)
    return nil if phase_started_on.blank?

    ((as_of - phase_started_on).to_i / 7) + 1
  end

  def last_session_date = sessions.where(status: "completed").maximum(:session_date)

  def days_since_last_session(as_of = Date.current)
    last = last_session_date
    last && (as_of - last).to_i
  end

  def last_assessment_on = metric_entries.maximum(:measured_on)

  # The home screen flags clients whose last assessment is older than the
  # trainer's cadence, default 30 days (MT-6).
  def assessment_overdue?(as_of = Date.current)
    last = last_assessment_on
    return true if last.nil?

    (as_of - last).to_i > trainer.assessment_cadence_days
  end

  def report_cadence = report_cadence_days || trainer.report_cadence_days

  def next_report_due_on
    last = reports.where(status: "published").maximum(:period_end)
    base = last || start_date
    base && base + report_cadence
  end
end
