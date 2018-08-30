class AddCallDurationToTwilioVideoCall < ActiveRecord::Migration[5.2]
  def change
    add_column :twilio_video_calls, :call_duration, :string
  end
end
