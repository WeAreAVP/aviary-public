# ApplicationHelper
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module ApplicationHelper
  include ApplicationHelperExtended
  include InterviewIndexHelper
  include DeprecatedHelper
  require 'securerandom'

  def organization_layout?
    nil
  end

  def collection_feed(_collection_id)
    nil
  end

  def boolean_value(value)
    return value.to_s.to_boolean? if value.present?
    false
  end

  def iscached?
    false
  end

  def path_for_request(digital_object_id)
    "/deliverableUnits/#{digital_object_id}?includeNestedLinks=true"
  end

  def stopwords
    %w(a an and are as at be but by for if in into is it no not of on or such that the their then there these they this to was will with)
  end

  def count_em(string, substring)
    substring = substring.delete(')').delete('(')
    string.present? && substring.present? ? string.to_s.scan(/#{Regexp.escape(substring)}/i).count : 0
  end

  # pass path to get current page active link
  def active_class(link_path)
    current_page?(link_path) ? 'active' : ''
  end

  # pass array of paths to get current page active link
  def active_class_multiple(array)
    array.include?(request.path) ? 'active' : ''
  end

  def iframe_responsive_design
    common_style = 'style="position:absolute;top:0;left:0;bottom: 0;right: 0;width:100%;height:100%;"'
    outer_div_style = 'style="padding: 100% 0 0 0;position: relative;overflow: hidden;width: 100%;"'

    [outer_div_style, common_style]
  end

  def random_number
    random = Time.now.to_i
    random.to_s + rand(10_000).to_s
  end

  def random_string(max_length = nil)
    max_length = 5 unless max_length.present?
    o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
    (0...max_length).map { o[rand(o.length)] }.join
  end

  def clean_uri(query)
    query.to_s.gsub(%r{[/?!*'();:@&=+\]\[$,%# ]}, '')
  rescue StandardError
    ''
  end

  def human_to_seconds(time)
    a = time.split(':')
    (a[0].to_i * 60 * 60) + (a[1].to_i * 60) + a[2].to_i
  rescue StandardError
    0
  end

  def interview_video_info(interview)
    interview_video_info_helper(interview)
  end

  def interview_lang_info(language)
    interview_lang_info_helper(language)
  end

  def date_time_format(date_time)
    date_time.to_datetime.strftime('%m-%d-%Y %H:%M:%S')
  end

  # states array for CA and US + None
  def available_states
    none = { none: 'None' }
    divider = { divider: '----------------' }
    canada = CS.states(:ca)
    us = CS.states(:us)

    results = none.merge!(divider)
    results.merge!(us)
    results.merge!(canada)
    results
  end

  def time_to_duration(seconds, mili_seconds = false)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60

    time_string = "#{format('%02d', hours)}:#{format('%02d', minutes)}:#{format('%02d', remaining_seconds)}"

    if mili_seconds
      milliseconds = (seconds % 1) * 1000
      time_string += ".#{format('%03d', milliseconds)}"
    end

    time_string
  rescue StandardError
    '00:00:00'
  end

  # Get the logo of a current organization
  def organization_logo
    main_logo = 'homepage/main-logo.png'
    if current_organization && current_organization.logo_image.present?
      current_organization.logo_image.url
    else
      main_logo
    end
  end

  # Registering Presents
  def present(model, presenter_class = nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)
    yield(presenter) if block_given?
  end

  # Languages array iso-639-1
  def iso_639_1_languages
    languages_array = languages_array_simple
    languages_array.first.map { |l| [l[1], l[0]] }
  end

  def languages_array_simple
    languages_array = ['ab' => 'Abkhazian', 'aa' => 'Afar', 'af' => 'Afrikaans', 'ak' => 'Akan', 'sq' => 'Albanian', 'am' => 'Amharic', 'ar' => 'Arabic', 'an' => 'Aragonese',
                       'hy' => 'Armenian', 'as' => 'Assamese', 'av' => 'Avaric', 'ae' => 'Avestan', 'ay' => 'Aymara', 'az' => 'Azerbaijani', 'bm' => 'Bambara', 'ba' => 'Bashkir',
                       'eu' => 'Basque', 'be' => 'Belarusian', 'bn' => 'Bengali', 'bh' => 'Bihari languages',
                       'bi' => 'Bislama', 'bs' => 'Bosnian', 'br' => 'Breton', 'bg' => 'Bulgarian', 'my' => 'Burmese',
                       'ca' => 'Catalan, Valencian', 'km' => 'Central Khmer', 'ch' => 'Chamorro', 'ce' => 'Chechen', 'ny' => 'Chichewa, Chewa, Nyanja', 'zh' => 'Chinese', 'zh-TW' => 'Chinese (Traditional)',
                       'cu' => 'Church Slavonic, Old Bulgarian, Old Church Slavonic', 'cv' => 'Chuvash', 'kw' => 'Cornish', 'co' => 'Corsican', 'cr' => 'Cree',
                       'hr' => 'Croatian', 'cs' => 'Czech', 'da' => 'Danish', 'dv' => 'Divehi, Dhivehi, Maldivian', 'nl' => 'Dutch, Flemish', 'dz' => 'Dzongkha',
                       'en' => 'English', 'eo' => 'Esperanto', 'et' => 'Estonian', 'ee' => 'Ewe',
                       'fo' => 'Faroese', 'fj' => 'Fijian', 'fi' => 'Finnish', 'fr' => 'French', 'ff' => 'Fulah', 'gd' => 'Gaelic, Scottish Gaelic', 'gl' => 'Galician',
                       'lg' => 'Ganda', 'ka' => 'Georgian', 'de' => 'German', 'ki' => 'Gikuyu, Kikuyu', 'el' => 'Greek (Modern)', 'kl' => 'Greenlandic, Kalaallisut', 'gn' => 'Guarani',
                       'gu' => 'Gujarati', 'ht' => 'Haitian, Haitian Creole', 'ha' => 'Hausa',
                       'he' => 'Hebrew', 'hz' => 'Herero', 'hi' => 'Hindi', 'ho' => 'Hiri Motu', 'hu' => 'Hungarian',
                       'is' => 'Icelandic', 'io' => 'Ido', 'ig' => 'Igbo', 'id' => 'Indonesian',
                       'ia' => 'Interlingua (International Auxiliary Language Association)', 'ie' => 'Interlingue',
                       'iu' => 'Inuktitut', 'ik' => 'Inupiaq', 'ga' => 'Irish', 'it' => 'Italian', 'ja' => 'Japanese',
                       'jv' => 'Javanese', 'kn' => 'Kannada', 'kr' => 'Kanuri', 'ks' => 'Kashmiri', 'kk' => 'Kazakh',
                       'rw' => 'Kinyarwanda', 'kv' => 'Komi', 'kg' => 'Kongo', 'ko' => 'Korean', 'kj' => 'Kwanyama, Kuanyama', 'ku' => 'Kurdish', 'ky' => 'Kyrgyz', 'lo' => 'Lao',
                       'la' => 'Latin', 'lv' => 'Latvian', 'lb' => 'Letzeburgesch, Luxembourgish', 'li' => 'Limburgish, Limburgan, Limburger', 'ln' => 'Lingala', 'lt' => 'Lithuanian',
                       'lu' => 'Luba-Katanga', 'mk' => 'Macedonian', 'mg' => 'Malagasy', 'ms' => 'Malay', 'ml' => 'Malayalam',
                       'mt' => 'Maltese', 'gv' => 'Manx', 'mi' => 'Maori', 'mr' => 'Marathi', 'mh' => 'Marshallese',
                       'ro' => 'Moldovan, Moldavian, Romanian', 'mn' => 'Mongolian', 'na' => 'Nauru', 'nv' => 'Navajo, Navaho', 'nd' => 'Northern Ndebele', 'ng' => 'Ndonga',
                       'ne' => 'Nepali', 'se' => 'Northern Sami', 'no' => 'Norwegian', 'nb' => 'Norwegian Bokmål',
                       'nn' => 'Norwegian Nynorsk', 'ii' => 'Nuosu, Sichuan Yi', 'oc' => 'Occitan (post 1500)',
                       'oj' => 'Ojibwa', 'or' => 'Oriya', 'om' => 'Oromo', 'os' => 'Ossetian, Ossetic',
                       'pi' => 'Pali', 'pa' => 'Panjabi, Punjabi', 'ps' => 'Pashto, Pushto', 'fa' => 'Persian',
                       'pl' => 'Polish', 'pt' => 'Portuguese', 'qu' => 'Quechua', 'rm' => 'Romansh', 'rn' => 'Rundi',
                       'ru' => 'Russian', 'sm' => 'Samoan', 'sg' => 'Sango', 'sa' => 'Sanskrit',
                       'sc' => 'Sardinian', 'sr' => 'Serbian', 'sn' => 'Shona', 'sd' => 'Sindhi',
                       'si' => 'Sinhala, Sinhalese',
                       'sk' => 'Slovak', 'sl' => 'Slovenian', 'so' => 'Somali', 'st' => 'Sotho, Southern',
                       'nr' => 'South Ndebele',
                       'es' => 'Spanish', 'es-419' => 'Spanish (Latin America)', 'su' => 'Sundanese', 'sw' => 'Swahili', 'ss' => 'Swati',
                       'sv' => 'Swedish', 'tl' => 'Tagalog', 'ty' => 'Tahitian', 'tg' => 'Tajik', 'ta' => 'Tamil',
                       'tt' => 'Tatar', 'te' => 'Telugu', 'th' => 'Thai', 'bo' => 'Tibetan', 'ti' => 'Tigrinya',
                       'to' => 'Tonga (Tonga Islands)', 'ts' => 'Tsonga', 'tn' => 'Tswana', 'tr' => 'Turkish',
                       'tk' => 'Turkmen', 'tw' => 'Twi', 'ug' => 'Uighur, Uyghur', 'uk' => 'Ukrainian', 'ur' => 'Urdu', 'uz' => 'Uzbek', 've' => 'Venda', 'vi' => 'Vietnamese', 'vo' => 'Volap_k',
                       'wa' => 'Walloon', 'cy' => 'Welsh', 'fy' => 'Western Frisian', 'wo' => 'Wolof', 'xh' => 'Xhosa', 'yi' => 'Yiddish', 'yo' => 'Yoruba', 'za' => 'Zhuang, Chuang', 'zu' => 'Zulu']
    languages_array
  end

  def valid_json?(json)
    return false if json.nil?
    begin
      ruby_hash = JSON.parse(json)
      ruby_hash
    rescue JSON::ParserError
      false
    end
  end

  def storage_percent(current, allowed)
    100 * current / 1_048_576 / allowed
  end

  def resource_percent(current, allowed)
    100 * current / allowed
  end

  def current_user_is_org_owner_or_admin?
    org_users = current_user.organization_users.active.where(organization_id: current_organization.id) if current_user.present?
    org_users.present? && Role.org_owner_and_admin_id.include?(org_users.first.role_id)
  end

  def current_user_is_org_user?(organization)
    organization.present? && current_user.present? && current_user.organization_users.active.where(organization_id: organization.id).present?
  end

  def current_user_is_current_org_user?
    current_user.present? && current_user.organization_users.active.where(organization_id: current_organization.id).present?
  end

  def cost_pay_as_you_go(resources)
    per_resource = if resources <= 1000
                     15
                   elsif resources <= 4500
                     9
                   elsif resources <= 17_500
                     4
                   elsif resources <= 50_000
                     2
                   else
                     1
                   end
    resources * per_resource.to_f / 100
  end

  def url_image(url)
    url.present? ? "background-size:cover;background-image: url(#{image_url url})" : 'background-size:cover'
  end

  def generate_random_password
    OpenSSL::Digest.new('SHA256').hexdigest(SecureRandom.hex(8)) + '@AvIry'
  end

  def nunncenter_ohms_xsd
    'http://weareavp.com/nunncenter/ohms/ohms.xsd'
  end

  def tracker_params(params, remove_extra_param = false)
    keys_to_extract = allowed_query_params
    raw_params = params.clone
    raw_params = raw_params.except('controller').except('action')
    if remove_extra_param.present?
      remove_extra_param.each do |single_params|
        raw_params.delete(single_params) if raw_params[single_params].present?
        raw_params.delete(single_params.to_s) if raw_params[single_params.to_s].present?
      end
    end
    raw_params = raw_params.select { |key, _| keys_to_extract.include? key }
    raw_params.to_json
  end

  def check_valid_array(value, attribute, length = 50)
    value_current = 'none'
    return value_current unless value.present?
    value_current = if value.class == Array
                      raw_values = []
                      value.each do |single_value|
                        raw_values << if single_value.class == Array && single_value.include?('::')
                                        custom_value = single_value.split('::')
                                        "#{custom_value[1].to_s.strip} (#{custom_value[0].to_s.strip})"
                                      else
                                        single_value.to_s.strip
                                      end
                      rescue StandardError => error
                        puts error
                      end
                      raw_values.join(', ')
                    else
                      value
                    end
    if %w(title_ss collection_title).include?(attribute)
      strip_tags(value_current.to_s.strip).gsub('::', ' ')
    elsif length > 50
      "<div class='interview_td #{attribute}'>#{truncate(strip_tags(value_current.to_s.strip).gsub('::', ' '), length: length)}</div>"
    else
      truncate(strip_tags(value_current.to_s.strip).gsub('::', ' '), length: length)
    end
  end

  def lock_image(classes = '')
    "<img class='#{classes}' src='https://#{ENV['S3_HOST_CDN']}/public/lock.png' alt='content locked'>".html_safe
  end

  def key_hash_manager(string)
    key = OpenSSL::Digest.new('SHA256').hexdigest(string)
    %w[ɷ ʇ ʊ ʚ ʎ ʚ ʛ ɸ ʝ ʇ].each_with_index { |index, single_character| key = key.gsub(single_character.to_s, index) }
    key
  end

  def speaker_regex
    /([A-Za-z0-9._\' ]+: )/
  end
end
