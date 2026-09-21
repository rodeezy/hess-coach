require "csv"

# Imports Julian's exercise sheet (spec EX-1, EX-7). Nothing in the library is
# invented here: every exercise, type, URL and how-to comes from his CSV. What
# this class adds is the type-driven defaults from spec section 7, the named
# exception overrides, and a list of everything a human should look at once.
#
# Re-import is additive: it adds new rows and refreshes video and how-to text by
# (name, type). It never deletes (EX-7).
class ExerciseLibraryImport
  Result = Struct.new(:created, :updated, :exceptions, :unmatched_types, keyword_init: true) do
    def total = created + updated
  end

  # Raised for a file that is not the exercise sheet, so an upload can say so
  # instead of importing nothing and reporting success.
  class InvalidFile < StandardError; end

  REQUIRED_HEADERS = ["exercise", "exercise type"].freeze

  # Julian's sheet heads its columns "RECORDED?" and "How to:", while the spec
  # names them Recorded and How to. Compare headers loosely (case, trailing
  # colon or question mark) so a CSV straight from Google Sheets works, and a
  # hand-edited one does too. Without this, every how-to imports blank.
  HEADER_NORMALIZER = ->(header) { header.to_s.strip.downcase.sub(/[?:]+\s*\z/, "").strip }

  # The sheet carries two misspellings (spec 7).
  TYPE_SPELLING_FIXES = {
    "mobiity" => "mobility",
    "morning mobilzation" => "morning mobilizations"
  }.freeze

  # Spec section 7, "Starter list of e1RM-eligible lifts". Everything else
  # imports as not eligible (EX-5).
  E1RM_ELIGIBLE = [
    "Machine Bench Press", "DB Bench Press", "Hooklying Bench Press", "Barbell Bench Press",
    "Weighted Pushup", "Machine Chest Supported Row", "DB Chest Supported Row", "3 Point Row",
    "Bentover DB Row", "Bentover Barbell Row", "Incline DB Press", "Incline Barbell Press",
    "Long Seated Barbell Overhead Press", "Seated Barbell Overhead Press",
    "Standing Barbell Overhead Press", "Long Seated DB Overhead Press", "Seated DB Overhead Press",
    "Standing DB Overhead Press", "Lat Puldown", "Chin Up", "Weighted Chin Up", "Pull Up",
    "Weighted Pullup", "Goblet Squat", "Zercher Squat", "Front Squat", "Box Squat", "Back Squat",
    "Split Squat", "RFESS", "Trap Bar Deadlift", "KB Deadlift", "DB/KB RDL", "Barbell RDL",
    "Machine RDL", "Barbell Deadlift", "Hip Thrust"
  ].map(&:downcase).to_set.freeze

  # Type defaults are wrong for this handful. The import applies the override and
  # lists the row on the review screen (spec 7, "Exceptions the import flags").
  OVERRIDES = [
    { match: ->(n, t) { t == "horizontal_push" && (n.start_with?("plank -") || n.in?(["bear iso", "single arm plank", "sa plank rotations", "iso pushup"])) },
      prescription: "time", block: "movement_prep", e1rm: false, load_type: "bodyweight",
      primary: %w[abs_obliques], secondary: %w[chest front_delts],
      why: "Core work, not a chest press" },
    { match: ->(n, t) { t == "horizontal_push" && n == "bear crawl" },
      prescription: "distance", block: "movement_prep", e1rm: false, load_type: "bodyweight",
      primary: %w[abs_obliques], secondary: %w[chest front_delts],
      why: "Distance-based, otherwise as planks" },
    { match: ->(n, t) { t == "vertical_push" && n.include?("incline") },
      primary_add: %w[chest], why: "Incline pressing adds chest as a primary" },
    { match: ->(_n, t) { false }, why: "" }, # placeholder kept out of the way
    { match: ->(n, _t) { n.in?(["passive hang", "weighted passive hang", "iso chin up (top)", "iso pull up (top)"]) },
      prescription: "time", primary: %w[forearms_grip lats], secondary: [], e1rm: false,
      why: "Timed hang, graded on grip and lats" },
    { match: ->(n, _t) { n == "single leg stand" || n.start_with?("iso split squat") || n == "iso rfess" || n.include?("wall sit") },
      prescription: "time", e1rm: false, why: "Timed hold" },
    { match: ->(n, _t) { n.in?(["croutch walks", "walking lunges"]) },
      why: "Reps or distance, trainer's choice per workout" },
    { match: ->(n, t) { t == "bridge_thrust" && n == "trx hamstring curl" },
      primary: %w[hamstrings], secondary: %w[glutes], why: "Hamstrings lead, not glutes" },
    { match: ->(n, _t) { n == "45 degree hyperextension" },
      primary: %w[glutes hamstrings spinal_erectors], secondary: [],
      why: "All three act as primaries" },
    { match: ->(n, _t) { n.in?(["jefferson curl", "db flexion rdl"]) },
      primary: %w[spinal_erectors], secondary: [], e1rm: false,
      why: "Spinal erector work, not a hinge max" },
    { match: ->(n, t) { t == "plyometrics" && n.include?("kb swing") },
      block: "power", primary: %w[glutes hamstrings], secondary: [],
      why: "Belongs in the Power block" },
    { match: ->(n, _t) { n.in?(["copenhagen plank", "active copenhagen"]) },
      prescription: "time", primary: %w[adductors], secondary: %w[abs_obliques], e1rm: false,
      why: "Adductor work, timed" },
    { match: ->(n, t) { t == "isometrics" && n.start_with?("dynanometer") },
      skip: true, why: "Not a programmed exercise: this is the grip strength test (MT-1)" }
  ].reject { |o| o[:why].blank? }.freeze

  def initialize(trainer:, csv_path:)
    @trainer  = trainer
    @csv_path = csv_path
    @muscles  = MuscleGroup.pluck(:key, :id).to_h
    @types_by_name = ExerciseType.all.index_by { |t| normalize_type_name(t.name) }
  end

  def call
    validate_headers!
    # One transaction, so a file that fails halfway leaves nothing half-imported.
    ActiveRecord::Base.transaction { import_rows }
  end

  def import_rows
    created = updated = 0
    exceptions = []
    unmatched = Hash.new(0)
    position = Hash.new(0)

    CSV.foreach(@csv_path, headers: true, encoding: "bom|utf-8",
                           header_converters: [HEADER_NORMALIZER]) do |row|
      name = row["exercise"].to_s.strip
      next if name.blank?

      raw_type = row["exercise type"].to_s.strip
      type = @types_by_name[normalize_type_name(raw_type)]
      if type.nil?
        unmatched[raw_type] += 1
        next
      end

      override = OVERRIDES.find { |o| o[:match].call(name.downcase, type.key) }
      if override&.dig(:skip)
        exceptions << { name: name, type: type.name, action: "skipped", why: override[:why] }
        next
      end

      url  = row["url"].to_s.strip.presence
      how  = row["how to"].to_s.strip.presence
      rec  = row["recorded"].to_s.strip

      exercise = @trainer.exercises.find_or_initialize_by(
        exercise_type_id: type.id, name: name
      )
      is_new = exercise.new_record?

      if is_new
        exercise.assign_attributes(
          sort_order:      position[type.id],
          prescription:    override&.dig(:prescription) || type.default_prescription,
          e1rm_eligible:   override&.key?(:e1rm) ? override[:e1rm] : E1RM_ELIGIBLE.include?(name.downcase),
          is_unilateral:   type.key.end_with?("_unilateral"),
          load_type:       override&.dig(:load_type) || infer_load_type(name),
          implement_count: infer_implement_count(name)
        )
      end

      # Refreshed on every import, new or not (EX-7).
      exercise.video_url    = url if url
      exercise.instructions = how if how
      exercise.needs_video  = url.nil?
      exercise.save!

      apply_muscles(exercise, type, override)
      position[type.id] += 1
      is_new ? created += 1 : updated += 1

      if override
        exceptions << { name: name, type: type.name, action: "overridden", why: override[:why] }
      end
      if url.present? && rec == "0"
        exceptions << { name: name, type: type.name, action: "flag",
                        why: "Marked not recorded but has a video link" }
      elsif url.blank? && rec == "1"
        exceptions << { name: name, type: type.name, action: "flag",
                        why: "Marked recorded but has no video link" }
      end
    end

    Result.new(created: created, updated: updated, exceptions: exceptions,
               unmatched_types: unmatched)
  end
  private :import_rows

  private

  def validate_headers!
    header = CSV.open(@csv_path, encoding: "bom|utf-8", &:shift) || []
    missing = REQUIRED_HEADERS - header.map(&HEADER_NORMALIZER)
    return if missing.empty?

    raise InvalidFile,
      "That does not look like the exercise sheet. It needs an Exercise column and an " \
      "Exercise Type column (missing: #{missing.join(', ')})."
  end

  # "Morning Mobilzation - Knee" and "Mobiity" are typos in the sheet (spec 7).
  def normalize_type_name(value)
    s = value.to_s.downcase.strip.gsub(/\s+/, " ")
    TYPE_SPELLING_FIXES.each { |wrong, right| s = s.sub(wrong, right) }
    s
  end

  # Only these produce an e1RM from body weight plus added load (spec 6.1).
  def infer_load_type(name)
    n = name.downcase
    return "assisted"        if n.include?("assisted")
    return "bodyweight_plus" if n.match?(/\b(chin up|pull up|pullup|weighted pushup)\b/)
    "external"
  end

  # Paired dumbbells and kettlebells are logged per implement but count double
  # for tonnage (spec 6.1, 6.3).
  def infer_implement_count(name)
    n = name.downcase
    return 1 if n.match?(/\b(single arm|sa|single leg|sl|alternating|offset|1 arm)\b/)
    n.match?(/\b(db|dumbbell|kb|kettlebell)\b/) ? 2 : 1
  end

  def apply_muscles(exercise, type, override)
    primary   = override&.dig(:primary)
    secondary = override&.dig(:secondary)

    pairs =
      if primary
        primary.map { |k| [k, "primary"] } + (secondary || []).map { |k| [k, "secondary"] }
      else
        type.exercise_type_muscle_groups.map { |m| [m.muscle_group.key, m.role] }
      end
    pairs += (override&.dig(:primary_add) || []).map { |k| [k, "primary"] }

    pairs.uniq { |k, _| k }.each do |key, role|
      row = ExerciseMuscleGroup.find_or_initialize_by(
        exercise: exercise, muscle_group_id: @muscles.fetch(key)
      )
      row.role = role
      row.save!
    end
  end
end
