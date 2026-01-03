# frozen_string_literal: true

require "rails_helper"

RSpec.describe Github::AppJwtGenerator do
  # Generate a test RSA key pair
  let(:test_private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:test_app_id) { "123456" }

  describe ".call" do
    before do
      allow(Github::AppConfig).to receive(:app_id).and_return(test_app_id)
      allow(Github::AppConfig).to receive(:private_key).and_return(test_private_key.to_pem)
    end

    it "generates valid RS256 JWT" do
      result = described_class.call

      expect(result).to be_success

      jwt = result.value!
      # Decode without verification to check structure
      decoded = JWT.decode(jwt, test_private_key.public_key, true, { algorithm: "RS256" })

      expect(decoded).to be_an(Array)
      expect(decoded[0]).to include("iss", "iat", "exp")
    end

    it "sets correct expiry (approximately 10 minutes from now)" do
      before_time = Time.now.to_i
      result = described_class.call
      after_time = Time.now.to_i

      jwt = result.value!
      decoded = JWT.decode(jwt, test_private_key.public_key, true, { algorithm: "RS256" })

      # exp should be within 10 minutes + 1 second tolerance from call time
      expect(decoded[0]["exp"]).to be_between(before_time + 600, after_time + 601)
    end

    it "sets issued-at time in the past (clock drift handling)" do
      before_time = Time.now.to_i
      result = described_class.call

      jwt = result.value!
      decoded = JWT.decode(jwt, test_private_key.public_key, true, { algorithm: "RS256" })

      # iat should be 60 seconds before current time (within tolerance)
      expect(decoded[0]["iat"]).to be_between(before_time - 61, before_time - 59)
    end

    it "sets issuer to app_id" do
      result = described_class.call
      jwt = result.value!
      decoded = JWT.decode(jwt, test_private_key.public_key, true, { algorithm: "RS256" })

      expect(decoded[0]["iss"]).to eq(test_app_id)
    end

    it "uses RS256 algorithm in JWT header" do
      result = described_class.call
      jwt = result.value!
      decoded = JWT.decode(jwt, test_private_key.public_key, true, { algorithm: "RS256" })

      expect(decoded[1]["alg"]).to eq("RS256")
    end

    context "when private key is not configured" do
      before do
        allow(Github::AppConfig).to receive(:private_key).and_return(nil)
      end

      it "returns failure" do
        result = described_class.call

        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:jwt_generation_failed)
        expect(result.failure[:message]).to include("private key not configured")
      end
    end

    context "when app_id is not configured" do
      before do
        allow(Github::AppConfig).to receive(:app_id).and_return(nil)
      end

      it "returns failure" do
        result = described_class.call

        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:jwt_generation_failed)
        expect(result.failure[:message]).to include("App ID not configured")
      end
    end

    context "when private key is invalid" do
      before do
        allow(Github::AppConfig).to receive(:private_key).and_return("invalid_key_data")
      end

      it "returns failure" do
        result = described_class.call

        expect(result).to be_failure
        expect(result.failure[:code]).to eq(:jwt_generation_failed)
      end
    end

    context "clock drift handling" do
      it "generates JWT with iat in the past to handle clock drift" do
        result = described_class.call
        jwt = result.value!
        decoded = JWT.decode(jwt, test_private_key.public_key, true, { algorithm: "RS256" })

        # The iat (issued at) should be in the past by CLOCK_DRIFT_SECONDS
        expect(decoded[0]["iat"]).to be < Time.now.to_i
      end
    end
  end

  describe "constants" do
    it "uses RS256 algorithm" do
      expect(described_class::ALGORITHM).to eq("RS256")
    end

    it "sets 10 minute expiry" do
      expect(described_class::TOKEN_EXPIRY_SECONDS).to eq(600)
    end

    it "accounts for 60 second clock drift" do
      expect(described_class::CLOCK_DRIFT_SECONDS).to eq(60)
    end
  end
end
