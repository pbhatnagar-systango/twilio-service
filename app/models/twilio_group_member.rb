class TwilioGroupMember < ApplicationRecord

  #Associations
  belongs_to :twilio_conversation_group

end
