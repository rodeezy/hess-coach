module AuthHelpers
  def sign_in(trainer)
    post login_path, params: { email_address: trainer.email_address, password: "secret123" }
  end
end

RSpec.configure { |c| c.include AuthHelpers, type: :request }
