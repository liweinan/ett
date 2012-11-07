# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def render_changelog(changelog)
    return '' if changelog.blank?

    if changelog.category == Changelog::CATEGORY[:comment]
      Changelog::TEMPLATE[:comment] % [changelog.user.name, link_to("##{Comment.find_by_id(changelog.references).id}", "#comment-#{Comment.find_by_id(changelog.references).id}")]
    elsif changelog.category == Changelog::CATEGORY[:create]
      Changelog::TEMPLATE[:create] % changelog.user.name
    elsif changelog.category == Changelog::CATEGORY[:delete]
      Changelog::TEMPLATE[:delete] % changelog.user.name
    elsif changelog.category == Changelog::CATEGORY[:clone]
      to_package = Package.find(changelog.to_value)
      Changelog::TEMPLATE[:clone] % [changelog.user.name, link_to("#{to_package.name}@#{to_package.brew_tag.name}", :controller => :packages, :action => :show, :id => escape_url(to_package.name), :brew_tag_id => escape_url(to_package.brew_tag.name))]
    elsif changelog.category == Changelog::CATEGORY[:update]
      Changelog::TEMPLATE[:update] % changelog.user.name
    else
      ''
    end

  end
end
