class Extractor
  def self.extract_url(str)
    if str.blank?
      return ''
    end
    str.gsub(/(https?:\/\/[^(\s|<)]*)/, '<a href="\1" target="_blank">\1</a>')
  end
end