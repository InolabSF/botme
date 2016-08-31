class CreateBots < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.string :name
      t.string :uri
      t.string :verify_token

      t.timestamps null: false
    end
  end
end
