# Library import and its one-time review screen (spec phase 1, section 7, EX-7).
#
# Upload is how the library reaches a deployed server: the CSV is Julian's own
# data and is gitignored, so it is not in the repo the host builds from.
class ImportReviewsController < InertiaController
  MAX_UPLOAD = 2.megabytes

  # Reads the CSV that seeding used. Only meaningful where that file exists,
  # which is a dev machine; on a deployed server use the upload.
  def show
    path = Rails.root.join("db/seeds/private/exercise_library.csv")
    return render inertia: "ImportReview", props: unavailable unless path.exist?

    render inertia: "ImportReview",
      props: review_props(ExerciseLibraryImport.new(trainer: current_trainer, csv_path: path).call)
  end

  # Additive and never deletes: new exercises are added, and video links and
  # how-to text are refreshed by (name, type) (EX-7).
  def create
    file = params[:file]
    if !file.respond_to?(:tempfile)
      return reject("Choose the exercise CSV first.")
    elsif file.size > MAX_UPLOAD
      return reject("That file is larger than 2 MB, which is too big for the exercise sheet.")
    elsif File.extname(file.original_filename.to_s).casecmp?(".xlsx")
      return reject("That is an .xlsx file. Download the sheet as CSV first " \
                    "(Google Sheets: File > Download > Comma-separated values).")
    end

    result = ExerciseLibraryImport.new(trainer: current_trainer, csv_path: file.tempfile.path).call
    render inertia: "ImportReview", props: review_props(result)
  rescue ExerciseLibraryImport::InvalidFile => e
    reject(e.message)
  rescue CSV::MalformedCSVError, EncodingError
    reject("That file could not be read as CSV.")
  end

  private

  def reject(message)
    redirect_to exercises_path, inertia: { errors: { file: message } }
  end

  def unavailable
    { available: false, groups: [], unmatched: [] }
  end

  def review_props(result)
    {
      available: true,
      summary: { created: result.created, updated: result.updated,
                 exceptions: result.exceptions.size },
      groups: result.exceptions.group_by { |e| e[:why] }.map { |why, rows|
        { why: why, action: rows.first[:action],
          rows: rows.map { |r| { name: r[:name], type: r[:type] } } }
      }.sort_by { |g| [g[:action], -g[:rows].size] },
      unmatched: result.unmatched_types.map { |t, n| { type: t, count: n } }
    }
  end
end
