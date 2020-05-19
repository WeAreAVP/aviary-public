FactoryBot.define do
  factory :collection_resource_file do
    sort_order 1
    is_downloadable 0
    association :collection_resource, factory: :collection_resource
  end
  trait :check_ffmpeg do
    resource_file File.new("#{Rails.root}/spec/fixtures/small.mp4")
  end
  trait :check_embed do
    embed_code 'https://www.youtube.com/watch?v=zzfCVBSsvqA'
    embed_type 1
    duration 134
    embed_content_type 'video/youtube'
  end

  trait :check_vimeo do
    embed_code '<iframe src="https://player.vimeo.com/video/246297527" width="640" height="360" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>'
    embed_type 3
  end
  trait :check_soundcloud do
    embed_code '<iframe width="100%" height="300" scrolling="no" frameborder="no" allow="autoplay" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/227106443&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true"></iframe>'
    embed_type 8
  end
  trait :check_avalon do
    embed_code '<iframe title=""Black Leadership in the Music Industry" Lecture - avalon_222251-aaamc_sc156_dvf673to674_edit_20130311.mpg" src="https://purl.dlib.indiana.edu/iudl/media/k91f560b46?urlappend=%2Fembed" width="600" height="450" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>'
    embed_type 4
  end
  trait :check_avalon_443 do
    embed_code '<iframe title=""Black Leadership in the Music Industry" Lecture - avalon_222251-aaamc_sc156_dvf673to674_edit_20130311.mpg" src="//purl.dlib.indiana.edu:443/iudl/media/k91f560b46?urlappend=%2Fembed" width="600" height="450" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>'
    embed_type 4
  end
end
