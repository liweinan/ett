class PAttachmentsController < ApplicationController
  before_filter :check_logged_in

  # GET /p_attachments
  # GET /p_attachments.xml
  def index
    @p_attachments = PAttachment.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @p_attachments }
    end
  end

  # GET /p_attachments/1
  # GET /p_attachments/1.xml
  def show
    @p_attachment = PAttachment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @p_attachment }
    end
  end

  # GET /p_attachments/new
  # GET /p_attachments/new.xml
  def new
    @p_attachment = PAttachment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @p_attachment }
    end
  end

  # GET /p_attachments/1/edit
  def edit
    @p_attachment = PAttachment.find(params[:id])
  end

  # POST /p_attachments
  # POST /p_attachments.xml
  def create
    @p_attachment = PAttachment.new(params[:p_attachment])
    @p_attachment.created_by = current_user.id
    respond_to do |format|
      if @p_attachment.save
        format.html {
          @package = @p_attachment.package

          unless params[:div_attachment_notification_area].blank?
            body = Hash.new
            subject = "#{current_user.name} added attachment to #{@package.name}"
            body[:link] = params[:request_path]
            body[:sender] = current_user.name
            body[:action] = "added attachment to #{@package.name}"
            body[:detail] = @p_attachment.attachment_file_name
            body[:updated_at] = @p_attachment.created_at

            notify(text_to_array(params[:div_attachment_notification_area]),
                   subject,
                   body)
          end

          if params[:user].blank?
            redirect_to(:controller => :packages,
                        :action => :show,
                        :id => escape_url(@package.name),
                        :task_id => escape_url(@package.task.name))
          else
            redirect_to(:controller => :packages,
                        :action => :show,
                        :id => escape_url(@package.name),
                        :task_id => escape_url(@package.task.name),
                        :user => params[:user])
          end
        }
      end
    end
  end

  # PUT /p_attachments/1
  # PUT /p_attachments/1.xml
  def update
    @p_attachment = PAttachment.find(params[:id])

    respond_to do |format|
      if @p_attachment.update_attributes(params[:p_attachment])
        format.html do
          redirect_to(@p_attachment,
                      :notice => 'PAttachment was successfully updated.')
        end
        format.xml { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml do
          render :xml => @p_attachment.errors, :status => :unprocessable_entity
        end
      end
    end
  end

  # DELETE /p_attachments/1
  # DELETE /p_attachments/1.xml
  def destroy
    @p_attachment = PAttachment.find(params[:id])
    @p_attachment.destroy

    respond_to do |format|
      format.html { redirect_to(p_attachments_url) }
      format.xml { head :ok }
    end
  end
end
