require 'securerandom'

class Project < ActiveRecord::Base

  include ::PublicUrl::Project

  belongs_to :user_repo, class_name: "::UserRepo"
  has_many :builds, dependent: :destroy, class_name: "::Build"
  has_many :subscriptions, dependent: :destroy, class_name: "::ProjectSubscription"
  has_many :cached_files, dependent: :destroy

  validates :name, :http_url, :clone_url, :token, :user_repo_id,
    :deploy_key, presence: true
  validates :name, :token, uniqueness: true

  delegate :identity, to: :user_repo

  before_validation :generate_token,      on: :create
  before_validation :generate_deploy_key, on: :create

  after_destroy :publish_destroyed


  class << self
    def deploy_key_name
      "Vexor (#{Rails.configuration.x.hostname})"
    end

    def find_by_token(token)
      find_by token: token
    end
  end

  def to_s
    name
  end

  def deploy_key_name
    self.class.deploy_key_name
  end

  def generate_deploy_key
    SSHKey.generate(type: "RSA", bits: 1024).tap do |key|
      self.deploy_key = key.private_key.strip
    end
  end

  def generate_token
    self.token = SecureRandom.uuid
  end

  def hook_url
    "http://#{Rails.configuration.x.hostname}/callbacks/github/#{token}"
  end

  def public_deploy_key
    @public_deploy_key ||= SSHKey.new(deploy_key, comment: deploy_key_name).try(:ssh_public_key)
  end

  def last_build
    @last_build ||= builds.where.not(status: [0,1]).first
  end

  def last_build_status
    last_build ? last_build.status_name : :unknown
  end

  def last_build_created_at
    last_build && last_build.created_at
  end

  def subscribed_by?(user)
    !!subscriptions.where(user_id: user.id).pluck(:subscribe).first
  end

  def subscribe(user)
    subscription = find_or_build_subscription_for_user(user)
    subscription.update subscribe: true
  end

  def unsubscribe(user)
    subscription = find_or_build_subscription_for_user(user)
    subscription.update subscribe: false
  end

  def new_build_from_payload(payload)
    attrs = {
      pull_request_id:  payload.pull_request_number,
      branch:           payload.branch,
      branch_label:     payload.branch_label,
      sha:              payload.head,
      http_url:         payload.url,
    }

    builds.build(attrs)
  end

  def service_connector
    user_repo.try(:identity).try(:service_connector)
  end

  def to_service_connector_model
    Vx::ServiceConnector::Model::Repo.new(id, name)
  end

  private

    def find_or_build_subscription_for_user(user)
      subscription = subscriptions.find_by user_id: user.id
      subscription ||= subscriptions.build user: user
    end

    def publish_destroyed
      publish :destroyed
    end

end

# == Schema Information
#
# Table name: projects
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  http_url     :string(255)      not null
#  clone_url    :string(255)      not null
#  description  :text
#  provider     :string(255)
#  deploy_key   :text             not null
#  token        :string(255)      not null
#  created_at   :datetime
#  updated_at   :datetime
#  identity_id  :integer
#  user_repo_id :integer          not null
#

