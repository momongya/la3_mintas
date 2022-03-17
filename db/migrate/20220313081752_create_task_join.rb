class CreateTaskJoin < ActiveRecord::Migration[6.1]
  def change
    create_table :join_tasks do |t|
      t.integer :task_id
      t.integer :user_id
      t.timestamps null: false
    end
  end
end
