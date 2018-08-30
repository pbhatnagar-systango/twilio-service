class CreateTwilioAudioCalls < ActiveRecord::Migration[5.2]
  def change
    create_table :twilio_audio_calls do |t|
      t.string :recording_url
      t.text :transcript_data
      t.references :twilio_conversation_group, index: true

      t.timestamps
    end
  end
end
