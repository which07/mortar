## Light Table ##

### Installation

This branch requires C Compiled ruby extension, make sure you have the appropriate Ruby setup to compile. Once you're ready a simple `bundle install` should do the trick.

### Usage

Using light table is easy:

```ruby
  $ mortar local:watch [script]
```

### Known issues

* Parameters don't work
* Deleting Aliases can pollute the namespace
* Syntax Errors aren't handled at all
* Soooooo fragile

