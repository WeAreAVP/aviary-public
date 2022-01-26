# coding: utf-8
#
# Transliteration
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Transliteration
  def self.convert!(text, enforce_language = nil)
    language = if enforce_language
                 enforce_input_language(enforce_language)
               else
                 detect_input_language
               end

    map = self.send(language.to_s).sort_by { |k, _v| k.length }.to_a.reverse.to_h
    map.each do |translit_key, translit_value|
      if text.present?
        text.gsub!(translit_key.to_s, translit_value)
      else
        text
      end
    end
    text
  end

  def self.convert(text, enforce_language = nil)
    convert!(text.dup, enforce_language)
  end

  private

  def self.create_russian_map
    self.english.inject({}) do |acc, tuple|
      rus_up, rus_low = tuple.last
      eng_value = tuple.first
      acc[rus_up] ? acc[rus_up] << eng_value.capitalize : acc[rus_up] = [eng_value.capitalize]
      acc[rus_low] ? acc[rus_low] << eng_value : acc[rus_low] = [eng_value]
      acc
    end
  end

  def self.detect_input_language
    :english
  end

  def self.enforce_input_language(language)
    if language == :english
      :russian
    else
      :english
    end
  end

  def self.english
    I18n.locale = :ru
    response = I18n.backend.send(:translations)[:i18n][:transliterate][:rule]
    I18n.locale = :en
    response
  end

  def self.russian
    @russian ||= create_russian_map
  end
end
