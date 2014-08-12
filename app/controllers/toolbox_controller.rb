class ToolboxController < ApplicationController

  def get_pac_btns
    respond_to do |format|
      format.js
    end
  end

  def get_pac_form
    respond_to do |format|
      format.js
    end
  end

  def get_initial_pac_btn_switch
    respond_to do |format|
      format.js
    end
  end

  def get_manual_time_track_component
    respond_to do |format|
      format.js
    end
  end

  def get_manual_time_track_components
    respond_to do |format|
      format.js
    end
  end

  def toggle_changelog
    respond_to do |format|
      format.js
    end
  end

  def show_comment_dialog
    respond_to do |format|
      format.js
    end
  end

  def show_log_dialog
    respond_to do |format|
      format.js
    end
  end

  def log_work_done
    respond_to do |format|
      format.js
    end
  end

  def package_ajax_req
    respond_to do |format|
      format.js
    end
  end

  def maven_build_arguments_ajax_req
    respond_to do |format|
      format.js
    end
  end

  def spec_file_ajax_req
    respond_to do |format|
      format.js
    end
  end

  def verify_bz_pwd
    respond_to do |format|
      format.js {
        render :status => verify_bz_credentials(params), :text => nil
      }
    end
  end

  def submit_build
    respond_to do |format|
      format.js
    end
  end

  def edit_spec_file
    @package_id = params[:id]


    @pac = Package.find(@package_id)
    if @pac.spec_file.blank?
      @spec_file = tiny_box_helper(get_spec_file_content(@pac.name,
                                                     @pac.task.primary_os_advisory_tag.candidate_tag))
    else
      @spec_file = tiny_box_helper(@pac.spec_file)
    end

    render :layout => false
  end

  def edit_maven_build_arguments_file
    @package_id = params[:id]


    @pac = Package.find(@package_id)

    if @pac.maven_build_arguments.blank?
      @m_b_a = tiny_box_helper(get_maven_build_arguments_content(@pac.name,
                                                     @pac.task.primary_os_advisory_tag.candidate_tag))
    else
      @m_b_a = tiny_box_helper(@pac.maven_build_arguments)
    end

    render :layout => false
  end

  def get_maven_build_arguments_content(package, branch)
    get_file_content_from_rpm_repo(package, branch, 'maven-build-arguments')
  end

  def get_spec_file_content(package, branch)
    get_file_content_from_rpm_repo(package, branch, "#{package}.spec")
  end

  def get_file_content_from_rpm_repo(package, branch, file)
    uri = URI("http://pkgs.devel.redhat.com/cgit/rpms/#{package}/plain/#{file}?h=#{branch}")
    response = Net::HTTP.get_response(uri)
    response.code == "200" ? response.body : ''
  end

  def press_build_button
    @package_id = params[:id]


    @pac = Package.find(@package_id)
    @clentry = tiny_box_helper("- ")
    @error = nil

    if @pac.status.blank? || @pac.status.code != 'inprogress' || @pac.user.nil?
      @error = "You can only use the Build Button when the status is 'InProgress' and there is an assignee to this package"
    end
    render :layout => false
  end

  def tiny_box_helper(content)
    # metaprogramming
    entry = Object.new
    entry.class.module_eval { attr_accessor :text }
    entry.text = content || "- "
    entry
  end
end
