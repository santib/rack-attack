# frozen_string_literal: true

require_relative 'spec_helper'

describe Rack::Attack::Cache::KeyGenerator do
  it 'defines the PREFIX for all keys' do
    assert_equal Rack::Attack::Cache::KeyGenerator::PREFIX, 'rack::attack'
  end

  describe '#key' do
    it 'forms the key by joining the parts' do
      key_generator = Rack::Attack::Cache::KeyGenerator.new('name', 'discriminator')
      assert_equal key_generator.key, 'rack::attack:name:discriminator'
    end
  end
end
