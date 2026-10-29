# frozen_string_literal: true

module Micontrato
  module Helpers
    # Every cover value prints in capitals, as the Google-Docs contracts do (their payload
    # upcases everything but the emails); an email address keeps its case. Ruby upcases the
    # accented letters too.
    module DocumentText
      EMAIL_PATTERN = /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/.freeze

      def document_text(text)
        text = text.to_s
        EMAIL_PATTERN.match?(text) ? text : text.upcase
      end
    end
  end
end
