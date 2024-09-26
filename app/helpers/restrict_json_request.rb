# RestrictJsonRequest
class RestrictJsonRequest
  def initialize
    @content_type = 'application/json'
  end

  def matches?(request)
    ![request.headers['Accept'], request.headers['HTTP_ACCEPT']].include?(@content_type)
  end
end
