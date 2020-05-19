# ErrorMailer
class ErrorMailer < ApplicationMailer
  def email_error_info(exception_object, extra_information, to_email, subject)
    @error_trace_string = exception_object.to_s
    @error_message = exception_object.to_s
    begin
      @error_trace_string = exception_object.backtrace.join("\n")
    rescue StackError => e
      puts e.backtrace.join("\n")
    end
    begin
      @error_message = exception_object.message
    rescue StackError => e
      puts e.backtrace.join("\n")
    end
    @extra_information = extra_information
    @subject = subject
    mail(to: to_email, subject: subject)
  end
end
