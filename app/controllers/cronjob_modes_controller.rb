class CronjobModesController < ApplicationController
  # GET /cronjob_modes
  # GET /cronjob_modes.xml
  def index
    @cronjob_modes = CronjobMode.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cronjob_modes }
    end
  end

  # GET /cronjob_modes/1
  # GET /cronjob_modes/1.xml
  def show
    @cronjob_mode = CronjobMode.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cronjob_mode }
    end
  end

  # GET /cronjob_modes/new
  # GET /cronjob_modes/new.xml
  def new
    @cronjob_mode = CronjobMode.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cronjob_mode }
    end
  end

  # GET /cronjob_modes/1/edit
  def edit
    @cronjob_mode = CronjobMode.find(params[:id])
  end

  # POST /cronjob_modes
  # POST /cronjob_modes.xml
  def create
    @cronjob_mode = CronjobMode.new(params[:cronjob_mode])

    respond_to do |format|
      if @cronjob_mode.save
        format.html { redirect_to(@cronjob_mode, :notice => 'CronjobMode was successfully created.') }
        format.xml  { render :xml => @cronjob_mode, :status => :created, :location => @cronjob_mode }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cronjob_mode.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cronjob_modes/1
  # PUT /cronjob_modes/1.xml
  def update
    @cronjob_mode = CronjobMode.find(params[:id])

    respond_to do |format|
      if @cronjob_mode.update_attributes(params[:cronjob_mode])
        format.html { redirect_to(@cronjob_mode, :notice => 'CronjobMode was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cronjob_mode.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cronjob_modes/1
  # DELETE /cronjob_modes/1.xml
  def destroy
    @cronjob_mode = CronjobMode.find(params[:id])
    @cronjob_mode.destroy

    respond_to do |format|
      format.html { redirect_to(cronjob_modes_url) }
      format.xml  { head :ok }
    end
  end

  def products_to_build
    response = {:products => []}
    active_tasks = Task.all(:conditions => ['active = ?', "1"])
    active_tasks.each do |task|
      os_adv_tags = task.os_advisory_tags
      distros = []
      to_add = {}
      to_add[:errata] = {}
      branch = ''
      os_adv_tags.each_with_index do |tag, count|
        distros << tag.os_arch
        to_add[tag.os_arch] = tag.modes_to_build

        unless tag.candidate_tag.blank? || tag.errata_prod_release.blank?
          to_add[:errata][tag.candidate_tag + "-candidate"] = tag.errata_prod_release
        end

        branch = tag.candidate_tag if count == 0
      end

      # override the branch string if the field build_branch is specified
      branch = task.build_branch unless task.build_branch.blank?

      product_info = {:version => task.tag_version,
                      :prod => task.prod,
                      :branch => branch,
                      :repository => task.repository,
                      :name => task.name,
                      :distros => distros}

      product_info.merge!(to_add)
      puts product_info

      response[:products] << product_info


    end

    render :json => response
  end
end
