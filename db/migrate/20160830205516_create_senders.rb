class CreateSenders < ActiveRecord::Migration
  def change
    create_table :senders do |t|
      t.string :facebook_id
      t.integer :bot_id

      t.timestamps null: false
    end
  end
end
