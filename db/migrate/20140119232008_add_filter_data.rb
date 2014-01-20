class AddFilterData < ActiveRecord::Migration
  def change
    create_table :filter_data do |t|
      t.string :filter
      t.text :filter_data
      t.timestamp
    end

    add_index :filter_data, :filter, :unique => true
  end
end
