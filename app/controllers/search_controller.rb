class SearchController < ApplicationController
  before_filter :check_tag

  def packages
    if request.post?
      @found = {}
      @not_found = []
      @keyword = params[:keyword]
      packages = params[:keyword].split("\r\n")
      packages.each do |package|
        unless package.blank?
          package = package.strip
          ps = Package.find_by_sql("select * from packages where name ilike '%#{package}%' and brew_tag_id = #{btagid}")

          if ps.blank?
            @not_found << package
          else
            _ps = []
            ps.each do |_p|
              _ps << _p
            end
            @found[package] = _ps
          end
        end
      end
    end
  end
end
