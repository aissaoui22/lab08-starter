class CreateBandGenres < ActiveRecord::Migration[7.0]
  def change
    create_table :band_genres do |t|
      t.integer :band_id
      t.integer :genre_id

      t.timestamps
    end
  end
end
