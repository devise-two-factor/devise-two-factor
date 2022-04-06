require 'spec_helper'
require 'support/two_factor_authenticatable_doubles'

describe ::Devise::Strategies::TwoFactorAuthenticatable do
  let(:scope) { "foo" }
  let(:strategy) { described_class.new({}, scope) }
  let(:params) do
    { scope => { "otp_attempt" => otp_attempt } }
  end

  let(:resource) do
    res = TwoFactorAuthenticatableWithCustomizeAttrEncryptedDouble.new
    res.otp_secret = res.class.generate_otp_secret
    res.consumed_timestep = nil

    res
  end

  describe "#validate_otp" do
    let(:params) do
      { scope => { "otp_attempt" => otp_attempt } }
    end

    before(:each) do
      allow(strategy).to receive(:params) { params }
      allow(resource).to receive(:otp_required_for_login) { otp_required_for_login }
    end

    subject { strategy.validate_otp(resource) }

    context "when otp is required" do
      let(:otp_required_for_login) { true }

      context "and params do include an otp_attempt" do
        context "that is valid" do
          let(:otp_attempt) { resource.current_otp }
          it { is_expected.to be(true) }
        end

        context "that is invalid" do
          let(:otp_attempt) { Faker::Number.number(digits: 6).to_s }
          it { is_expected.to be(false) }
        end
      end

      context "and params do not include an otp_attempt" do
        let(:otp_attempt) { nil }
        it { is_expected.to be_nil }
      end
    end

    context "when otp is not required" do
      let(:otp_required_for_login) { false }

      context "and params do include an otp_attempt" do
        let(:otp_attempt) { Faker::Number.number(digits: 6).to_s }
        it { is_expected.to be(true) }
      end

      context "and params do not include an otp_attempt" do
        let(:otp_attempt) { nil }
        it { is_expected.to be(true) }
      end
    end
  end

  describe "#authenticate!" do
    subject { strategy.authenticate! }

    before(:each) do
      allow(strategy).to receive(:find_resource_from_mapping_and_auth_hash).and_return(resource)
      allow(strategy).to receive(:params) { params }
      allow(resource).to receive(:otp_required_for_login) { otp_required_for_login }
    end

    context "when resource.otp_required_for_login is true" do
      let(:otp_required_for_login) { true }

      context "and params do not include an otp_attempt" do
        let(:otp_attempt) { nil }
        it { is_expected.not_to eq(:success) }
      end

      context "and params include an invalid otp_attempt" do
        let(:otp_attempt) { Faker::Number.number(digits: 10).to_s }
        it { is_expected.not_to eq(:success) }
      end
    end
  end
end
