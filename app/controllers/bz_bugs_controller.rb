class BzBugsController < ApplicationController
  def create
    package_id = params[:package_id].strip
    bz_id = params[:bz_id].strip

    bz_bug = BzBug.new
    bz_bug.package_id = package_id
    bz_bug.bz_id = bz_id
    bz_bug.creator_id = current_user.id
    bz_bug.save
    @bz_bug_id = bz_id
  end

  def destroy
    BzBug.find(params[:id]).destroy
  end
end
