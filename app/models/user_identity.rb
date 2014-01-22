class UserIdentity < ActiveRecord::Base

  belongs_to :user
  has_many :projects, dependent: :nullify, foreign_key: :identity_id,
    class_name: "::Project"

  validates :user_id, :provider, :uid, :token, presence: true
  validates :user_id, uniqueness: { scope: [:provider] }

  scope :provider, ->(provider) { where provider: provider }

  class << self
    def find_by_provider(p)
      provider(p).first
    end

    def github
      find_by_provider "github"
    end

    def provider?(p)
      provider(p).exists?
    end
  end

  def service_connector
    @service_connector ||= begin
      connector_class = Vx::ServiceConnector.to(provider)
      case provider.to_sym
      when :github
        connector_class.new(login, token)
      end
    end
  end
end

# == Schema Information
#
# Table name: user_identities
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  provider   :string(255)      not null
#  token      :string(255)      not null
#  uid        :string(255)      not null
#  login      :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#

