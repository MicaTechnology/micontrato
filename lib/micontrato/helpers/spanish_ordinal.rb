# frozen_string_literal: true

module Micontrato
  module Helpers
    # Feminine Spanish ordinals for clause titles ("PRIMERA.- OBJETO"), any position up to 99.
    module SpanishOrdinal
      UNITS = {
        1 => "PRIMERA", 2 => "SEGUNDA", 3 => "TERCERA", 4 => "CUARTA", 5 => "QUINTA",
        6 => "SEXTA", 7 => "SÉPTIMA", 8 => "OCTAVA", 9 => "NOVENA"
      }.freeze

      TEENS = {
        11 => "UNDÉCIMA", 12 => "DUODÉCIMA", 13 => "DECIMOTERCERA", 14 => "DECIMOCUARTA",
        15 => "DECIMOQUINTA", 16 => "DECIMOSEXTA", 17 => "DECIMOSÉPTIMA", 18 => "DECIMOCTAVA",
        19 => "DECIMONOVENA"
      }.freeze

      TENS = {
        10 => "DÉCIMA", 20 => "VIGÉSIMA", 30 => "TRIGÉSIMA", 40 => "CUADRAGÉSIMA",
        50 => "QUINCUAGÉSIMA", 60 => "SEXAGÉSIMA", 70 => "SEPTUAGÉSIMA",
        80 => "OCTOGÉSIMA", 90 => "NONAGÉSIMA"
      }.freeze

      def spanish_ordinal(position)
        return "CLÁUSULA #{position}" unless position.is_a?(Integer) && position.between?(1, 99)
        return UNITS[position] if position <= 9
        return TEENS[position] if position.between?(11, 19)

        tens_part = (position / 10) * 10
        unit_part = position % 10

        return TENS[tens_part] if unit_part.zero?

        "#{TENS[tens_part]} #{UNITS[unit_part]}"
      end
    end
  end
end
