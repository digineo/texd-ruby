# frozen_string_literal: true

Rails.application.routes.draw do
  resource :document, only: :show
end
