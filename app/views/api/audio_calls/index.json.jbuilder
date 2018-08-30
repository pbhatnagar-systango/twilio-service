json.success true
json.audio_calls do
  json.array! @twilio_conversation_groups do |twilio_conversation_group|
    if twilio_conversation_group.twilio_audio_call.present?
      json.timestamp twilio_conversation_group.created_at
      json.call_duration twilio_conversation_group.twilio_audio_call.call_duration
      json.call_recording_url twilio_conversation_group.twilio_audio_call.recording_url
      json.call_with twilio_conversation_group.other_group_member_ids @user_id
    end
  end
end
