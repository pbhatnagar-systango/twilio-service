class TwilioConversationGroup < ApplicationRecord

  #Associations
  has_one :twilio_session, dependent: :destroy
  has_one :twilio_audio_call, dependent: :destroy
  has_one :twilio_video_call, dependent: :destroy
  has_many :twilio_group_members, dependent: :destroy

  def other_group_member_ids current_user_id
    other_group_members = self.twilio_group_members.where.not(participant_id: current_user_id)
    other_group_members.first.participant_id if other_group_members.present?
  end
end
