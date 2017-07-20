class CreateCalls < ActiveRecord::Migration[5.0]
  def change
    create_table :calls do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end
end