class AddColumnsToTwilioAudioCall < ActiveRecord::Migration[5.2]
  def change
    add_column :twilio_audio_calls, :twilio_call_sid, :string
    add_column :twilio_audio_calls, :call_duration, :string
  end
end
