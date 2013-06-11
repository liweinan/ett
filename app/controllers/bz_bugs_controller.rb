class BzBugsController < ApplicationController
  def create
    package_id = params[:package_id].strip
    package = Package.find(package_id)
    bz_id = ''

    if params[:bz_id].blank?
      # create a bug in bugzilla
      require 'net/http'
      uri = URI.parse(APP_CONFIG["bz_bug_creation_url"])

      @response = Net::HTTP.post_form(uri,
                                      'pkg' => package.name,
                                      'version' => params[:ver],
                                      'release' => params[:rel],
                                      'tagversion' => params[:tver],
                                      'userid' => extract_username(params[:user]),
                                      'pwd' => params[:pwd])

      if @response.class == Net::HTTPCreated
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
    else
      bz_id = params[:bz_id].strip
      @bz_bug = BzBug.new
      @bz_bug.package_id = package_id
      @bz_bug.bz_id = bz_id
      @bz_bug.creator_id = current_user.id
      @bz_bug.save
    end

    respond_to do |format|
      format.js {
        unless @response.blank?
          render :status => @response.code
        end
      }
    end


  end

  def update
    bz_bug = BzBug.find(params[:id])
    bz_bug.bz_id = params[:bz_id]
    bz_bug.save
  end

  def destroy
    BzBug.find(params[:id]).destroy
  end

  def render_partial
    respond_to do |format|
      format.js {
        render(:partial => params[:partial], :locals => {:bz_bug => BzBug.find(params[:id].scan(/\d+/))[0]})
      }
    end
  end

  def new_bz_bug
    @package = Package.find(params[:id])
    respond_to do |format|
      format.js {
        render :partial => 'bz_bugs/new_bz_bug', :locals => {:id => params[:id]}
      }
    end
  end

  def link_bz_bug
    @package = Package.find(params[:id])
    respond_to do |format|
      format.js {
        render :partial => 'bz_bugs/link_bz_bug', :locals => {:id => params[:id]}
      }
    end
  end

  protected

  def extract_bz_bug_info(body)
    #  @response.body
    # "BZ#999999: Upgrade jboss-aggregator to 7.2.0.Final-redhat-7 (MOCK)"
    bug_info = Hash.new
    unless body.blank?
      bug_info[:bz_id] = body.scan(/^BZ#\d+/)[0].split('#')[1].to_i
      bug_info[:summary] = body.split(/BZ#\d+:\s+/)[1]
    end
    bug_info
  end
end
