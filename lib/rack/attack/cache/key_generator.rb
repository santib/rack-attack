# frozen_string_literal: true

module Rack
  class Attack
    class Cache
      class KeyGenerator
        PREFIX = 'rack::attack'

        def initialize(name, discriminator)
          @name = name
          @discriminator = discriminator
        end

        def key
          @key ||= [PREFIX, unprefixed_key].join(':')
        end

        private

        attr_reader :name, :discriminator

        def unprefixed_key
          [name, discriminator]
        end
      end
    end
  end
end
