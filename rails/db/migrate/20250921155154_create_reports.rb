class CreateReports < ActiveRecord::Migration[7.2]
  def change
    create_table :reports do |t|
      t.references :user, foreign_key: true, null: false
      t.references :post, foreign_key: true, null: false
      t.references :report_type, foreign_key: true, null: false
      t.text :content, null: false
      t.timestamps
    end
  end
end
