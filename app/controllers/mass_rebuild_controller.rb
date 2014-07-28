class MassRebuildController < ApplicationController
  def first_step
    return unless admin?
    unless params.include?(:task_id)
      render :status => 400, :text => "You did not specify the task to do a mass-rebuild. Return where you came from!"
    else
      @task = find_task(params[:task_id])
      respond_to do |format|
        format.html
      end
    end
  end

  def second_step
    return unless admin?
    version = params[:version]
    repository = params[:repository]
    type_build = params[:type][:option]
    branch = params[:branch]
    filename = params[:filename]
    distros = params[:distros]
    clentry = params[:clentry]

    packages = get_filename_content(repository, branch, filename)

    @msg = []
    packages.each do |pkg|
      @msg << sched_build(pkg, version, repository, type_build, distros, clentry)
    end
    respond_to do |format|
      format.html
    end
  end

  private
  def get_filename_content(repository, branch, filename)
    link = "http://pkgs.devel.redhat.com/cgit/rpms/#{repository}/plain/#{filename}?h=#{branch}"
    uri = URI(link)
    res = Net::HTTP.get_response(uri)
    res.body.split("\n")
  end

  def sched_build(pkg, version, repository, type_build, distros, clentry)
    uri = URI("http://mead.usersys.redhat.com/mead-scheduler/rest/build/sched/eap6/#{pkg}")
    res = Net::HTTP.post_form(uri, :clentry => clentry,
                                   :user_id => current_user.email.gsub('@redhat.com', ''),
                                   :sources => '',
                                   :version => version,
                                   :mode => type_build,
                                   :distros => distros.join(','))
    case res.code
    when '202'
      res.body
    else
      "Could not schedule #{pkg}: #{res.body}"
    end
  end

  def admin?
    unless (logged_in? && can_manage?)
      render :status => 404, :text => "You are now allowed to use mass-rebuild feature"
      return false
    end

    true
  end
end