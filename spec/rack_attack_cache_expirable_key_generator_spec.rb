# frozen_string_literal: true

require_relative 'spec_helper'
require_relative 'support/freeze_time_helper'

describe Rack::Attack::Cache::ExpirableKeyGenerator do
  describe '#key' do
    it 'forms the key by joining the parts' do
      within_same_period do
        period = 50
        time_window = (Time.now.to_i / period).to_i
        key_generator = Rack::Attack::Cache::ExpirableKeyGenerator.new('name', 'discriminator', period)
        assert_equal key_generator.key, "rack::attack:#{time_window}:name:discriminator"
      end
    end
  end

  describe '#expires_in' do
    it 'returns the expiration' do
      within_same_period do
        period = 50
        key_generator = Rack::Attack::Cache::ExpirableKeyGenerator.new('name', 'discriminator', period)
        assert_equal key_generator.expires_in, period - (Time.now.to_i % period) + 1
      end
    end
  end

  describe '#current_time' do
    it 'returns the frozen time' do
      within_same_period do
        expected_time = Time.now.to_i
        key_generator = Rack::Attack::Cache::ExpirableKeyGenerator.new('name', 'discriminator', 50)
        Timecop.travel(60)
        assert_equal Time.now.to_i, expected_time + 60
        assert_equal key_generator.current_time, expected_time
      end
    end
  end
end
