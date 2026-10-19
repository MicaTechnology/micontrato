# frozen_string_literal: true

module Micontrato
  module Helpers
    # Spells a MXN amount the way the contract documents print it:
    # "$6,300 MXN (SEIS MIL TRESCIENTOS PESOS MEXICANOS)", cents appended as
    # "CON 50/100" only when present. Mirrors the Google Apps Script `money()` helper so
    # inhouse and Google-Docs contracts read the same.
    module SpanishAmountInWords
      UNITS = %w[CERO UN DOS TRES CUATRO CINCO SEIS SIETE OCHO NUEVE].freeze
      TEENS = %w[DIEZ ONCE DOCE TRECE CATORCE QUINCE DIECISÉIS DIECISIETE DIECIOCHO DIECINUEVE].freeze
      TWENTIES = %w[VEINTE VEINTIÚN VEINTIDÓS VEINTITRÉS VEINTICUATRO VEINTICINCO VEINTISÉIS VEINTISIETE VEINTIOCHO VEINTINUEVE].freeze
      TENS = [nil, nil, 'VEINTE', 'TREINTA', 'CUARENTA', 'CINCUENTA', 'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA'].freeze
      HUNDREDS = [nil, 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'].freeze

      CURRENCY_SINGULAR = 'PESO MEXICANO'
      CURRENCY_PLURAL = 'PESOS MEXICANOS'
      NUMERIC_PATTERN = /\A-?\d+(\.\d+)?\z/

      module_function

      # Accepts a Numeric or a numeric-looking string ("6300", "6,300.00", "$6,300").
      # Returns nil for anything else so callers can fall back to the raw value.
      def money(amount)
        number = to_number(amount)
        return nil if number.nil?

        integer_part = number.abs.floor
        cents = ((number.abs - integer_part) * 100).round
        if cents == 100
          integer_part += 1
          cents = 0
        end

        formatted = "#{number.negative? ? '-' : ''}$#{with_thousands_delimiter(integer_part)}"
        formatted += ".#{format('%02d', cents)}" if cents.positive?

        words = "#{integer_words(integer_part)}#{whole_millions?(integer_part) ? ' DE ' : ' '}#{currency_noun(integer_part)}"
        words += " CON #{format('%02d', cents)}/100" if cents.positive?

        "#{formatted} MXN (#{words})"
      end

      # Whole number in Spanish, upper case, with the apocope every amount needs because a
      # noun always follows (UN MIL, VEINTIÚN PESOS).
      def integer_words(number)
        number = number.to_i
        return UNITS[0] if number.zero?

        millions, remainder = number.divmod(1_000_000)
        thousands, units = remainder.divmod(1_000)

        parts = []
        parts << (millions == 1 ? 'UN MILLÓN' : "#{below_thousand(millions)} MILLONES") if millions.positive?
        parts << (thousands == 1 ? 'MIL' : "#{below_thousand(thousands)} MIL") if thousands.positive?
        parts << below_thousand(units) if units.positive?
        parts.join(' ')
      end

      def below_thousand(number)
        return 'CIEN' if number == 100

        hundreds, remainder = number.divmod(100)
        parts = []
        parts << HUNDREDS[hundreds] if hundreds.positive?
        parts << below_hundred(remainder) if remainder.positive?
        parts.join(' ')
      end

      def below_hundred(number)
        return UNITS[number] if number < 10
        return TEENS[number - 10] if number < 20
        return TWENTIES[number - 20] if number < 30

        tens, units = number.divmod(10)
        units.zero? ? TENS[tens] : "#{TENS[tens]} Y #{UNITS[units]}"
      end

      def currency_noun(integer_part)
        integer_part == 1 ? CURRENCY_SINGULAR : CURRENCY_PLURAL
      end

      # "UN MILLÓN DE PESOS", but "UN MILLÓN QUINIENTOS MIL PESOS".
      def whole_millions?(integer_part)
        integer_part >= 1_000_000 && (integer_part % 1_000_000).zero?
      end

      def to_number(amount)
        return amount if amount.is_a?(Numeric)

        normalized = amount.to_s.gsub(/[^\d.\-]/, '')
        return nil unless NUMERIC_PATTERN.match?(normalized)

        normalized.include?('.') ? normalized.to_f : normalized.to_i
      end

      def with_thousands_delimiter(integer)
        integer.to_s.gsub(/(\d)(?=(\d{3})+\z)/, '\1,')
      end
    end
  end
end
