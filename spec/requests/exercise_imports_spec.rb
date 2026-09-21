require "rails_helper"

RSpec.describe "Importing the exercise library", type: :request do
  include_context "seeded trainer"

  before do
    Seeds::ExerciseTypes.call(trainer)
    sign_in(trainer)
  end

  # Header row exactly as Julian's sheet has it, not as the spec spells it.
  SHEET_HEADER = "Exercise,Exercise Type,URL,RECORDED?,How to:\n".freeze

  def upload(body, name: "library.csv", type: "text/csv")
    Rack::Test::UploadedFile.new(StringIO.new(body), type, original_filename: name)
  end

  def post_upload(body, **opts)
    post import_exercises_path, params: { file: upload(body, **opts) }
  end

  it "imports a CSV straight from the sheet, including how-to text" do
    post_upload(SHEET_HEADER + "Barbell Bench Press,Horizontal Push,http://v/1,1,Press it\n")

    expect(response).to have_http_status(:ok)
    ex = trainer.exercises.find_by!(name: "Barbell Bench Press")
    expect(ex.exercise_type.name).to eq("Horizontal Push")
    expect(ex.video_url).to eq("http://v/1")
    # The sheet calls the column "How to:". Reading only "How to" left this blank.
    expect(ex.instructions).to eq("Press it")
  end

  it "reads a file with a byte order mark, which Excel writes" do
    post_upload("﻿" + SHEET_HEADER + "Pushup,Horizontal Push,,0,\n")

    expect(response).to have_http_status(:ok)
    expect(trainer.exercises.where(name: "Pushup")).to exist
  end

  it "is additive: a second upload refreshes text and never duplicates or deletes" do
    post_upload(SHEET_HEADER + "Pushup,Horizontal Push,,0,\nChin Up,Vertical Pull,,0,\n")
    post_upload(SHEET_HEADER + "Pushup,Horizontal Push,http://v/new,1,New cue\n")

    expect(trainer.exercises.where(name: "Pushup").count).to eq(1)
    expect(trainer.exercises.find_by!(name: "Pushup").instructions).to eq("New cue")
    expect(trainer.exercises.where(name: "Chin Up")).to exist # not in the second file, kept
  end

  it "shows what changed, in the same review as the seeded import" do
    post_upload(SHEET_HEADER + "Plank - Elbows Elevated,Horizontal Push,,0,\n")

    expect(response.body).to include("Core work, not a chest press")
  end

  describe "refusing a file that is not the exercise sheet" do
    def expect_rejected(message)
      expect(response).to redirect_to(exercises_path)
      follow_redirect!
      expect(response.body).to include(message)
    end

    it "asks for a file when none is chosen" do
      post import_exercises_path
      expect_rejected("Choose the exercise CSV")
    end

    it "says so for an .xlsx, and how to get a CSV" do
      post_upload("PK\x03\x04binary", name: "Exercise Library.xlsx",
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      expect_rejected("Download the sheet as CSV")
    end

    it "names the missing columns instead of importing nothing and reporting success" do
      expect { post_upload("Name,Kind\nPushup,Push\n") }.not_to change(trainer.exercises, :count)
      expect_rejected("Exercise Type")
    end

    it "leaves the library untouched when the file cannot be parsed" do
      expect { post_upload(SHEET_HEADER + "\"unterminated,Horizontal Push,,0,\n") }
        .not_to change(trainer.exercises, :count)
      expect_rejected("could not be read as CSV")
    end

    it "refuses an oversized file" do
      post_upload(SHEET_HEADER + ("x" * 3.megabytes))
      expect_rejected("larger than 2 MB")
    end
  end

  it "requires a signed in trainer" do
    delete logout_path
    post_upload(SHEET_HEADER + "Pushup,Horizontal Push,,0,\n")

    expect(response).to redirect_to(login_path)
    expect(trainer.exercises.where(name: "Pushup")).not_to exist
  end

  it "renders the Library with the upload panel" do
    get exercises_path
    expect(response).to have_http_status(:ok)
  end
end
