require "rails_helper"
require Rails.root.join("db/migrate/20260921100003_set_trainer_password_from_env")

# This migration changes who can sign in to a public site, and a mistake here
# either locks the owner out or leaves the default password live.
RSpec.describe SetTrainerPasswordFromEnv do
  let!(:trainer) { Trainer.create!(email_address: "julian@hesscoach.test", password: "password") }

  around do |example|
    ActiveRecord::Migration.suppress_messages { example.run }
  end

  def with_env(env = {}, production: false)
    stub_const("ENV", ENV.to_hash.except("TRAINER_PASSWORD", "TRAINER_EMAIL").merge(env))
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production")) if production
  end

  def migrate = described_class.new.up

  def can_sign_in_with?(password, email: "julian@hesscoach.test")
    Trainer.authenticate_by(email_address: email, password: password).present?
  end

  it "replaces the default password with TRAINER_PASSWORD" do
    with_env({ "TRAINER_PASSWORD" => "a-real-passphrase" })
    migrate

    expect(can_sign_in_with?("a-real-passphrase")).to be(true)
    expect(can_sign_in_with?("password")).to be(false)
  end

  it "ends existing sessions, since a login cookie outlives a password change" do
    AuthSession.create!(trainer: trainer, ip_address: "203.0.113.9")
    with_env({ "TRAINER_PASSWORD" => "a-real-passphrase" })

    expect { migrate }.to change(AuthSession, :count).from(1).to(0)
  end

  it "finds the account by TRAINER_EMAIL when that is set" do
    other = Trainer.create!(email_address: "coach@example.com", password: "password")
    with_env({ "TRAINER_PASSWORD" => "a-real-passphrase", "TRAINER_EMAIL" => "Coach@Example.com" })
    migrate

    expect(can_sign_in_with?("a-real-passphrase", email: "coach@example.com")).to be(true)
    expect(other.reload.authenticate("a-real-passphrase")).to be_truthy
    expect(can_sign_in_with?("password")).to be(true) # the other account is untouched
  end

  describe "in production" do
    it "fails the deploy when TRAINER_PASSWORD is missing, and changes nothing" do
      with_env({}, production: true)

      expect { migrate }.to raise_error(/TRAINER_PASSWORD is not set/)
      expect(can_sign_in_with?("password")).to be(true)
    end

    it "fails the deploy when the account cannot be found" do
      with_env({ "TRAINER_PASSWORD" => "a-real-passphrase", "TRAINER_EMAIL" => "nobody@example.com" },
               production: true)

      expect { migrate }.to raise_error(/No trainer with email nobody@example.com/)
    end
  end

  describe "elsewhere" do
    it "leaves the password alone when the variable is not set, so local setup still works" do
      with_env({})

      expect { migrate }.not_to raise_error
      expect(can_sign_in_with?("password")).to be(true)
    end

    it "skips a missing account rather than failing a fresh local database" do
      with_env({ "TRAINER_PASSWORD" => "a-real-passphrase", "TRAINER_EMAIL" => "nobody@example.com" })

      expect { migrate }.not_to raise_error
    end
  end

  it "refuses a short password wherever it runs, and changes nothing" do
    with_env({ "TRAINER_PASSWORD" => "short" })

    expect { migrate }.to raise_error(/at least 8 characters/)
    expect(can_sign_in_with?("password")).to be(true)
  end

  it "does nothing on rollback" do
    expect { described_class.new.down }.not_to raise_error
  end
end
