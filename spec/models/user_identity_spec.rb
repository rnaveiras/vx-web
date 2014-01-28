require 'spec_helper'

describe UserIdentity do
  let(:identity) { build :user_identity }

  context ".find_by_provider" do
    subject { described_class.find_by_provider "github" }
    before { identity.save! }

    it "should find the identity by provider name" do
      expect(subject).to eq identity
    end
  end

  context ".provider?" do
    before { identity.save! }

    it "should be true if provider exists" do
      expect(described_class.provider? "github").to be_true
    end

    it "should be false unless provider" do
      expect(described_class.provider? "not-exists").to be_false
    end
  end

  context "#sc" do
    subject { identity.sc }

    context "for github" do
      before { identity.provider = 'github' }
      it { should be }
      its(:login)        { should eq identity.login }
      its(:access_token) { should eq identity.token }
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

