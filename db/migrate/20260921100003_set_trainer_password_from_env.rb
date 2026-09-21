# One-off: replaces the trainer's password with TRAINER_PASSWORD.
#
# The production account was seeded with the default password, on a public URL.
# The host offers no shell, and this app boots through `db:prepare`, which runs
# pending migrations, so this is how the change gets applied.
#
# It runs once per database. Changing TRAINER_PASSWORD afterwards will not
# change the password again.
#
# In production a missing variable, a missing account or a weak password
# raises rather than skipping. A skip would be recorded as done and never run
# again, leaving the default password in place with nothing to say so. Failing
# the boot is loud, and once the variable is fixed the migration runs normally.
class SetTrainerPasswordFromEnv < ActiveRecord::Migration[8.1]
  MIN_LENGTH = 8

  # Own tiny models, so this migration keeps working if the app's models change.
  class MigrationTrainer < ActiveRecord::Base
    self.table_name = "trainers"
    has_secure_password
  end

  class MigrationAuthSession < ActiveRecord::Base
    self.table_name = "auth_sessions"
  end

  def up
    password = ENV["TRAINER_PASSWORD"].to_s
    email    = ENV.fetch("TRAINER_EMAIL", "julian@hesscoach.test").strip.downcase

    if password.empty?
      raise "TRAINER_PASSWORD is not set. Set it and deploy again." if Rails.env.production?

      say "TRAINER_PASSWORD not set; leaving the trainer's password alone"
      return
    end

    if password.length < MIN_LENGTH
      raise "TRAINER_PASSWORD must be at least #{MIN_LENGTH} characters."
    end

    trainer = MigrationTrainer.find_by(email_address: email)
    if trainer.nil?
      raise "No trainer with email #{email}. Set TRAINER_EMAIL to the account's email." if Rails.env.production?

      say "No trainer with email #{email}; nothing to update"
      return
    end

    trainer.update!(password: password)

    # A login cookie outlives a password change, so anyone who signed in with
    # the old password would stay signed in. End every existing session.
    signed_out = MigrationAuthSession.where(trainer_id: trainer.id).delete_all

    say "Password for #{email} set from TRAINER_PASSWORD; #{signed_out} existing session(s) ended"
  end

  # A password hash cannot be restored, and there is nothing to undo.
  def down; end
end
