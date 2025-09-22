class CreateReportTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :report_types do |t|
      t.text :content, null: false
      t.timestamps
    end
  end
end
