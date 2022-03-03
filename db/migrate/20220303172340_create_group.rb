class CreateGroup < ActiveRecord::Migration[6.1]
  def change
    create_table :groups do |t|
      t.string :group_name
      t.string :code
      t.string :color
      t.timestamps null: false
    end
  end
end
