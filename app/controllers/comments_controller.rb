class CommentsController < ApplicationController
  before_filter :check_logged_in

  def create

    @comment = Comment.new
    @comment.comment = params[:comment].strip
    @comment.created_at = Time.now
    @package = Package.find(params[:package_id])

    dup_comment = Comment.find_by_comment_and_source(@comment.comment(:source),
                                                     request.remote_ip)

    if no_duplicate_comment(dup_comment)
      @comment.user_id = current_user.id if current_user
      @comment.source = request.remote_ip
      @package.add_comment(@comment)

      if Rails.env.production?
        notify_users_of_comment(@package, @comment, params)
      end
    else
      # doing that so that view does not update anything
      @comment = nil
    end

    respond_to do |format|
      format.js
    end
  end

  def no_duplicate_comment(dup_comment)
    dup_comment.blank? || dup_comment.is_older_than(10.minutes.ago)
  end

  def notify_users_of_comment(package, comment, params)
    if Setting.activated?(package.task, Setting::ACTIONS[:commented])
      debugger

      Notify::Comment.create(current_user,
                             get_package_link(params, package),
                             package,
                             comment,
                             Setting.all_recipients_of_package(package,
                                                               comment.user,
                                                               :comment))
    end

    unless params[:div_comment_notification_area].blank?
      Notify::Comment.create(current_user,
                             get_package_link(params, package),
                             package,
                             comment,
                             params[:div_comment_notification_area])
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
  end
end
