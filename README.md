# Effective Mergery

Merge any two Active Record objects, along with all associated objects, into one record.

## Getting Started

Add to your Gemfile:

```ruby
gem 'effective_mergery'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_mergery:install
```

The generator will install an initializer which describes all configuration options.

Require the javascript on the asset pipeline by adding the following to your application.js:

```ruby
//= require effective_mergery
```

Require the stylesheet on the asset pipeline by adding the following to your application.css:

```ruby
*= require effective_mergery
```

## Usage

Visit `/admin/merge` and select an object type to merge.

```ruby
link_to 'Merge', effective_mergery.admin_merge_index_path
link_to 'Merge: User', effective_mergery.new_admin_merge_path(type: 'User')
```

## Permissions

Add the following permissions (using CanCan):

```ruby
can :admin, :effective_mergery
```

## License

MIT License. Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request

