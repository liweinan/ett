class UserViewsController < ApplicationController
  before_filter :check_user_id, :only => [:index]

  def index
    @user = User.find_by_name(params[:user_id])
    @packages = Package.find(:all, :conditions => ['user_id = ?', @user.id], :include => [:product, :label, :marks], :order => "product_id, label_id")
  end
end
