class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.string :name
      t.integer :unit_prefix
      t.integer :number
      t.integer :units
      t.boolean :active

      # t.timestamps
    end
  end
end
