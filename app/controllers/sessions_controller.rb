################################################################################
# Handles '/login' and '/logout'
#
# Due to a setting set in config/environment.rb, everything that is saved in the
# session is saved in the database also. (See session_store in that file)
################################################################################
class SessionsController < ApplicationController
  def new
    @session = Session.new
  end

  def create
    update
  end

  def update
    redirect = '/'
    redirect = params[:session][:redirect]  if params[:session][:redirect]

    u = User.find_by_email(params[:session][:email].strip.downcase)
    if u
      if password_valid?(u, params[:session][:password])
        session[:current_user] = u
        flash[:notice] = 'Login succeed.'
        redirect_to(redirect)
      else
        flash[:notice] = 'Login failed: password not correct'
        redirect_to(new_session_path)
      end
    else
      flash[:notice] = 'Login failed: no such user'
      redirect_to(new_session_path)
    end
  end

  def destroy
    reset_session # delete all the data in the session and create a new one
    flash[:notice] = 'Logout succeed.'
    redirect_to('/')
  end

  private
  def password_valid?(user, password)

    return false if user.blank?

    if user.password.blank?
      user.email == password # default password is user email address
    else
      user.password == User.encrypt_password(password)
    end
  end
end