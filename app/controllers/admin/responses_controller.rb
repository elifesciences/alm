class Admin::ResponsesController < Admin::ApplicationController

  load_and_authorize_resource :alert, :parent => false

  def index
    responses = ApiResponse.total(1).order("group_id, display_name").group(:source_id).count
    durations = ApiResponse.total(1).order("group_id, display_name").group(:source_id).average("duration")
    errors = Alert.total_errors(1).order("group_id, display_name").group(:source_id).count
    @sources = Source.active.map { |source| { "id" => source.id,
                                              "name" => source.display_name,
                                              "status" => source.status,
                                              "url" => admin_source_path(source),
                                              "group" => source.group_id,
                                              "response_count" => responses[source.id],
                                              "response_duration" => durations[source.id],
                                              "error_count" => errors[source.id] }}
    render :index
  end

end
