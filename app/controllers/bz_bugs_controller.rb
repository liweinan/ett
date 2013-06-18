class BzBugsController < ApplicationController
  def create
    require 'net/http'
    require 'json'

    package_id = params[:package_id].strip
    package = Package.find(package_id)
    bz_id = ''

    if params[:type] == 'create_bz'
      # create a bug in bugzilla
      begin

        uri = URI.parse(APP_CONFIG["bz_bug_creation_url"])

        @err_msg = ''

        if params[:user].blank?
          @err_msg << "Bugzilla account can't be empty.\n"
        end

        if params[:pwd].blank?
          @err_msg << "Bugzilla account password can't be empty.\n"
        end

        if params[:ver].blank?
          @err_msg << "Package Version (ver) can't be empty.\n"
        end

        unless @err_msg.blank?
          raise ArgumentError, @err_msg
        end

        @response = Net::HTTP.post_form(uri,
                                        'pkg' => package.name,
                                        'version' => params[:ver],
                                        'release' => package.product.target_release,
                                        'tagversion' => package.product.candidate_tag,
                                        'userid' => extract_username(params[:user]),
                                        'pwd' => params[:pwd])

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
        @err_msg = ''

        if params[:user].blank?
          @err_msg << "Bugzilla account can't be empty.\n"
        end

        if params[:pwd].blank?
          @err_msg << "Bugzilla account password can't be empty.\n"
        end

        if params[:bz_id].blank?
          @err_msg << "Bugzilla Bug ID can't be empty.\n"
        end

        unless @err_msg.blank?
          raise ArgumentError, @err_msg
        end

        bz_id = params[:bz_id].strip

        @response = Net::HTTP.get_response(URI("#{APP_CONFIG["bz_bug_query_url"]}#{bz_id}.json?userid=#{extract_username(params[:user])}&pwd=#{params[:pwd]}"))

        if @response.class == Net::HTTPOK
          summary = JSON.parse(@response.body)["summary"]
          @bz_bug = BzBug.new
          @bz_bug.package_id = package_id
          @bz_bug.bz_id = bz_id
          @bz_bug.summary = summary
          @bz_bug.creator_id = current_user.id
          @bz_bug.save
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
    # "999999: Upgrade jboss-aggregator to 7.2.0.Final-redhat-7 (MOCK)"
    bug_info = Hash.new
    unless body.blank?
      bug_info[:bz_id] = body.scan(/^\d+/)[0].to_i
      bug_info[:summary] = body.split(/^\d+:\s*/)[1]
    end
    bug_info
  end
end
