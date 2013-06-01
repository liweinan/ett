class BzBugsController < ApplicationController
  def create
    package_id = params[:package_id].strip
    bz_id = params[:bz_id].strip

    @bz_bug = BzBug.new
    @bz_bug.package_id = package_id
    @bz_bug.bz_id = bz_id
    @bz_bug.creator_id = current_user.id
    @bz_bug.save

  end

  def update
    bz_bug = BzBug.find(params[:id])
    bz_bug.bz_id = params[:bz_id]
    debugger
    bz_bug.save
  end

  def destroy
    BzBug.find(params[:id]).destroy
  end
end
