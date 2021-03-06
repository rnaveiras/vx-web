class Company < ActiveRecord::Base
  validates :name, presence: true
  validates :name, uniqueness: true

  has_many :projects, dependent: :destroy
  has_many :user_repos, dependent: :destroy
  has_many :user_companies, dependent: :destroy
  has_many :users, through: :user_companies
  has_many :invites, dependent: :destroy

  default_scope ->{ order("companies.name ASC") }

  def default_user_role
    users.any? ? "developer" : "admin"
  end

  def channel
    @channel ||= "company/#{id}"
  end
end

# == Schema Information
#
# Table name: companies
#
#  name               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  id                 :uuid             not null, primary key
#  billing_started_at :datetime
#

