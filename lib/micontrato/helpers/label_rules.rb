# frozen_string_literal: true

module Micontrato
  module Helpers
    # Formatting rules for templates that predate `data_type`: the label says what the value
    # is. Mixed into FieldHelper, which provides the formatters each rule calls.
    module LabelRules
      DATE_LABEL_PATTERN = /INICIO DE LA VIGENCIA|FIN DE LA VIGENCIA|FECHA DE ENTREGA/i.freeze
      CURRENCY_LABEL_PATTERN = Regexp.new(
        ["PRECIO MENSUAL", "CUOTA DE MANTENIMIENTO", "RENTA MENSUAL INTEGRAL", "DEPÓSITO EN GARANTÍA",
         "RENTAS? ADELANTADAS?"].join("|"),
        Regexp::IGNORECASE
      ).freeze
      PROTECTION_LABEL_PATTERN = /SERVICIO DE PROTECCIÓN/i.freeze
      DURATION_LABEL_PATTERN = /DURACIÓN DEL ARRENDAMIENTO/i.freeze
      PAYMENT_METHOD_LABEL_PATTERN = /FORMA DE PAGO/i.freeze

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
    end
  end
end
