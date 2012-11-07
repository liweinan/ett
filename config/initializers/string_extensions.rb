class String
  def strip_html
    self.gsub(/<\/?[^>]*>/, "")
  end

  def extract_urls
    self.split(/\s+/).find_all { |u| u =~ /^https?:/ }
  end

end
