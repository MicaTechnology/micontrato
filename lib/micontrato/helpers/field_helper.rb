# frozen_string_literal: true

require_relative "spanish_ordinal"
require_relative "spanish_amount_in_words"
require_relative "document_text"
require_relative "label_rules"
require_relative "display_template"

module Micontrato
  module Helpers
    # Resolves and formats the cover-field values of a contract document: dates, amounts in
    # words, Sí/No, protection and payment labels. The host apps include it too (the web
    # viewer's PopulateCoverFields), so screen and paper always print the same text.
    module FieldHelper
      include SpanishOrdinal
      include DocumentText
      include LabelRules
      include DisplayTemplate

      MICA_RAZON_SOCIAL = "MCTC PLATAFORMA DE RENTAS, S.A.P.I. DE C.V."
      MICA_REPRESENTANTE_LEGAL = "JULIAN STASTNY"
      MICA_SIGNATURE_LABEL = '"MICA RENT"'

      GUARANTOR_ROLE_LABELS = {
        "bondsman" => "FIADOR",
        "joint_obligor" => "OBLIGADO SOLIDARIO",
        "aval" => "AVAL"
      }.freeze

      # Cover field `data_type` values, the display formatter of a row. A `template` field
      # prints its `display_format` with the `{{ }}` tokens resolved (DisplayTemplate).
      DATA_TYPE_BOOLEAN = "boolean"
      DATA_TYPE_DATE = "date"
      DATA_TYPE_CURRENCY = "currency"
      DATA_TYPE_EMAIL = "email"
      DATA_TYPE_TEMPLATE = DisplayTemplate::DATA_TYPE_TEMPLATE

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

      def guarantor_role_label(guarantor)
        GUARANTOR_ROLE_LABELS[guarantor&.guarantor_type] || "OBLIGADO SOLIDARIO"
      end

      # A static field prints its display_value; a dynamic one resolves it as a dotted method
      # path from mica_rent ("rent_landlord_detail.full_name", "contract_document_values.inventory");
      # a template field prints its display_format with every token resolved the same way.
      def evaluate_field_value(field, mica_rent)
        return render_display_template(field, mica_rent) if template_field?(field)
        return document_text(field["display_value"]) unless field["is_dynamic"]
        return "" unless field["display_value"].present?

        begin
          value = resolve_display_path(mica_rent, field["display_value"])
          format_field_value(value, field["label"], field["data_type"])
        rescue StandardError => e
          "[Error: #{e.message}]"
        end
      end

      def resolve_display_path(mica_rent, path)
        path.to_s.split(".").reduce(mica_rent) do |object, method_name|
          object&.public_send(method_name)
        end
      end

      # A row the template asks to drop when its value is blank (`hide_when_blank`, e.g.
      # rentas adelantadas when none were requested) hides like an `is_hidden` one.
      def field_hidden?(field, value)
        return true if field["is_hidden"]

        field["hide_when_blank"] && value.blank?
      end

      # The explicit data_type wins; templates that predate it fall back to the label
      # (LabelRules). A real boolean prints Sí/No whatever the declared type (a copied template
      # may lack it). The text then goes in capitals (DocumentText), except an email.
      def format_field_value(value, label, data_type = nil)
        text = format_typed_value(value, label, data_type)
        return text if data_type == DATA_TYPE_EMAIL

        document_text(text)
      end

      def format_typed_value(value, label, data_type)
        return boolean_label(value) if data_type == DATA_TYPE_BOOLEAN || [true, false].include?(value)
        return "" if value.blank?

        case data_type
        when DATA_TYPE_DATE then format_date(value)
        when DATA_TYPE_CURRENCY then format_currency(value)
        else format_by_label(value, label)
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
