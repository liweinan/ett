class UsersController < ApplicationController
  # GET /users
  # GET /users.xml
  def index
    if params[:search].blank?
      @users = User.all(:order => :name)
    else
      @users = User.find(:all, :conditions => ['name ILIKE ? OR email ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%"])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
    end
  end

  def search

  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = nil
    if logged_in?
      @user = User.find(params[:id])
    elsif !params[:reset_code].blank?
      @user = User.find_by_id_and_reset_code(params[:id], params[:reset_code])
    end

    respond_to do |format|
      format.html {
        if @user.blank?
          redirect_to '/login'
        end
      }
    end
  end

  # POST /users
  # POST /users.xml
  def create
    params[:user][:email].downcase!
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to(@user) }
        format.xml { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    User.transaction do
      @user = User.find(params[:id])
      respond_to do |format|
        params[:user][:email].downcase!

        if its_myself?(@user) && !params[:time_zone].blank?
          @user.tz = TimeZone.find(params[:time_zone])
          @user.save
        end

        if validate_input_password(@user, params[:user][:password], params[:user][:confirm_password]) && @user.update_attributes(params[:user])
          flash[:notice] = 'User was successfully updated.'
          @user.reset_code = ''
          @user.save
          format.html { redirect_to(@user) }
        else
          format.html { render :action => "edit" }
        end
      end
    end
  end

  def validate_input_password(user, password, confirm_password)
    if user.blank? || password.blank?
      return true # bypass checking if password does not change.
    end

    if (password == confirm_password)
      return true
    else
      user.errors.add(:password, "different from confirm password.")
      return false
    end
  end

  def reset_password
    if request.post?
      if params[:task][:email].blank?
        @user = User.new
        @user.errors.add(:email, "not found.")
      else
        @user = User.find_by_email(params[:task][:email])
        if @user.blank?
          @user = User.new
          @user.errors.add(:email, "User not found.")
          return
        else
          @user.make_token
          Thread.new do
            UserMailer.deliver_reset_password(@user)
          end
          flash[:notice] = "The password reset code has been sent to your email address."
        end
      end
    else # GET
      @user = User.new
    end
  end

# DELETE /users/1
# DELETE /users/1.xml
#  def destroy
#    @user = User.find(params[:id])
#    @user.destroy
#
#    respond_to do |format|
#      format.html { redirect_to(users_url) }
#      format.xml  { head :ok }
#    end
#  end
end
