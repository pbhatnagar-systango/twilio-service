class CreateTwilioGroupMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :twilio_group_members do |t|
      t.integer :participant_id
      t.string :phone_number
      t.string :tag
      t.references :twilio_conversation_group, foreign_key: true

      t.timestamps
    end
  end
end
