class CreateFees < ActiveRecord::Migration[5.0]
  def change
    create_table :fees do |t|
      t.string :case_title
      t.string :description
      t.integer :amount
      t.integer :glimr_id
    end
  end
end
