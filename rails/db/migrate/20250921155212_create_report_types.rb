class CreateReportTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :report_types do |t|
      t.timestamps
    end
  end
end
