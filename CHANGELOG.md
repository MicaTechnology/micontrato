## [Unreleased]

## [1.1.0] - 2026-10-16

Parity of the inhouse contract document with the Google-Docs one:

- Cover values are formatted by `data_type` first (`boolean`, `date`, `currency`), falling back to the
  label-based rules templates without a `data_type` rely on. Booleans always print `Sí` / `No`
  (never `true`).
- Currency values print the amount in words: `$6,300 MXN (SEIS MIL TRESCIENTOS PESOS MEXICANOS)`
  (`Micontrato::Helpers::SpanishAmountInWords`). The label rule also covers `RENTAS ADELANTADAS`.
- `FORMA DE PAGO` no longer title-cases unknown values: a document-ready text (payment destination
  block with bank data) passes through, and cover values keep their line breaks (`white-space: pre-line`).
- Cover fields accept `hide_when_blank: true`: the row is dropped when its value is blank (e.g.
  rentas adelantadas when none were requested).
- Cover fields accept `data_type: "table"` with static `rows: [[first, second], ...]`: the rows share
  the label cell (the overdue-interest summary by day ranges).
- `HtmlGenerator.new(..., signature_participants:)` takes the resolved signers per role (`tenant`,
  `landlord`, `guarantor`, `client`, `mica`) with `name`, `email`, `phone`, `role`; the signature
  blocks print name, email and phone under each line, and a legal representative / attorney prints
  in place of the party they sign for. Without it the blocks fall back to the names read from the rent.

## [1.0.1]

- `spanish_ordinal` computed for any position up to 99.

## [1.0.0]

- Image cover elements.

## [0.1.0] - 2025-12-19

- Initial release
