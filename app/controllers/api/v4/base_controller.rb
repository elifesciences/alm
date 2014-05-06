class Api::V4::BaseController < ActionController::Base
  # include base controller methods
  include Baseable

  respond_to :json

  before_filter :default_format_json, :authenticate_user_via_basic_authentication!
end
