class TwilioVideoCall < ApplicationRecord
  belongs_to :twilio_conversation_group
end
