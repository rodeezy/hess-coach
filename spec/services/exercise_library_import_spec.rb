require "rails_helper"
require "csv"

RSpec.describe ExerciseLibraryImport do
  let(:trainer) { Trainer.create!(email_address: "j@hess.test", password: "secret123") }

  before do
    Seeds::Lookups.call(trainer)
    Seeds::ExerciseTypes.call
  end

  def import(rows)
    path = Rails.root.join("tmp", "spec_library_#{SecureRandom.hex(4)}.csv")
    CSV.open(path, "w") do |csv|
      csv << ["Exercise", "Exercise Type", "URL", "Recorded", "How to"]
      rows.each { |r| csv << r }
    end
    described_class.new(trainer: trainer, csv_path: path).call
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  def exercise(name) = trainer.exercises.find_by!(name: name)

  it "imports a row under its type with that type's defaults (EX-3)" do
    result = import([["Barbell Bench Press", "Horizontal Push", "http://v/1", "1", "Press it"]])

    expect(result.created).to eq(1)
    ex = exercise("Barbell Bench Press")
    expect(ex.exercise_type.name).to eq("Horizontal Push")
    expect(ex.prescription).to eq("reps")
    expect(ex.needs_video).to be(false)
    expect(ex.muscle_group_roles).to eq(
      "Chest" => "primary", "Front Delts" => "secondary", "Triceps" => "secondary"
    )
  end

  it "normalizes the two spelling variants in the sheet (section 7)" do
    import([["Knee CARs", "Morning Mobilzation - Knee", "", "0", ""],
            ["Cossack Rocks", "Mobiity", "", "0", ""]])

    expect(exercise("Knee CARs").exercise_type.name).to eq("Morning Mobilizations - Knee")
    expect(exercise("Cossack Rocks").exercise_type.name).to eq("Mobility")
  end

  it "keeps sheet order as progression order within a type (EX-2)" do
    import([["Hand Elevated Pushups", "Horizontal Push", "", "0", ""],
            ["Pushup",                "Horizontal Push", "", "0", ""],
            ["Weighted Pushup",       "Horizontal Push", "", "0", ""]])

    ordered = trainer.exercises.joins(:exercise_type)
      .where(exercise_types: { key: "horizontal_push" }).in_order.pluck(:name)
    expect(ordered).to eq(["Hand Elevated Pushups", "Pushup", "Weighted Pushup"])
  end

  it "sets e1rm_eligible only from the starter list (EX-5)" do
    import([["Barbell Bench Press", "Horizontal Push", "", "0", ""],
            ["Plank - Weight Shift", "Horizontal Push", "", "0", ""]])

    expect(exercise("Barbell Bench Press").e1rm_eligible).to be(true)
    expect(exercise("Plank - Weight Shift").e1rm_eligible).to be(false)
  end

  describe "section 7 exception overrides" do
    it "treats planks as timed core work in Movement Prep, not a chest press" do
      import([["Plank - Elbows Elevated", "Horizontal Push", "", "0", ""]])

      ex = exercise("Plank - Elbows Elevated")
      expect(ex.prescription).to eq("time")
      expect(ex.e1rm_eligible).to be(false)
      expect(ex.load_type).to eq("bodyweight")
      expect(ex.muscle_group_roles).to eq(
        "Abs/Obliques" => "primary", "Chest" => "secondary", "Front Delts" => "secondary"
      )
    end

    it "makes Bear Crawl distance-based" do
      import([["Bear Crawl", "Horizontal Push", "", "0", ""]])
      expect(exercise("Bear Crawl").prescription).to eq("distance")
    end

    it "adds chest as a primary on incline presses" do
      import([["Incline DB Press", "Vertical Push", "", "0", ""]])
      expect(exercise("Incline DB Press").muscle_group_roles["Chest"]).to eq("primary")
    end

    it "moves KB Swing to the Power block" do
      import([["KB Swing", "Plyometrics", "", "0", ""]])
      expect(exercise("KB Swing").muscle_group_roles.keys).to contain_exactly("Glutes", "Hamstrings")
    end

    it "skips the Dynanometer, which is the grip test not an exercise" do
      result = import([["Dynanometer", "Isometrics", "", "0", ""]])

      expect(result.created).to eq(0)
      expect(trainer.exercises.where(name: "Dynanometer")).to be_empty
      expect(result.exceptions.first).to include(action: "skipped")
    end
  end

  describe "load and implement inference (6.1, 6.3)" do
    it "treats chin ups and weighted pushups as bodyweight plus load" do
      import([["Chin Up", "Vertical Pull", "", "0", ""],
              ["Leg Assisted Chin Up", "Vertical Pull", "", "0", ""]])

      expect(exercise("Chin Up").load_type).to eq("bodyweight_plus")
      expect(exercise("Leg Assisted Chin Up").load_type).to eq("assisted")
    end

    it "counts paired dumbbells as two implements but single-arm as one" do
      import([["DB Bench Press", "Horizontal Push", "", "0", ""],
              ["Alternating DB Bench Press", "Horizontal Push", "", "0", ""]])

      expect(exercise("DB Bench Press").implement_count).to eq(2)
      expect(exercise("Alternating DB Bench Press").implement_count).to eq(1)
    end
  end

  describe "re-import (EX-7)" do
    it "adds new rows and refreshes video and how-to without deleting" do
      import([["Pushup", "Horizontal Push", "", "0", ""]])
      expect(exercise("Pushup").needs_video).to be(true)

      result = import([["Pushup",  "Horizontal Push", "http://v/new", "1", "Updated cue"],
                       ["New Lift", "Horizontal Push", "", "0", ""]])

      expect(result.created).to eq(1)
      expect(result.updated).to eq(1)
      expect(exercise("Pushup").video_url).to eq("http://v/new")
      expect(exercise("Pushup").instructions).to eq("Updated cue")
      expect(exercise("Pushup").needs_video).to be(false)
      expect(trainer.exercises.count).to eq(2)
    end

    it "keeps the same name under two different types distinct (section 7)" do
      import([["Shinbox Getups", "Mobility", "", "0", ""],
              ["Shinbox Getups", "Morning Mobilizations - Hip", "", "0", ""]])

      expect(trainer.exercises.where(name: "Shinbox Getups").count).to eq(2)
    end
  end

  it "reports unmatched types rather than inventing them" do
    result = import([["Mystery Move", "Underwater Basket Weaving", "", "0", ""]])

    expect(result.created).to eq(0)
    expect(result.unmatched_types).to eq("Underwater Basket Weaving" => 1)
  end

  it "flags rows where the sheet disagrees with itself about video" do
    result = import([["Pushup", "Horizontal Push", "http://v/1", "0", ""]])

    expect(result.exceptions).to include(
      hash_including(action: "flag", why: a_string_matching(/not recorded but has a video/))
    )
  end
end
