# Sign in and out. Open signup is off by design: the trainer account comes from
# db/seeds or the TRAINER_EMAIL allowlist (spec section 8, Auth).
class AuthSessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to login_path, alert: "Try again later." }

  def new
  end

  def create
    if (trainer = Trainer.authenticate_by(params.permit(:email_address, :password)))
      start_new_session_for trainer
      redirect_to after_authentication_url
    else
      redirect_to login_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to login_path
  end
end
