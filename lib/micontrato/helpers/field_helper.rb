# frozen_string_literal: true

require_relative 'spanish_amount_in_words'

module Micontrato
  module Helpers
    module FieldHelper
      UNITS = {
        1 => 'PRIMERA', 2 => 'SEGUNDA', 3 => 'TERCERA', 4 => 'CUARTA', 5 => 'QUINTA',
        6 => 'SEXTA', 7 => 'SÉPTIMA', 8 => 'OCTAVA', 9 => 'NOVENA'
      }.freeze

      TEENS = {
        11 => 'UNDÉCIMA', 12 => 'DUODÉCIMA', 13 => 'DECIMOTERCERA', 14 => 'DECIMOCUARTA',
        15 => 'DECIMOQUINTA', 16 => 'DECIMOSEXTA', 17 => 'DECIMOSÉPTIMA', 18 => 'DECIMOCTAVA',
        19 => 'DECIMONOVENA'
      }.freeze

      TENS = {
        10 => 'DÉCIMA', 20 => 'VIGÉSIMA', 30 => 'TRIGÉSIMA', 40 => 'CUADRAGÉSIMA',
        50 => 'QUINCUAGÉSIMA', 60 => 'SEXAGÉSIMA', 70 => 'SEPTUAGÉSIMA',
        80 => 'OCTOGÉSIMA', 90 => 'NONAGÉSIMA'
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

      MICA_RAZON_SOCIAL = 'MCTC PLATAFORMA DE RENTAS, S.A.P.I. DE C.V.'.freeze
      MICA_REPRESENTANTE_LEGAL = 'JULIAN STASTNY'.freeze
      MICA_SIGNATURE_LABEL = '"MICA RENT"'.freeze

      GUARANTOR_ROLE_LABELS = {
        'bondsman' => 'FIADOR',
        'joint_obligor' => 'OBLIGADO SOLIDARIO',
        'aval' => 'AVAL'
      }.freeze

      # Cover field `data_type` values the renderers understand. A `table` field is static:
      # its `rows` (array of [first column, second column] pairs) print as sub-rows that
      # share the label cell (e.g. the overdue-interest summary by day ranges).
      DATA_TYPE_BOOLEAN = 'boolean'
      DATA_TYPE_DATE = 'date'
      DATA_TYPE_CURRENCY = 'currency'
      DATA_TYPE_TABLE = 'table'

      TRUTHY_VALUES = [true, 'true', 'Sí', 'Si', 'sí', 'si', '1', 1, 'yes', 'Yes'].freeze
      BOOLEAN_LABELS = { true => 'Sí', false => 'No' }.freeze

      PROTECTION_TYPE_LABELS = {
        'proteccion_juridica' => 'Protección Jurídica',
        'proteccion_integral' => 'Protección Integral',
        'proteccion_premium' => 'Protección Premium'
      }.freeze

      # Only the stored enum keys are translated; a document-ready text (the payment
      # destination block, for instance) passes through untouched.
      PAYMENT_METHOD_LABELS = {
        'bank_transfer' => 'Transferencia bancaria',
        'cash' => 'Efectivo',
        'transferencia_bancaria' => 'Transferencia bancaria',
        'efectivo' => 'Efectivo'
      }.freeze

      DATE_LABEL_PATTERN = /INICIO DE LA VIGENCIA|FIN DE LA VIGENCIA|FECHA DE ENTREGA/i
      CURRENCY_LABEL_PATTERN = /PRECIO MENSUAL|CUOTA DE MANTENIMIENTO|RENTA MENSUAL INTEGRAL|DEPÓSITO EN GARANTÍA|RENTAS? ADELANTADAS?/i
      PROTECTION_LABEL_PATTERN = /SERVICIO DE PROTECCIÓN/i
      DURATION_LABEL_PATTERN = /DURACIÓN DEL ARRENDAMIENTO/i
      PAYMENT_METHOD_LABEL_PATTERN = /FORMA DE PAGO/i

      def guarantor_role_label(guarantor)
        GUARANTOR_ROLE_LABELS[guarantor&.guarantor_type] || 'OBLIGADO SOLIDARIO'
      end

      def evaluate_field_value(field, mica_rent)
        # If not a dynamic field, just return the display_value as is (static text)
        return field['display_value'] unless field['is_dynamic']

        # If dynamic field but no display_value, return empty string
        return '' unless field['display_value'].present?

        begin
          # When is_dynamic is true, display_value contains the method path
          # This handles deep associations like "landlord.user_profile.full_name" or "rent_application.user.full_name"
          # Starting from mica_rent
          result = field['display_value'].split('.').reduce(mica_rent) do |obj, method_name|
            obj&.public_send(method_name)
          end

          format_field_value(result, field['label'], field['data_type'])
        rescue StandardError => e
          "[Error: #{e.message}]"
        end
      end

      # A row the template asks to drop when its value is blank (`hide_when_blank`, e.g.
      # rentas adelantadas when none were requested) hides like an `is_hidden` one.
      def field_hidden?(field, value)
        return true if field['is_hidden']

        field['hide_when_blank'] && value.blank?
      end

      def table_field?(field)
        field['data_type'] == DATA_TYPE_TABLE
      end

      def table_rows(field)
        Array(field['rows']).select { |row| row.is_a?(Array) }.map { |row| row.map(&:to_s) }
      end

      # The explicit data_type wins; templates that predate it fall back to the label.
      def format_field_value(value, label, data_type = nil)
        return boolean_label(value) if data_type == DATA_TYPE_BOOLEAN || boolean_value?(value)
        return '' if value.blank?

        case data_type
        when DATA_TYPE_DATE then format_date(value)
        when DATA_TYPE_CURRENCY then format_currency(value)
        else format_by_label(value, label)
        end
      end

      def format_by_label(value, label)
        case label
        when DATE_LABEL_PATTERN then format_date(value)
        when CURRENCY_LABEL_PATTERN then format_currency(value)
        when PROTECTION_LABEL_PATTERN then format_protection_type(value)
        when DURATION_LABEL_PATTERN then format_duration(value)
        when PAYMENT_METHOD_LABEL_PATTERN then format_payment_method(value)
        else value.to_s
        end
      end

      def boolean_value?(value)
        value == true || value == false
      end

      def boolean_label(value)
        BOOLEAN_LABELS[TRUTHY_VALUES.include?(value)]
      end

      def format_date(value)
        return value.to_s unless value.respond_to?(:strftime)

        month_names = {
          1 => 'Ene', 2 => 'Feb', 3 => 'Mar', 4 => 'Abr', 5 => 'May', 6 => 'Jun',
          7 => 'Jul', 8 => 'Ago', 9 => 'Sep', 10 => 'Oct', 11 => 'Nov', 12 => 'Dic'
        }

        "#{value.day}/#{month_names[value.month]}/#{value.year}"
      end

      # "$6,300 MXN (SEIS MIL TRESCIENTOS PESOS MEXICANOS)" — the amount in words is what
      # the Google-Docs contracts print, so the inhouse ones read the same.
      def format_currency(value)
        SpanishAmountInWords.money(value) || value.to_s
      end

      def format_protection_type(value)
        PROTECTION_TYPE_LABELS[value.to_s] || value.to_s.titleize
      end

      def format_duration(value)
        return value.to_s unless value.to_s.match?(/^\d+$/)

        "#{value} Meses"
      end

      def format_payment_method(value)
        PAYMENT_METHOD_LABELS[value.to_s] || value.to_s
      end
    end
  end
end
