class Notifier < ActionMailer::Base
  

  def feedback(name = "unknown", email = "unknown@example.com", comment = "unknown", sent_at = Time.now)
    subject    '[MyCitytrain] Feedback Received'
    recipients 'lachlan.dowding@gmail.com'
    from       email
    sent_on    sent_at
    body       :name => name, :email => email, :comment => comment
  end

end
