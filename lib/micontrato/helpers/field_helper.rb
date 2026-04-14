# frozen_string_literal: true

module Micontrato
  module Helpers
    module FieldHelper
      def spanish_ordinal(position)
        ordinals = {
          1 => 'PRIMERA', 2 => 'SEGUNDA', 3 => 'TERCERA', 4 => 'CUARTA', 5 => 'QUINTA',
          6 => 'SEXTA', 7 => 'SÉPTIMA', 8 => 'OCTAVA', 9 => 'NOVENA', 10 => 'DÉCIMA',
          11 => 'UNDÉCIMA', 12 => 'DUODÉCIMA', 13 => 'DECIMOTERCERA', 14 => 'DECIMOCUARTA',
          15 => 'DECIMOQUINTA', 16 => 'DECIMOSEXTA', 17 => 'DECIMOSÉPTIMA', 18 => 'DECIMOCTAVA',
          19 => 'DECIMONOVENA', 20 => 'VIGÉSIMA', 21 => 'VIGÉSIMA PRIMERA', 22 => 'VIGÉSIMA SEGUNDA',
          23 => 'VIGÉSIMA TERCERA', 24 => 'VIGÉSIMA CUARTA', 25 => 'VIGÉSIMA QUINTA',
          26 => 'VIGÉSIMA SEXTA', 27 => 'VIGÉSIMA SÉPTIMA', 28 => 'VIGÉSIMA OCTAVA',
          29 => 'VIGÉSIMA NOVENA', 30 => 'TRIGÉSIMA', 31 => 'TRIGÉSIMA PRIMERA',
          32 => 'TRIGÉSIMA SEGUNDA', 33 => 'TRIGÉSIMA TERCERA', 34 => 'TRIGÉSIMA CUARTA',
          35 => 'TRIGÉSIMA QUINTA', 36 => 'TRIGÉSIMA SEXTA', 37 => 'TRIGÉSIMA SÉPTIMA',
          38 => 'TRIGÉSIMA OCTAVA', 39 => 'TRIGÉSIMA NOVENA', 40 => 'CUADRAGÉSIMA',
          41 => 'CUADRAGÉSIMA PRIMERA', 42 => 'CUADRAGÉSIMA SEGUNDA', 43 => 'CUADRAGÉSIMA TERCERA',
          44 => 'CUADRAGÉSIMA CUARTA', 45 => 'CUADRAGÉSIMA QUINTA', 46 => 'CUADRAGÉSIMA SEXTA',
          47 => 'CUADRAGÉSIMA SÉPTIMA', 48 => 'CUADRAGÉSIMA OCTAVA', 49 => 'CUADRAGÉSIMA NOVENA',
          50 => 'QUINCUAGÉSIMA', 51 => 'QUINCUAGÉSIMA PRIMERA', 52 => 'QUINCUAGÉSIMA SEGUNDA',
          53 => 'QUINCUAGÉSIMA TERCERA', 54 => 'QUINCUAGÉSIMA CUARTA', 55 => 'QUINCUAGÉSIMA QUINTA',
          56 => 'QUINCUAGÉSIMA SEXTA', 57 => 'QUINCUAGÉSIMA SÉPTIMA', 58 => 'QUINCUAGÉSIMA OCTAVA',
          59 => 'QUINCUAGÉSIMA NOVENA', 60 => 'SEXAGÉSIMA'
        }
        ordinals[position] || "CLÁUSULA #{position}"
      end

      MICA_RAZON_SOCIAL = 'MCTC PLATAFORMA DE RENTAS, S.A.P.I. DE C.V.'.freeze
      MICA_REPRESENTANTE_LEGAL = 'JULIAN STASTNY'.freeze
      MICA_SIGNATURE_LABEL = '"MICA RENT"'.freeze

      GUARANTOR_ROLE_LABELS = {
        'bondsman' => 'FIADOR',
        'joint_obligor' => 'OBLIGADO SOLIDARIO',
        'aval' => 'AVAL'
      }.freeze

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

          # Format the result based on field type
          format_field_value(result, field['label'])
        rescue StandardError => e
          "[Error: #{e.message}]"
        end
      end

      def format_field_value(value, label)
        return '' if value.blank?

        case label
        # Date fields
        when /INICIO DE LA VIGENCIA|FIN DE LA VIGENCIA|FECHA DE ENTREGA/i
          format_date(value)
        # Currency fields
        when /PRECIO MENSUAL|CUOTA DE MANTENIMIENTO|RENTA MENSUAL INTEGRAL|DEPÓSITO EN GARANTÍA/i
          format_currency(value)
        # Protection service
        when /SERVICIO DE PROTECCIÓN/i
          format_protection_type(value)
        # Duration
        when /DURACIÓN DEL ARRENDAMIENTO/i
          format_duration(value)
        # Payment method
        when /FORMA DE PAGO/i
          format_payment_method(value)
        else
          value.to_s
        end
      end

      def format_date(value)
        return value.to_s unless value.respond_to?(:strftime)

        month_names = {
          1 => 'Ene', 2 => 'Feb', 3 => 'Mar', 4 => 'Abr', 5 => 'May', 6 => 'Jun',
          7 => 'Jul', 8 => 'Ago', 9 => 'Sep', 10 => 'Oct', 11 => 'Nov', 12 => 'Dic'
        }

        "#{value.day}/#{month_names[value.month]}/#{value.year}"
      end

      def format_currency(value)
        return value.to_s unless value.is_a?(Numeric) || value.to_s.match?(/^\d+\.?\d*$/)

        amount = value.to_f
        "$#{number_with_precision(amount, precision: 2, delimiter: ',')} MXN"
      end

      def format_protection_type(value)
        protection_types = {
          'proteccion_juridica' => 'Protección Jurídica',
          'proteccion_integral' => 'Protección Integral',
          'proteccion_premium' => 'Protección Premium'
        }

        protection_types[value.to_s] || value.to_s.titleize
      end

      def format_duration(value)
        return value.to_s unless value.to_s.match?(/^\d+$/)

        "#{value} Meses"
      end

      def format_payment_method(value)
        payment_methods = {
          'bank_transfer' => 'Transferencia bancaria',
          'cash' => 'Efectivo',
          'transferencia_bancaria' => 'Transferencia bancaria',
          'efectivo' => 'Efectivo'
        }

        payment_methods[value.to_s] || value.to_s.titleize
      end

      private

      def number_with_precision(number, options = {})
        precision = options[:precision] || 2
        delimiter = options[:delimiter] || ','

        formatted = format("%.#{precision}f", number)
        parts = formatted.split('.')
        parts[0].gsub!(/(\d)(?=(\d{3})+(?!\d))/, "\\1#{delimiter}")
        parts.join('.')
      end
    end
  end
end
