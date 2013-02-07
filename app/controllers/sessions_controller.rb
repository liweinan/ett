class SessionsController < ApplicationController
  def new
    @session = Session.new
  end

  def create
    update
  end

  def update
    u = User.find_by_email(params[:session][:email].strip.downcase)
    if u
      session[:current_user] = u
      flash[:notice] = 'Login succeed.'
      #redirect_back_or_default('/')
      redirect_to('/')
    else
      flash[:notice] = 'Login failed: no such user'
      redirect_to(new_session_path)
    end
  end

  def destroy
    session[:current_user] = nil
    flash[:notice] = 'Logout succeed.'
    #redirect_back_or_default('/')
    redirect_to('/')
  end
end
