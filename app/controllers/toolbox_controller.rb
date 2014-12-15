require 'shellwords'
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

  def replace_newline_to_whitespace(string_info)
    if string_info.nil?
      string_info
    else
      # leaving 2 whitespace chars so that it's more visible on the webview
      string_info.gsub("\n", "  ")
    end
  end

  def edit_ini_file
    @package_id = params[:id]
    @package = Package.find(@package_id)

    branch = @package.task.primary_os_advisory_tag.candidate_tag
    ini_file = get_file_content_from_rpm_repo(@package.name, branch,
                                              "#{@package.name}.ini")

    if ini_file.blank?
      @maven_group_artifact = ''
      @build_requires = ''
      @goals = ''
      @profiles = ''
      @properties = ''
      @maven_options = ''
      @envs = ''
      @jvm_options = ''
    else
      unless @package.ini_file.blank?
        data = parse_ini_file(@package.ini_file)
      else
        data = parse_ini_file(ini_file)
      end

      section = data.keys[0]
      config = data[section]
      @maven_group_artifact = section
      @build_requires = replace_newline_to_whitespace(config['buildrequires'])
      @goals = replace_newline_to_whitespace(config['goals'])
      @profiles = replace_newline_to_whitespace(config['profiles'])
      @properties = replace_newline_to_whitespace(config['properties'])
      @maven_options = replace_newline_to_whitespace(config['maven_options'])
      @envs = replace_newline_to_whitespace(config['envs'])
      @jvm_options = replace_newline_to_whitespace(config['jvm_options'])
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
    link = "http://pkgs.devel.redhat.com/cgit/rpms/#{package}/plain/#{file}?h=#{branch}"
    download_item_from_link(link)
  end

  def download_item_from_link(link)
    uri = URI(link)
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

  # this is super hacky, but it works?
  # Call Python ini parser from Ruby.
  # Reason: The Python ini parser is way more complete than the ini parsers
  # existing in rubyland. And the Python ini parser is pretty much guaranteed to
  # work with Koji/Brew
  def parse_ini_file(ini_file_content)
    if Rails.env.production?
      data_json = `python26 #{File.dirname(__FILE__)}/ini_parser.py #{ini_file_content.shellescape}`
    else
      data_json = `python #{File.dirname(__FILE__)}/ini_parser.py #{ini_file_content.shellescape}`
    end
    data = JSON.parse(data_json)
    return data
  end

  def tiny_box_helper(content)
    # metaprogramming
    entry = Object.new
    entry.class.module_eval { attr_accessor :text }
    entry.text = content || "- "
    entry
  end

  def update_pull_request_information
    client = Octokit::Client.new(:access_token => ENV['GITHUB_ETT_TOKEN'])

    active_tasks = Task.all(:conditions => ['active = ?', '1'])
    active_tasks.each do |task|
      task.unclosed_pr_pkgs.each { |pkg| pkg.close_github_pr_closed(client) }
    end
    render :nothing => true
  end
end
