require "rails_helper"

RSpec.describe "Clients", type: :request do
  include_context "seeded trainer"

  before { sign_in(trainer) }

  # These pages touch every Client association. A missing model class only
  # surfaces at request time, which is how Session went unnoticed.
  it "renders the client list" do
    client
    get clients_path
    expect(response).to have_http_status(:ok)
  end

  it "renders a client dashboard" do
    get client_path(client)
    expect(response).to have_http_status(:ok)
  end

  it "renders metrics, notes and assessment for a client" do
    [client_metrics_path(client), client_notes_path(client), client_assessment_path(client)]
      .each do |path|
        get path
        expect(response).to have_http_status(:ok), "#{path} returned #{response.status}"
      end
  end

  describe "creating a client" do
    # An untouched optional select posts "", which must not blow up (UX-10).
    it "accepts a form where only the first name is filled in" do
      expect {
        post clients_path, params: {
          first_name: "Dana", last_name: "", email: "", phone: "", date_of_birth: "",
          sex: "", height_cm: "", start_date: "", disc_type: "", max_hr: "",
          current_phase_id: "", phase_started_on: "", intake_notes: ""
        }
      }.to change(trainer.clients, :count).by(1)

      created = trainer.clients.order(:created_at).last
      expect(created.first_name).to eq("Dana")
      expect(created.disc_type).to be_nil
      expect(response).to redirect_to(client_path(created))
    end

    # All seeded metrics start off except body weight (MT-4).
    it "tracks body weight by default and nothing else" do
      post clients_path, params: { first_name: "Dana" }
      created = trainer.clients.order(:created_at).last

      expect(created.metric_types.pluck(:key)).to eq(["body_weight"])
    end
  end

  describe "archiving (CL-1)" do
    it "hides the client from the active list but keeps the record" do
      client
      post archive_client_path(client)

      get clients_path
      expect(response).to have_http_status(:ok)
      expect(client.reload).to be_archived
    end
  end

  describe "changing phase (CL-6)" do
    it "sets the phase and its start date from a single action" do
      phase = trainer.phases.find_by!(name: "Intensification")

      post change_phase_client_path(client),
        params: { phase_id: phase.id, started_on: "2026-08-01" }

      client.reload
      expect(client.current_phase).to eq(phase)
      expect(client.phase_started_on).to eq(Date.new(2026, 8, 1))
    end
  end

  it "404s on another trainer's client" do
    other = Trainer.create!(email_address: "other@hess.test", password: "secret123")
    stranger = other.clients.create!(first_name: "Nope")

    get client_path(stranger)
    expect(response).to have_http_status(:not_found)
  end
end

RSpec.describe "Unauthenticated pages", type: :request do
  # These are plain ERB rather than Inertia, so they are easy to forget about
  # when styling changes land (that is how the login field went white on white).
  it "renders sign in" do
    get login_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("field")
  end

  it "renders the password reset request page" do
    get new_password_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("field")
  end
end
