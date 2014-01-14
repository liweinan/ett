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

        # marker for the view
        @created = true

        parameters = {'pkg' => package.name,
                      'version' => params[:ver],
                      'release' => package.task.target_release,
                      'tagversion' => package.task.tag_version,
                      'userid' => extract_username(params[:user]),
                      'summary' => "RPMs: Upgrade #{package.name} to #{params[:ver]}",
                      'pwd' => params[:pwd]}
        parameters['seealso'] = params[:see_also] unless params[:see_also].blank?

        email = nil
        unless package.assignee.blank?
          email = package.assignee.email
          parameters['assignee'] = email
        end

        if params.has_key?(:summary)
          parameters['summary'] = params[:summary]
          @response = create_bzs_from_params(parameters, 'el6', package_id)
        else
          if package.task.os_advisory_tags.empty?
            summary = "RHEL6 RPMs: Upgrade #{package.name} to #{params[:ver]}"
            parameters['summary'] = summary
            @response = create_bzs_from_params(parameters, 'el6', package_id)
          else
            # create bzs for each rhels
            package.task.os_advisory_tags.each do |os_adv_tag|
              summary = "RHEL" + os_adv_tag.os_arch[-1, 1] + " RPMs: Upgrade #{package.name} to #{params[:ver]}"
              parameters['summary'] = summary
              @response = create_bzs_from_params(parameters, os_adv_tag.os_arch, package_id)
            end
          end
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

        bz_bug_exist = (package.bz_bugs.select {|bz| bz.bz_id == bz_id}).length > 0

        if bz_bug_exist
          @do_nothing = true
        else
          @do_nothing = false
        end

        if !@do_nothing
          @response = query_bz_bug_info(bz_id, extract_username(params[:user]), params[:pwd])

          if @response.class == Net::HTTPOK

            bz_info = JSON.parse(@response.body)
            @bz_bug =
                BzBug.create_from_bz_info(bz_info, package_id, current_user)
          end
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
          if @response
            render :status => @response.code
          else
            render :status => 200
          end
        end
      }
    end
  end

  def update
    begin
      if params[:bz_action].blank?
        bz_bug = BzBug.find(params[:id])
        bz_bug.bz_id = params[:bz_id]
        bz_bug.save
      else
        begin_check_param
        check_param_user(params)
        check_param_pwd(params)
        end_check_param

        bz_bug = BzBug.find(params[:id])

        if params[:bz_action] == BzBug::BZ_ACTIONS[:done]
          bz_bug.bz_action = BzBug::BZ_ACTIONS[:done]
          bz_bug.save
        end

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
          if params[:bz_action] == BzBug::BZ_ACTIONS[:movetoassigned]
            render :partial => 'bz_bugs/movetoassigned', :status => @response.code
          elsif params[:bz_action] == BzBug::BZ_ACTIONS[:movetomodified]
            render :partial => 'bz_bugs/movetomodified', :status => @response.code
          end
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
      @response = query_bz_bug_info(@bz_bug.bz_id, extract_username(params[:user]), params[:pwd])

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
    # used in the view...
    @package = Package.find(params[:package_id])
    respond_to do |format|
      format.js {
        if params[:id].scan(/\d+/) != ['0'] || params[:id].scan(/\d+/) != [0]
          bz_bug_temp = nil
        else
          bz_bug_temp = BzBug.find(params[:id].scan(/\d+/))[0]
        end
        render(:partial => params[:partial], :locals => {:id => params[:id], :package_id => params[:package_id], :bz_bug => bz_bug_temp})
      }
    end
  end

  protected


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
    if (!current_user.blank? && params[:user].blank?)
      params[:user] = current_user.email
    end

    if (!session[:bz_pass].blank? && params[:pwd].blank?)
      params[:pwd] = session[:bz_pass]
    end
  end

  def end_check_param
    unless @err_msg.blank?
      raise ArgumentError, @err_msg
    end
  end

  def create_bzs_from_params(parameters, os, package_id)
    puts parameters
    puts bz_bug_creation_uri
    response = Net::HTTP.post_form(bz_bug_creation_uri, parameters)

    if response.class == Net::HTTPCreated
      update_bz_pass(params[:pwd])
      #  @response.body
      # "BZ#999999: Upgrade jboss-aggregator to 7.2.0.Final-redhat-7 (MOCK)"
      bug_info = extract_bz_bug_info(response.body)
      bz_id = bug_info[:bz_id]
      response = query_bz_bug_info(bz_id, extract_username(params[:user]), params[:pwd])

      if response.class == Net::HTTPOK
        bz_info = JSON.parse(response.body)
        bz_bug =
            BzBug.create_from_bz_info(bz_info, package_id, current_user, os)
      end
    end
    response
  end

end
