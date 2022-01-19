module URI
  def self.escape(str, unsafe = URI::UNSAFE)
    str.gsub(unsafe, &CGI.method(:escape))
  end
end