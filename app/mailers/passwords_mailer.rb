class PasswordsMailer < ApplicationMailer
  def reset(trainer)
    @trainer = trainer
    mail subject: "Reset your password", to: trainer.email_address
  end
end
