# frozen_string_literal: true

module Micontrato
  module Helpers
    # A `template` cover field prints its `display_format` with every `{{ }}` token replaced:
    # `{{ value }}` is the field's own display value, any other token a dotted path resolved
    # from the rent exactly like a display value. A `| formatter` applies one of the
    # data_type formatters (currency, date, boolean, number, text, email, tel) or one half of
    # a currency: `amount` ("$6,300 MXN") or `words` ("SEIS MIL TRESCIENTOS PESOS MEXICANOS").
    # The static text prints in capitals like every value. A template that names its own
    # display value prints nothing while that value is blank, so `hide_when_blank` works on
    # it as on any other field; a wrong path or formatter prints "[Error: ...]". Mixed into
    # FieldHelper, which provides the formatters and the path resolver.
    module DisplayTemplate
      DISPLAY_FORMAT = "display_format"
      SELF_TOKEN = "value"
      TOKEN_PATTERN = /\{\{\s*([a-z][a-z0-9_.]*)\s*(?:\|\s*([a-z_]+)\s*)?\}\}/.freeze
      FORMATTER_AMOUNT = "amount"
      FORMATTER_WORDS = "words"
      TOKEN_FORMATTERS = %w[text email tel date number currency boolean amount words].freeze

      def template_field?(field)
        field["data_type"] == DATA_TYPE_TEMPLATE
      end

      def render_display_template(field, mica_rent)
        own_path = field["display_value"].to_s.strip
        own_value = own_path.empty? ? nil : resolve_display_path(mica_rent, own_path)
        return "" if !own_path.empty? && blank_template_value?(own_value)

        interpolate_display_format(field, mica_rent, own_value)
      rescue StandardError => e
        "[Error: #{e.message}]"
      end

      private

      def interpolate_display_format(field, mica_rent, own_value)
        rendered = +""
        remainder = field[DISPLAY_FORMAT].to_s
        while (match = TOKEN_PATTERN.match(remainder))
          rendered << document_text(match.pre_match)
          rendered << render_display_token(field, mica_rent, own_value, match[1], match[2])
          remainder = match.post_match
        end
        rendered << document_text(remainder)
      end

      def render_display_token(field, mica_rent, own_value, path, formatter)
        raise ArgumentError, "unknown formatter '#{formatter}'" if formatter && !TOKEN_FORMATTERS.include?(formatter)

        own_token = path == SELF_TOKEN
        value = own_token ? own_value : resolve_display_path(mica_rent, path)
        format_display_token(value, own_token ? field["label"] : nil, formatter)
      end

      def format_display_token(value, label, formatter)
        case formatter
        when FORMATTER_AMOUNT then document_text(SpanishAmountInWords.money_amount(value) || value.to_s)
        when FORMATTER_WORDS then document_text(SpanishAmountInWords.money_words(value) || value.to_s)
        else format_field_value(value, label, formatter)
        end
      end

      # `false` is a printable answer (Sí / No), not a missing one.
      def blank_template_value?(value)
        value != false && value.blank?
      end
    end
  end
end
