class CreateTask < ActiveRecord::Migration[6.1]
  def change
    create_table :tasks do |t|
      t.integer :group_id
      t.text :todo
      t.integer :priority
      t.integer :leader_id
      t.string :state
      t.timestamps null: false
    end
  end
end
