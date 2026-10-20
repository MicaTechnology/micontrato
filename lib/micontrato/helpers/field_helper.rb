# frozen_string_literal: true

require_relative "spanish_ordinal"
require_relative "spanish_amount_in_words"

module Micontrato
  module Helpers
    # Resolves and formats the cover-field values of a contract document: dates, amounts in
    # words, Sí/No, protection and payment labels. The host apps include it too (the web
    # viewer's PopulateCoverFields), so screen and paper always print the same text.
    module FieldHelper
      include SpanishOrdinal

      MICA_RAZON_SOCIAL = "MCTC PLATAFORMA DE RENTAS, S.A.P.I. DE C.V."
      MICA_REPRESENTANTE_LEGAL = "JULIAN STASTNY"
      MICA_SIGNATURE_LABEL = '"MICA RENT"'

      GUARANTOR_ROLE_LABELS = {
        "bondsman" => "FIADOR",
        "joint_obligor" => "OBLIGADO SOLIDARIO",
        "aval" => "AVAL"
      }.freeze

      # Cover field `data_type` values the renderers understand. A `table` field is static:
      # its `rows` (array of [first column, second column] pairs) print as sub-rows that
      # share the label cell (e.g. the overdue-interest summary by day ranges).
      DATA_TYPE_BOOLEAN = "boolean"
      DATA_TYPE_DATE = "date"
      DATA_TYPE_CURRENCY = "currency"
      DATA_TYPE_TABLE = "table"

      TRUTHY_VALUES = [true, "true", "Sí", "Si", "sí", "si", "1", 1, "yes", "Yes"].freeze
      BOOLEAN_LABELS = { true => "Sí", false => "No" }.freeze

      PROTECTION_TYPE_LABELS = {
        "proteccion_juridica" => "Protección Jurídica",
        "proteccion_integral" => "Protección Integral",
        "proteccion_premium" => "Protección Premium"
      }.freeze

      # Only the stored enum keys are translated; a document-ready text (the payment
      # destination block, for instance) passes through untouched.
      PAYMENT_METHOD_LABELS = {
        "bank_transfer" => "Transferencia bancaria",
        "cash" => "Efectivo",
        "transferencia_bancaria" => "Transferencia bancaria",
        "efectivo" => "Efectivo"
      }.freeze

      MONTH_ABBREVIATIONS = %w[Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic].freeze

      # Label rules for templates that predate `data_type` (regexp sources, case-insensitive).
      DATE_LABEL_PATTERN = /INICIO DE LA VIGENCIA|FIN DE LA VIGENCIA|FECHA DE ENTREGA/i.freeze
      CURRENCY_LABEL_PATTERN = Regexp.new(
        ["PRECIO MENSUAL", "CUOTA DE MANTENIMIENTO", "RENTA MENSUAL INTEGRAL", "DEPÓSITO EN GARANTÍA",
         "RENTAS? ADELANTADAS?"].join("|"),
        Regexp::IGNORECASE
      ).freeze
      PROTECTION_LABEL_PATTERN = /SERVICIO DE PROTECCIÓN/i.freeze
      DURATION_LABEL_PATTERN = /DURACIÓN DEL ARRENDAMIENTO/i.freeze
      PAYMENT_METHOD_LABEL_PATTERN = /FORMA DE PAGO/i.freeze

      def guarantor_role_label(guarantor)
        GUARANTOR_ROLE_LABELS[guarantor&.guarantor_type] || "OBLIGADO SOLIDARIO"
      end

      # A static field prints its display_value; a dynamic one resolves it as a dotted method
      # path from mica_rent ("rent_landlord_detail.full_name", "contract_document_values.inventory").
      def evaluate_field_value(field, mica_rent)
        return field["display_value"] unless field["is_dynamic"]
        return "" unless field["display_value"].present?

        begin
          result = field["display_value"].split(".").reduce(mica_rent) do |object, method_name|
            object&.public_send(method_name)
          end
          format_field_value(result, field["label"], field["data_type"])
        rescue StandardError => e
          "[Error: #{e.message}]"
        end
      end

      # A row the template asks to drop when its value is blank (`hide_when_blank`, e.g.
      # rentas adelantadas when none were requested) hides like an `is_hidden` one.
      def field_hidden?(field, value)
        return true if field["is_hidden"]

        field["hide_when_blank"] && value.blank?
      end

      def table_field?(field)
        field["data_type"] == DATA_TYPE_TABLE
      end

      def table_rows(field)
        Array(field["rows"]).grep(Array).map { |row| row.map(&:to_s) }
      end

      # The explicit data_type wins; templates that predate it fall back to the label. A real
      # boolean prints Sí/No whatever the declared type (a copied template may lack it).
      def format_field_value(value, label, data_type = nil)
        return boolean_label(value) if data_type == DATA_TYPE_BOOLEAN || [true, false].include?(value)
        return "" if value.blank?

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

      def boolean_label(value)
        BOOLEAN_LABELS[TRUTHY_VALUES.include?(value)]
      end

      def format_date(value)
        return value.to_s unless value.respond_to?(:strftime)

        "#{value.day}/#{MONTH_ABBREVIATIONS[value.month - 1]}/#{value.year}"
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
