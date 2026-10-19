# frozen_string_literal: true

require 'erb'
require_relative 'helpers/field_helper'

module Micontrato
  class HtmlGenerator
    include Helpers::FieldHelper

    # Roles of the signature blocks and the key each one reads from `signature_participants`.
    SIGNATURE_ROLES = %i[tenant landlord guarantor client mica].freeze

    # signature_participants: optional { role => { name:, email:, phone:, role:, title:, subtitle:, company: } }
    # (symbol or string keys) resolved by the host app — the e-signature signers, so a
    # legal representative or an attorney prints in place of the company they sign for and
    # the contact lines match the signatories. Without it the blocks fall back to the names
    # the rent exposes directly.
    def initialize(contract:, mica_rent: nil, show_admin_info: false, watermark_image: nil, signature_participants: nil)
      @contract = contract
      @mica_rent = mica_rent
      @show_admin_info = show_admin_info
      @watermark_image = watermark_image
      @signature_participants = normalize_participants(signature_participants)
      @cover_sections = contract.cover_sections
      all_clauses = contract.clauses.respond_to?(:reorder) ? contract.clauses.reorder(:position) : contract.clauses.sort_by(&:position)
      @header_clauses = all_clauses.select { |c| c.section == 'header' }
      @clauses = all_clauses.reject { |c| c.section == 'header' }
    end

    def generate
      template = File.read(template_path)
      ERB.new(template).result(binding)
    end

    private

    def clause_image_src(clause)
      if clause.clause_attachment.present?
        clause.clause_attachment.url
      elsif clause.text.present?
        clause.text
      end
    end

    def render_clauses(clauses)
      html = +'' # Mutable string needed because frozen_string_literal is enabled
      clauses.each do |clause|
        case clause.clause_type
        when 'image'
          image_src = clause_image_src(clause)
          if image_src.present?
            html << '<div style="display: table; width: 100%; height: 355.6mm; text-align: center;">'
            html << '<div style="display: table-cell; vertical-align: middle;">'
            html << "<img src=\"#{image_src}\" style=\"max-width: 100%; height: auto;\" />"
            html << '</div></div>'
          end
        when 'standard'
          html << '<div class="clause">'
          if clause.show_title && clause.title.present?
            html << "<p><strong>#{clause.title}</strong></p>"
          end
          html << clause.text.to_s if clause.text.present?
          html << '</div>'
        end
      end
      html
    end

    # The participant of a signature block: the one the host resolved, else the legacy
    # name read straight from the rent. Nil for a guarantor the rent does not have.
    def signature_participant(role)
      @signature_participants.fetch(role) { default_signature_participant(role) }
    end

    # Name, email and phone of a signer, blank lines dropped — what prints under the
    # signature line, like the Google-Docs contracts.
    def signature_participant_lines(participant)
      return [] if participant.nil?

      [participant[:name], participant[:email], participant[:phone]].map { |line| line.to_s.strip }.reject(&:empty?)
    end

    def default_signature_participant(role)
      case role
      when :tenant then { name: @mica_rent&.user&.full_name.to_s, role: 'ARRENDATARIO' }
      when :landlord then { name: @mica_rent&.landlord&.user_profile&.full_name.to_s, role: 'ARRENDADOR' }
      when :client then { name: @mica_rent&.landlord&.user_profile&.full_name.to_s }
      when :guarantor then default_guarantor_participant
      when :mica then { name: Helpers::FieldHelper::MICA_REPRESENTANTE_LEGAL, company: Helpers::FieldHelper::MICA_RAZON_SOCIAL }
      end
    end

    def default_guarantor_participant
      guarantor = @mica_rent&.rent_application&.guarantor
      return nil unless guarantor&.approved_at.present?

      { name: guarantor.full_name.to_s, role: guarantor_role_label(guarantor) }
    end

    def normalize_participants(participants)
      return {} if participants.nil?

      participants.each_with_object({}) do |(role, participant), normalized|
        next if participant.nil?

        normalized[role.to_sym] = participant.transform_keys(&:to_sym)
      end
    end

    def template_path
      File.join(__dir__, 'templates', 'contract.html.erb')
    end
  end
end
