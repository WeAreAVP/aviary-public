# workers/thesaurus_terms_writer_worker.rb
#
# Class ThesaurusTermsWriterWorker
# The class is written to run the bulk import script in the background using Sidekiq gem
#
# Author::    Usman Javaid  (mailto:usman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class ThesaurusTermsWriterWorker
  include Sidekiq::Worker

  def perform(*args)
    file_name, thesaurus_id, append_mode, user_id, action = args

    thesaurus = ::Thesaurus::Thesaurus.find(thesaurus_id)
    file_path = Rails.root.join('public', 'reports', file_name)
    file = File.open(file_path, 'r')

    thesaurus_terms = if file.present?
                        file.respond_to?(:read) ? CSV.foreach(file.path, encoding: 'iso-8859-1:utf-8').map { |row| row[0] } : []
                      else
                        []
                      end

    unless append_mode
      all_terms = ::Thesaurus::ThesaurusTerms.where(thesaurus_information_id: thesaurus.id)
      all_terms.destroy_all if all_terms.present?
    end

    manage_terms(thesaurus_terms.compact, thesaurus)
    thesaurus.number_of_terms = ::Thesaurus::ThesaurusTerms.where(thesaurus_information_id: thesaurus.id).count
    thesaurus.save

    File.delete(file_path)

    send_email_notification(user_id, action, :success)
  rescue StandardError => e
    Rails.logger.error e
    Rails.logger.error args
  end

  def manage_terms(thesaurus_terms, thesaurus)
    if thesaurus_terms.present?
      ::Thesaurus::ThesaurusTerms.transaction do
        thesaurus_terms.each do |single_term|
          ::Thesaurus::ThesaurusTerms.create(thesaurus_information_id: thesaurus.id, term: single_term) unless ::Thesaurus::ThesaurusTerms.where(thesaurus_information_id: thesaurus.id, term: single_term).present?
        end
      end
    end
    thesaurus
  end

  def send_email_notification(user_id, action, status)
    notification = Notification.new
    if status == :success
      notification.subject = "Thesaurus Terms #{action.capitalize}d Successfully"
      notification.heading = "Thesaurus Terms #{action.capitalize}d Successfully"
      notification.sub_heading = ''
      notification.content = "The thesaurus #{action} job that you initiated in Aviary has completed. Please review the results in Aviary and let us know if you have any questions or find any issues"
    else
      notification.subject = "Thesaurus Terms #{action.capitalize} Unsuccessful"
      notification.heading = "Thesaurus Terms #{action.capitalize} Unsuccessful"
      notification.sub_heading = ''
      notification.content = "Your thesaurus #{action} job was unscuccessful. Please try again"
    end

    UserMailer.notification_alert(User.find(user_id), notification).deliver_now
  end
end
