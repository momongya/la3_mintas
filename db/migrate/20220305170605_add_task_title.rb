class AddTaskTitle < ActiveRecord::Migration[6.1]
  def change
    add_column :tasks, :title, :string
  end
end
