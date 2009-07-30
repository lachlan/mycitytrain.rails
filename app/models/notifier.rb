class Notifier < ActionMailer::Base
  

  def feedback(name = "unknown", email = "unknown@example.com", comment = "unknown", sent_at = Time.now)
    subject    '[MyCitytrain] Feedback Received'
    recipients ["lachlan.dowding@gmail.com", "readkev@gmail.com"]
    from       feedback@mycitytrain.info
    sent_on    sent_at
    body       :name => name.squeeze[0..100], :email => email.squeeze[0..100], :comment => comment.squeeze[0..1000]
  end

end
