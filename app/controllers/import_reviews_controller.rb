# The one-time review screen for the library import (spec phase 1, section 7).
# Exceptions are recomputed from the CSV rather than stored: the import is a pure
# function over that file, and this screen is meant to be read once.
class ImportReviewsController < InertiaController
  def show
    path = Rails.root.join("db/seeds/private/exercise_library.csv")
    unless path.exist?
      return render inertia: "ImportReview", props: { available: false, groups: [], unmatched: [] }
    end

    result = ExerciseLibraryImport.new(trainer: current_trainer, csv_path: path).call

    render inertia: "ImportReview", props: {
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
