# frozen_string_literal: true

module Rack
  class Attack
    class Cache
      class ExpirableKeyGenerator < KeyGenerator
        attr_reader :current_time

        def initialize(name, discriminator, period)
          super(name, discriminator)
          @period = period
          @current_time = Time.now.to_i
        end

        def expires_in
          # Add 1 to expires_in to avoid timing error: https://github.com/rack/rack-attack/pull/85
          @expires_in ||= (period - elapsed + 1).to_i
        end

        private

        attr_reader :period

        def unprefixed_key
          [time_window, super]
        end

        def time_window
          (current_time / period).to_i
        end

        def elapsed
          current_time % period
        end
      end
    end
  end
end
