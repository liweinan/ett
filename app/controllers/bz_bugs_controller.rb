class BzBugsController < ApplicationController
  require 'net/http'
  require 'json'

  def create
    package_id = params[:package_id].strip
    package = Package.find(package_id)
    bz_id = ''

    if params[:type] == 'create_bz'
      # create a bug in bugzilla
      begin
        begin_check_param
        check_param_user(params)
        check_param_pwd(params)
        check_param_ver(params)
        end_check_param

        uri = URI.parse(APP_CONFIG["bz_bug_creation_url"])
        parameters = {'pkg' => package.name,
                      'version' => params[:ver],
                      'release' => package.task.target_release,
                      'tagversion' => package.task.candidate_tag,
                      'userid' => extract_username(params[:user]),
                      'pwd' => params[:pwd]}

        parameters['see_also'] = params[:see_also] unless params[:see_also].blank?

        @response = Net::HTTP.post_form(bz_bug_creation_uri, parameters)

        if @response.class == Net::HTTPCreated
          update_bz_pass(params[:pwd])
          #  @response.body
          # "BZ#999999: Upgrade jboss-aggregator to 7.2.0.Final-redhat-7 (MOCK)"
          bug_info = extract_bz_bug_info(@response.body)
          @bz_bug = BzBug.new
          @bz_bug.package_id = package_id
          @bz_bug.bz_id = bug_info[:bz_id]
          @bz_bug.summary = bug_info[:summary]
          @bz_bug.creator_id = current_user.id
          @bz_bug.save
        end
      rescue => e
        @error = e
      end
    elsif params[:type] == 'create_bz_link'
      begin
        begin_check_param
        check_param_user(params)
        check_param_pwd(params)
        check_param_bz_id(params)
        end_check_param

        bz_id = params[:bz_id].strip

        @response = Net::HTTP.get_response(URI("#{APP_CONFIG["bz_bug_query_url"]}#{bz_id}.json?userid=#{extract_username(params[:user])}&pwd=#{params[:pwd]}"))
        #debugger
        #(rdb:2) @response.body
        #{}"{\"id\":\"333\",\"summary\":\"edquota calls /usr/bin/vi, which does not exist\",\"status\":\"CLOSED\",\"release\":\"---\",\"milestone\":\"---\"}

        if @response.class == Net::HTTPOK
          bz_info = JSON.parse(@response.body)
          @bz_bug =
              BzBug.create_from_bz_info(bz_info, package_id, current_user)
        end
      rescue => e
        @error = e
      end
    end

    respond_to do |format|
      format.js {
        unless @error.blank?
          if @error.class == ArgumentError
            # 400 Bad Request
            render :status => 400
          else
            # 500 Internal Server Error
            render :status => 500
          end
        else
          render :status => @response.code
        end
      }
    end
  end

  def update
    begin
      if params[:action].blank?
        bz_bug = BzBug.find(params[:id])
        bz_bug.bz_id = params[:bz_id]
        bz_bug.save
      else
        begin_check_param
        check_param_user(params)
        check_param_pwd(params)
        end_check_param

        if params[:action] == BzBug::BZ_ACTIONS[:movetoassigned]
        end

      end
    rescue => e
      @error = e
    end

    respond_to do |format|
      format.js {
        if params[:action] == BzBug::BZ_ACTIONS[:movetoassigned]

        end
      }
    end
  end

  def sync
    begin
      begin_check_param
      check_param_user(params)
      check_param_pwd(params)
      end_check_param

      @bz_bug = BzBug.find(params[:id])
      @response = Net::HTTP.get_response(
          URI("#{APP_CONFIG["bz_bug_query_url"]}#{@bz_bug.bz_id}.json?userid=#{extract_username(params[:user])}&pwd=#{params[:pwd]}"))

      if @response.class == Net::HTTPOK
        bz_info = JSON.parse(@response.body)
        @bz_bug = BzBug.update_from_bz_info(bz_info, @bz_bug)
      end
    rescue => e
      @error = e
    end

    respond_to do |format|
      format.js {
        unless @error.blank?
          if @error.class == ArgumentError
            # 400 Bad Request
            render :status => 400
          else
            # 500 Internal Server Error
            render :status => 500
          end
        else
          render :status => @response.code
        end
      }
    end
  end

  def destroy
    BzBug.find(params[:id]).destroy
  end

  def render_partial
    respond_to do |format|
      format.js {
        render(:partial => params[:partial], :locals => {:id => params[:id], :package_id => params[:package_id], :bz_bug => BzBug.find(params[:id].scan(/\d+/))[0]})
      }
    end
  end

  protected

  def extract_bz_bug_info(body)
    #  @response.body
    # "999999: Upgrade jboss-aggregator to 7.2.0.Final-redhat-7 (MOCK)"
    bug_info = Hash.new
    unless body.blank?
      bug_info[:bz_id] = body.scan(/^\d+/)[0].to_i
      bug_info[:summary] = body.split(/^\d+:\s*/)[1]
    end
    bug_info
  end

  def check_param_user(params)
    if params[:user].blank?
      @err_msg << "Bugzilla account can't be empty.\n"
    end
  end

  def check_param_pwd(params)
    if params[:pwd].blank?
      @err_msg << "Bugzilla account password can't be empty.\n"
    end
  end

  def check_param_bz_id(params)
    if params[:bz_id].blank?
      @err_msg << "Bugzilla Bug ID can't be empty.\n"
    end
  end

  def check_param_ver(params)
    if params[:ver].blank?
      @err_msg << "Package Version (ver) can't be empty.\n"
    end
  end

  def begin_check_param
    @err_msg = ''
  end

  def end_check_param
    unless @err_msg.blank?
      raise ArgumentError, @err_msg
    end
  end

end
