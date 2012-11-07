class UserViewsController < ApplicationController
  before_filter :check_user_id, :only => [:index]

  def index
    @user = User.find_by_name(params[:user_id])
    @packages = Package.find(:all, :conditions => ['user_id = ?', @user.id], :include => [:brew_tag, :label, :marks], :order => "brew_tag_id, label_id")
  end
end
