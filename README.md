# Micontrato

HTML and PDF contract generator for Mica rent contracts. This gem provides a reusable way to render contract templates with dynamic field evaluation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'micontrato', git: 'https://github.com/MicaTechnology/micontrato.git'
```

Or for local development:

```ruby
gem 'micontrato', path: '../micontrato'
```

And then execute:

```bash
$ bundle install
```

## Usage

### Generate HTML

```ruby
# In your controller or service
contract = MicaRent::Contract.find(id)
mica_rent = contract.mica_rent

generator = Micontrato::HtmlGenerator.new(
  contract: contract,
  mica_rent: mica_rent,
  show_admin_info: true  # Optional: shows admin indicators (editable, commentable, etc.)
)

html = generator.generate

# Render in Rails
render html: html.html_safe, layout: false
```

### Signature participants

The signature blocks print the people who actually sign (a legal representative signs for a persona
moral landlord, an attorney for a persona moral tenant) with their email and phone under the line.
Resolve them in the host app and pass them per role; a missing role falls back to the names read
from `mica_rent`:

```ruby
Micontrato::HtmlGenerator.new(
  contract: contract,
  mica_rent: mica_rent,
  signature_participants: {
    tenant: { name: 'Alberto Cecias', email: 'alberto@example.com', phone: '52 9995124291', role: 'ARRENDATARIO' },
    landlord: { name: 'Juan Carlos Villareal', email: 'juan@example.com', phone: '52 9995124291', role: 'ARRENDADOR' },
    guarantor: { name: 'Pedro Páramo', email: 'pedro@example.com', phone: '52 5512345678', role: 'OBLIGADO SOLIDARIO' }, # or nil
    client: { name: 'Juan Carlos Villareal', email: 'juan@example.com', phone: '52 9995124291', subtitle: 'POR SU PROPIO DERECHO' },
    mica: { name: 'Julian Stastny', company: 'MCTC PLATAFORMA DE RENTAS, S.A.P.I. DE C.V.' }
  }
).generate
```

### Cover field options

Each cover field hash may carry, besides `label`, `display_value`, `is_dynamic`, `is_editable` and
`is_hidden`:

- `data_type`: `text | email | tel | date | number | currency | boolean | template`. Formatting follows
  it (`currency` prints the amount in words, `boolean` prints `Sí` / `No`); templates without it fall
  back to label-based rules. Every value then prints in capitals, except an `email` (or any value
  that is an email address), which keeps its case.
- `hide_when_blank`: drop the row when the resolved value is blank.
- `display_format` (with `data_type: "template"`): free text with `{{ value }}` (the field's own display
  value) or `{{ a.dotted.path }}` tokens resolved from the rent, each with an optional `| formatter`
  (`currency`, `date`, `boolean`, `number`, `text`, `email`, `tel`, or `amount` / `words` for the two
  halves of a currency), e.g. `{{ value | amount }} más IVA ({{ value | words }})`. A template that
  names its own display value prints nothing while that value is blank; a wrong path or formatter
  prints `[Error: ...]`.

### Expected Contract Interface

The gem uses duck typing - your contract object should respond to:

```ruby
contract.name                # String
contract.for_joint_obligor   # Boolean
contract.created_at          # DateTime
contract.cover_sections      # Array of sections
contract.clauses             # Array/Relation of clauses

# Each section should respond to:
section.name
section.cover_fields         # Array of field hashes

# Each clause should respond to:
clause.id
clause.title
clause.text
clause.position
clause.show_title
clause.is_editable
clause.allow_comments
```

### Dynamic Field Evaluation

Fields with `is_dynamic: true` can reference deep associations:

```ruby
{
  'label' => 'NOMBRE DEL ARRENDADOR',
  'is_dynamic' => true,
  'display_value' => 'landlord.user_profile.full_name'  # Will call mica_rent.landlord.user_profile.full_name
}
```

Static fields just display the `display_value` as-is:

```ruby
{
  'label' => 'DOMICILIO',
  'is_dynamic' => false,
  'display_value' => 'Ciudad de México'
}
```

## Field Formatting

The gem automatically formats fields based on their label:

- **Dates**: "INICIO DE LA VIGENCIA", "FIN DE LA VIGENCIA" → `15/Ene/2024`
- **Currency**: "PRECIO MENSUAL", "DEPÓSITO EN GARANTÍA" → `$15,000.00 MXN`
- **Duration**: "DURACIÓN DEL ARRENDAMIENTO" → `12 Meses`
- **Payment Method**: Translates to Spanish
- **Protection Type**: Translates protection types

## Spanish Ordinals

Clauses are numbered with Spanish ordinals (PRIMERA, SEGUNDA, TERCERA, etc.) up to 60.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

This is a private gem for Mica Technology. Contact the maintainers for contribution guidelines.

## License

Proprietary - Mica Technology
