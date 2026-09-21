# frozen_string_literal: true

# Base for every Inertia-rendered screen. Plain ERB pages (login, password reset
# and the public report card) inherit ApplicationController instead, so they
# never load the Inertia entrypoint.
class InertiaController < ApplicationController
  layout "inertia"

  inertia_share trainer: -> {
    Current.trainer&.as_json(only: %i[id name business_name accent_color unit_system])
  }
end
