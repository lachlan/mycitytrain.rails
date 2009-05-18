require 'test_helper'

class NotifierTest < ActionMailer::TestCase
  test "send_email" do
    @expected.subject = 'Notifier#send_email'
    @expected.body    = read_fixture('send_email')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Notifier.create_send_email(@expected.date).encoded
  end

end
