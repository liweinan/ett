class CommentsController < ApplicationController
  before_filter :check_logged_in

  def create

    current_time = Time.now

    @comment = Comment.new
    @comment.comment = params[:comment].strip
    @comment.created_at = current_time
    @package = Package.find(params[:package_id])

    dup_comment = Comment.find_by_comment_and_source(@comment.comment(:source), request.remote_ip)

    if dup_comment.blank? || dup_comment.is_older_than(10.minutes.ago)
      @comment.user_id = current_user.id if current_user
      @comment.source = request.remote_ip
      @package.add_comment(@comment)

      if Rails.env.production?
        if Setting.activated?(@package.brew_tag, Setting::ACTIONS[:commented])
          debugger
          Notify::Comment.create(current_user, params[:request_path], @package, @comment, Setting.all_recipients_of_package(@package, @comment.user, :comment))
        end

        unless params[:div_comment_notification_area].blank?
          Notify::Comment.create(current_user, params[:request_path], @package, @comment, params[:div_comment_notification_area])
        end
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
  end
end
