class CreateTwilioVideoCalls < ActiveRecord::Migration[5.2]
  def change
    create_table :twilio_video_calls do |t|
      t.string :room_id
      t.references :twilio_conversation_group, foreign_key: true

      t.timestamps
    end
  end
end
