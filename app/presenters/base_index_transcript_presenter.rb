# BaseIndexTranscriptPresenter
# presenters/base_index_transcript_presenter.rb
#
# Author::    Muhammad Furqan  (mailto:furqan@weareavp.com)
class BaseIndexTranscriptPresenter < BasePresenter
  def add_marker_occurrences(session_video_text_all, text)
    return text unless session_video_text_all.present?
    session_video_text_all.each do |key_keyword, single_keyword|
      occurrences = text.scan(/\b#{single_keyword}\b/i).uniq
      if occurrences.present?
        occurrences.each do |single_occurrence|
          text = text.gsub(/(#{single_occurrence})/, '<span data-markjs="true" class="highlight-marker mark ' + key_keyword + '">' + single_occurrence + '</span>')
        end
      end
    end
    text
  end
end
