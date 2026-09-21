# Seed logic lives in lib/seeds and is autoloaded, so specs can use it too.

# Open signup is off: the trainer account comes from here or a TRAINER_EMAIL
# allowlist in config (spec section 8, Auth).
email    = ENV.fetch("TRAINER_EMAIL", "julian@hesscoach.test")
password = ENV.fetch("TRAINER_PASSWORD", "password")

trainer = Trainer.find_or_initialize_by(email_address: email)
trainer.assign_attributes(
  password:      password,
  name:          ENV.fetch("TRAINER_NAME", "Julian Hess"),
  business_name: ENV.fetch("TRAINER_BUSINESS", "Hess Coach"),
  unit_system:   "lb",
  timezone:      ENV.fetch("TRAINER_TZ", "America/Chicago")
)
trainer.save!

Seeds::Lookups.call(trainer)
Seeds::ExerciseTypes.call(trainer)

csv_path = Rails.root.join("db/seeds/private/exercise_library.csv")
if csv_path.exist?
  result = ExerciseLibraryImport.new(trainer: trainer, csv_path: csv_path).call
  puts "Imported library: #{result.created} created, #{result.updated} updated"
  puts "  exceptions to review  #{result.exceptions.size}"
  result.unmatched_types.each { |t, n| puts "  UNMATCHED TYPE #{t.inspect} (#{n} rows)" }
else
  puts "No exercise_library.csv in db/seeds/private - skipping library import"
end


puts "Seeded trainer #{trainer.email_address}"
puts "  main patterns   #{MainPattern.count}"
puts "  muscle groups   #{MuscleGroup.count}"
puts "  phases          #{trainer.phases.count}"
puts "  block presets   #{trainer.block_presets.count}"
puts "  presentations   #{trainer.presentations.count}"
