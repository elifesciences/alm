class Admin::ErrorMessagesController < Admin::ApplicationController
  
  def index
    @error_messages = ErrorMessage.order("updated_at DESC").paginate(:page => params[:page])
    respond_with @error_messages
  end
  
  def destroy
    @error_message = ErrorMessage.find(params[:id])
    ErrorMessage.destroy_all(:message => @error_message.message)
    @error_messages = ErrorMessage.order("updated_at DESC").paginate(:page => params[:page])
    respond_with(@error_messages) do |format|  
      format.js { render :index }
    end
  end
  
end