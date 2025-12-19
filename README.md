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
