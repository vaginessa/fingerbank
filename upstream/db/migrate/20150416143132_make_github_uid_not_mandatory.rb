class MakeGithubUidNotMandatory < ActiveRecord::Migration
  def change
    change_column :users, :github_uid, :string, :null => true
  end
end
