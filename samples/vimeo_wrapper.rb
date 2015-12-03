module VimeoLib

  VIMEO_URL = 'https://api.vimeo.com'

  def get_quota
    quota = fetch_from_vimeo_api(build_url('me'), {}, 'get')
    quota['upload_quota']
  end

  def vimeo_video_image(streaming_id)
    image = fetch_from_vimeo_api(build_url("videos/#{streaming_id}/pictures"), {}, "GET")['data']
    images = image_list(image.first)
    images[images.count-1]['link']
  rescue
    nil
  end

  def upload_ticket
    opts = { "type": "POST", "redirect_url": ticket_redirect }
  	upload = fetch_from_vimeo_api(build_url("/me/videos"), opts, "POST")
    upload['upload_link_secure']
  end

  private

  def image_list(images)
    images['sizes']
  end

  def ticket_redirect
    "#{request.base_url}/admin/videos/new"
  end

  def build_url(path)
  	"#{VIMEO_URL}/#{path}?access_token=#{ENV['VIMEO_TOKEN']}"
  end

  def fetch_from_vimeo_api(url, opts = {}, method)
    response = RestClient::Request.execute(method: method.to_sym, url: url, payload: opts)
    JSON.parse(response)
  end
end
