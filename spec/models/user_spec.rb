require 'spec_helper'

describe User do
  let(:user) { User.new }
  subject { user }

  context "sync_repos" do
    let(:company)       { create :company }
    let(:external_repo) { Vx::ServiceConnector::Model.test_repo }
    let(:user_repo)     { create :user_repo, external_id: external_repo.id }
    let(:identity)      { user_repo.identity }
    let(:user)          { identity.user }

    subject { user.sync_repos(company) }

    before do
      any_instance_of(Vx::ServiceConnector::Github) do |g|
        mock(g).repos { [external_repo] }
      end
    end

    it { should be }

    it "should create missing user_repos" do
      user_repo.destroy
      expect {
        subject
      }.to change(identity.user_repos, :count).by(1)
    end

    it "should remove unupdated user_repos" do
      user_repo.update! external_id: -1

      expect(subject).to be
      expect{user_repo.reload}.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should update existing user_repos" do
      user_repo.update! description: "..."
      expect(subject).to be
      expect(user_repo.reload.description).to eq 'description'
    end

  end

  context "default_company" do
    let(:user) { create :user }

    let(:c1)  { create :company, name: "c1", id: 1 }
    let(:c2)  { create :company, name: "c2", id: 2 }
    let!(:uc1) { create :user_company, user: user, company: c1, default: 0 }
    let!(:uc2) { create :user_company, user: user, company: c2, default: 1 }

    it "should return first default company" do
      expect(user.default_company).to eq c2
    end
  end

  context "add_to_company" do
    let(:user) { create :user }
    let(:c1)   { create :company, id: 1, name: "c1" }
    let(:c2)   { create :company, id: 2, name: "c2" }

    it "should crate user_company and set is default" do
      expect(user.add_to_company c1).to be
      expect(user.default_company).to eq c1

      expect(user.add_to_company c2).to be
      expect(user.default_company).to eq c2

      expect(user.add_to_company c2).to be
      expect(user.default_company).to eq c2
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  email      :string(255)      not null
#  name       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#

