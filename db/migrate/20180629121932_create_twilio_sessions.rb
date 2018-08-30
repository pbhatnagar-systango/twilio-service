class CreateTwilioSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :twilio_sessions do |t|
      t.string :call_type
      t.references :twilio_conversation_group, foreign_key: true, index: true

      t.timestamps
    end
  end
end
