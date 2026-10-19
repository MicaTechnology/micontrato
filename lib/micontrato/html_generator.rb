# frozen_string_literal: true

require "erb"
require_relative "helpers/field_helper"

module Micontrato
  # Renders a contract (template or generated contract) as the HTML the PDF and the Pandora
  # previews are built from: header elements, cover sections and clauses.
  class HtmlGenerator
    include Helpers::FieldHelper

    # Each signature role and the method that builds its fallback participant when the host
    # passed none: the names read straight from the rent, as the blocks always printed.
    DEFAULT_PARTICIPANT_BUILDERS = {
      tenant: :default_tenant_participant,
      landlord: :default_landlord_participant,
      guarantor: :default_guarantor_participant,
      client: :default_client_participant,
      mica: :default_mica_participant
    }.freeze

    HEADER_SECTION = "header"

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
      @header_clauses, @clauses = partition_clauses(contract.clauses)
    end

    def generate
      template = File.read(template_path)
      ERB.new(template).result(binding)
    end

    private

    # Header elements first, body clauses after, both in position order.
    def partition_clauses(clauses)
      ordered = clauses.respond_to?(:reorder) ? clauses.reorder(:position) : clauses.sort_by(&:position)
      ordered.partition { |clause| clause.section == HEADER_SECTION }
    end

    def clause_image_src(clause)
      if clause.clause_attachment.present?
        clause.clause_attachment.url
      elsif clause.text.present?
        clause.text
      end
    end

    def render_clauses(clauses)
      clauses.map { |clause| render_header_clause(clause) }.join
    end

    def render_header_clause(clause)
      case clause.clause_type
      when "image" then render_image_clause(clause)
      when "standard" then render_standard_clause(clause)
      else ""
      end
    end

    def render_image_clause(clause)
      image_src = clause_image_src(clause)
      return "" unless image_src.present?

      '<div style="display: table; width: 100%; height: 355.6mm; text-align: center;">' \
        '<div style="display: table-cell; vertical-align: middle;">' \
        "<img src=\"#{image_src}\" style=\"max-width: 100%; height: auto;\" />" \
        "</div></div>"
    end

    def render_standard_clause(clause)
      title = clause.show_title && clause.title.present? ? "<p><strong>#{clause.title}</strong></p>" : ""
      "<div class=\"clause\">#{title}#{clause.text}</div>"
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
      builder = DEFAULT_PARTICIPANT_BUILDERS[role]
      builder && send(builder)
    end

    def default_tenant_participant
      { name: @mica_rent&.user&.full_name.to_s, role: "ARRENDATARIO" }
    end

    def default_landlord_participant
      { name: legacy_landlord_name, role: "ARRENDADOR" }
    end

    def default_client_participant
      { name: legacy_landlord_name }
    end

    def default_mica_participant
      { name: Helpers::FieldHelper::MICA_REPRESENTANTE_LEGAL, company: Helpers::FieldHelper::MICA_RAZON_SOCIAL }
    end

    def default_guarantor_participant
      guarantor = @mica_rent&.rent_application&.guarantor
      return nil unless guarantor&.approved_at.present?

      { name: guarantor.full_name.to_s, role: guarantor_role_label(guarantor) }
    end

    def legacy_landlord_name
      landlord_profile = @mica_rent&.landlord&.user_profile
      landlord_profile&.full_name.to_s
    end

    def normalize_participants(participants)
      return {} if participants.nil?

      participants.each_with_object({}) do |(role, participant), normalized|
        next if participant.nil?

        normalized[role.to_sym] = participant.transform_keys(&:to_sym)
      end
    end

    def template_path
      File.join(__dir__, "templates", "contract.html.erb")
    end
  end
end
