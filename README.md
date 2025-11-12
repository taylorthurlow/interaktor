# Interaktor

[![gem version](https://badge.fury.io/rb/interaktor.svg)](http://rubygems.org/gems/interaktor)

**DISCLAIMER: Interaktor is considered to be stable, but has not yet reached version 1.0. Following semantic versioning, minor version updates can introduce breaking changes. Please review the changelog when updating.**

**Interaktor** is a fork of [Interactor by collectiveidea](https://github.com/collectiveidea/interactor). While Interactor is still used by collectiveidea internally, communication and progress has been slow in adapting to pull requests and issues. This inactivity combined with my desire to dial back on the Interactor's inherent permissivity led me to fork it and create Interaktor.

Fundamentally, Interaktor is the same as Interactor, but with the following changes:

- Explicit definition of interaktor "attributes" which replaces the concept of the interaktor context. Attributes are defined using the DSL provided by [ActiveModel](https://rubygems.org/gems/activemodel), which allows for complex validation, if desired. This is the same DSL used internally by ActiveRecord, so you will be familiar with validations if you have experience with ActiveRecord.
- The interaktor "context" is no longer a public-facing concept, all data/attribute accessors/setters are defined as attributes
- Attributes passed to `#fail!` must be defined in advance
- Interaktors support early-exit functionality through the use of `#success!`, which functions the same as `#fail!` in that you must define the success attributes on the interaktor

## Getting started

Add `interaktor` to your Gemfile and `bundle install`.

```ruby
gem "interaktor"
```

## What is an interaktor?

An interaktor is a simple, single-purpose object.

Interaktors are used to encapsulate your application's [business logic](http://en.wikipedia.org/wiki/Business_logic). Each interaktor represents one thing that your application _does_.

### Attributes

Attributes are defined using the DSL provided by ActiveModel, whose documentation can be found [here](https://api.rubyonrails.org/classes/ActiveModel/Attributes.html). The same DSL is used to define _input_ attributes, _success_ attributes, and _failure_ attributes.

The aforementioned documentation provides a reasonably comprehensive overview of the DSL is used. But generally a definition block looks like this:

```ruby
attribute :name, :string
attribute :email, :string
attribute :date_of_birth

validates :name, presence: true
validates :email, presence: true, allow_nil: true
validates :date_of_birth, presence: true
```

Defining an attribute requires a name, and optionally a type. The available types are not currently well documented, but can be found clearly in the source code of ActiveModel. At the time of writing (activemodel `8.1.1`), the following types are available: `big_integer`, `binary`, `boolean`, `date`, `datetime`, `decimal`, `float`, `immutable_string`, `integer`, `string`, and `time`.

Defining a type will allow ActiveModel to perform type-specific validation and coercion. This means that when a value is assigned to an attribute, ActiveModel will attempt to convert it to the specified type, and raise an error if the conversion is not possible.

The type argument can also be a class constant, but that class will need to define certain methods that ActiveModel relies on in order to work properly - the errors raised by ActiveModel should illustrate which methods are required.

Validations should look familiar to Rails developers. They are defined using the `validates` method, which takes a hash of options. The options are the same as those used in Rails, so you can refer to the Rails documentation for more information.

In general, it is recommended to be careful with validations. These are not database records - they are simply a way to ensure that the data passed into an interaktor is valid and consistent before it is processed. Consider thinking twice before adding validations more complicated than typical `nil`/`blank?` checks.

#### Input attributes

Input attributes are attributes that are passed into an interaktor when it is invoked. The following interaktor defines a required `name` attribute and an optional `email` attribute.

```ruby
class CreateUser
  include Interaktor

  input do
    attribute :name, :string
    attribute :email, :string

    validates :name, presence: true
    validates :email, presence: true, allow_nil: true
  end

  def call
    User.create!(
      name: name,
      email: email,
    )
  end
end

CreateUser.call!(name: "Foo Bar")
```

#### Success and failure attributes

Based on the outcome of the interaktor's work, we can define attributes to be provided.

The use of `#success!` allows you to early return from an interaktor's work. If no `success` attributes are defined, and the `call` method finishes execution normally, then the interaktor is considered to to have completed successfully. Conversely, if `success` attributes are defined, and the `call` method finishes execution normally (i.e. without a raised error, and without calling `success!`), then an exception will be raised.

In the example below, we must succeed with a `user_id` attribute, and if we fail, we must provide an `error_messages` attribute.

```ruby
class CreateUser
  include Interaktor

  input do
    attribute :name, :string

    validates :name, presence: true
  end

  success do
    attribute :user_id, :integer

    validates :user_id, presence: true
  end

  failure do
    attribute :error_messages # string array

    validates :error_messages, presence: true
  end

  def call
    user = User.new(name: name)

    if user.save
      success!(user_id: user.id)
    else
      fail!(error_messages: user.errors.full_messages)
    end
  end
end

result = CreateUser.call(name: "Foo Bar")

if result.success?
  puts "The new user ID is: #{result.user_id}".
else
  puts "Creating the user failed: #{result.error_messages.join(", ")}".
end
```

The returned object is an instance of `Interaktor::Interaction`. Depending on whether the interaction was successful or not, the object will have different attributes and methods available. These methods are determined by the success and failure attributes defined on the interaktor. It is not possible to access input attributes on the Interaction object.

#### Dealing with failure

`#fail!` always throws an exception of type `Interaktor::Failure`.

Normally, however, these exceptions are not seen. In the recommended usage, the caller invokes the interaktor using the class method `.call`, then checks the `#success?` method of the returned object. This works because the `call` class method rescues the `Interaktor::Failure` exception. When unit testing an interaktor, if calling custom business logic methods directly and bypassing `call`, be aware that `fail!` will generate such exceptions.

See _Interaktors in the controller_, below, for the recommended usage of `.call` and `#success?`.

### Hooks

#### Before hooks

Sometimes an interaktor needs to prepare something before the interaktor is even run. This can be done with before hooks on the interaktor.

```ruby
before do
  # Do some stuff
end
```

A symbol argument can also be given, rather than a block.

```ruby
before :do_some_stuff

def do_some_stuff
  # Do some stuff
end
```

#### After hooks

Interaktors can also perform teardown operations after the interaktor instance is run. They are only run on success.

```ruby
after do
  user.reload
end
```

#### Ensure hooks

Very similar to `after` hooks, but the hooks are run in an `ensure` block in the order they are defined.

```ruby
ensure_hook do
  file.close
end
```

#### Around hooks

You can also define around hooks in the same way as before or after hooks, using either a block or a symbol method name. The difference is that an around block or method accepts a single argument. Invoking the `call` method on that argument will continue invocation of the interaktor. For example, with a block:

```ruby
around do |interaktor|
  # Do stuff before
  interaktor.call
  # Do stuff after
end
```

With a method:

```ruby
around :do_stuff_around

def do_stuff_around(interaktor)
  # Do stuff before
  interaktor.call
  # Do stuff after
end
```

If `#fail!` is called, any code defined in the hook after the call to the interaktor will not be run.

#### Hook sequence

Before hooks are invoked in the order in which they were defined while after hooks are invoked in the opposite order. Around hooks are invoked outside of any defined before and after hooks. For example:

```ruby
around do |interaktor|
  puts "around before 1"
  interaktor.call
  puts "around after 1"
end

around do |interaktor|
  puts "around before 2"
  interaktor.call
  puts "around after 2"
end

before do
  puts "before 1"
end

before do
  puts "before 2"
end

after do
  puts "after 1"
end

after do
  puts "after 2"
end
```

will output:

```
around before 1
around before 2
before 1
before 2
after 2
after 1
around after 2
around after 1
```

#### Interaktor concerns

An interaktor can define multiple before/after hooks, allowing common hooks to be extracted into interaktor concerns.

```ruby
module InteraktorDoStuff
  extend ActiveSupport::Concern

  included do
    around do |interaktor|
      # Do stuff before
      interaktor.call
      # Do stuff after
    end
  end
end
```

## Kinds of interaktors

There are two kinds of interaktors built into the Interaktor library: basic interaktors and organizers.

### Interaktors

A basic interaktor is a class that includes `Interaktor` and defines `call`.

```ruby
class PrintAThing
  include Interaktor

  input { attribute :name }

  def call
    puts name
  end
end
```

Basic interaktors are the building blocks. They are your application's single-purpose units of work.

### Organizers

An organizer is a variation on the basic interaktor. Its single purpose is to run _other_ interaktors.

```ruby
class DoSomeThingsInOrder
  include Interaktor::Organizer

  input do
    attribute :name, :string

    validates :name, presence: true
  end

  organize CreateOrder, ChargeCard, SendThankYou
end
```

In the controller, you can run the `PlaceOrder` organizer just like you would any other interaktor:

```ruby
class OrdersController < ApplicationController
  def create
    result = PlaceOrder.call(order_params: order_params)

    if result.success?
      redirect_to result.order
    else
      @order = result.order
      render :new
    end
  end

  private

  def order_params
    params.require(:order).permit!
  end
end
```

The organizer passes its own input arguments (if present) into first interaktor that it organizes (in the above example, `CreateOrder`), which is called and executed using those arguments. For the following interaktors in the organize list, each interaktor receives its input arguments from the previous interaktor (both input arguments and success arguments, with success arguments taking priority in the case of a name collision).

Any arguments which are _not_ accepted by the next interaktor (listed as an input attribute) are dropped in the transition.

If the organizer specifies any success attributes, the final interaktor in the
organized list must also specify those success attributes.

#### Rollback

If any one of the organized interaktors fails, the organizer stops. If the `ChargeCard` interaktor fails, `SendThankYou` is never called.

In addition, any interaktors that had already run are given the chance to undo themselves, in reverse order. Simply define the `rollback` method on your interaktors.

```ruby
class CreateOrder
  include Interaktor

  input do
    attribute :order_params

    validates :order_params, presence: true
  end

  success do
    attribute :order

    validates :order, presence: true
  end

  def call
    order = Order.create(order_params)

    if order.persisted?
      success!(order: order)
    else
      fail!
    end
  end

  def rollback
    order.destroy
  end
end
```

**NOTE:** The interaktor that fails is _not_ rolled back. Because every interaktor should have a single purpose, there should be no need to clean up after any failed interaktor. This is why the rollback method above can access the `order` success attribute - rollback is only called on successful interaktors.

## Testing interaktors

When written correctly, an interaktor is easy to test because it only _does_ one thing. Take the following interaktor:

```ruby
class AuthenticateUser
  include Interaktor

  input do
    attribute :email, :string
    attribute :password, :string

    validates :email, presence: true
    validates :password, presence: true
  end

  success do
    attribute :user
    attribute :token, :string

    validates :user, presence: true
    validates :token, presence: true
  end

  failure do
    attribute :message

    validates :message, presence: true
  end

  def call
    if user = User.authenticate(email, password)
      success!(user: user, token: user.secret_token)
    else
      fail!(message: "authenticate_user.failure")
    end
  end
end
```

You can test just this interaktor's single purpose and how it affects the result.

```ruby
describe AuthenticateUser do
  subject(:result) { AuthenticateUser.call(email: "john@example.com", password: "secret") }

  describe ".call" do
    context "when given valid credentials" do
      let(:user) { double(:user, secret_token: "token") }

      before do
        allow(User).to receive(:authenticate).with("john@example.com", "secret").and_return(user)
      end

      it "succeeds" do
        expect(result).to be_a_success
      end

      it "provides the user" do
        expect(result.user).to eq user
      end

      it "provides the user's secret token" do
        expect(result.token).to eq "token"
      end
    end

    context "when given invalid credentials" do
      before do
        allow(User).to receive(:authenticate).with("john@example.com", "secret").and_return(nil)
      end

      it "fails" do
        expect(result).to be_a_failure
      end

      it "provides a failure message" do
        expect(result.message).to be_present
      end
    end
  end
end
```

### Isolation

You may notice that we stub `User.authenticate` in our test rather than creating users in the database. That's because our purpose in `spec/interaktors/authenticate_user_spec.rb` is to test just the `AuthenticateUser` interaktor. The `User.authenticate` method is put through its own paces in `spec/models/user_spec.rb`.

It's a good idea to define your own interfaces to your models. Doing so makes it easy to draw a line between which responsibilities belong to the interaktor and which to the model. The `User.authenticate` method is a good, clear line. Imagine the interaktor otherwise:

```ruby
class AuthenticateUser
  include Interaktor

  # ...

  def call
    user = User.find_by(email: email)

    # Yuck!
    if user && BCrypt::Password.new(user.password_digest) == password
      success!(user: user)
    else
      fail!(message: "authenticate_user.failure")
    end
  end
end
```

It would be very difficult to test this interaktor in isolation and even if you did, as soon as you change your ORM or your encryption algorithm (both model concerns), your interaktors (business concerns) break.

_Draw clear lines._

### Integration

While it's important to test your interaktors in isolation, it's just as important to write good integration or acceptance tests.

One of the pitfalls of testing in isolation is that when you stub a method, you could be hiding the fact that the method is broken, has changed or doesn't even exist.

When you write full-stack tests that tie all of the pieces together, you can be sure that your application's individual pieces are working together as expected. That becomes even more important when you add a new layer to your code like interaktors.

### Controllers

One of the advantages of using interaktors is how much they simplify controllers and their tests. Because you're testing your interaktors thoroughly in isolation as well as in integration tests (right?), you can remove your business logic from your controller tests.

```ruby
class SessionsController < ApplicationController
  def create
    result = AuthenticateUser.call(session_params)

    if result.success?
      session[:user_token] = result.token
      redirect_to result.user
    else
      flash.now[:message] = t(result.message)
      render :new
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
```

```ruby
describe SessionsController do
  describe "#create" do
    before do
      expect(AuthenticateUser).to receive(:call).once.with(email: "john@doe.com", password: "secret").and_return(result)
    end

    context "when successful" do
      let(:user) { double(:user, id: 1) }
      let(:result) { double(:result, success?: true, user: user, token: "token") }

      it "saves the user's secret token in the session" do
        expect {
          post :create, session: { email: "john@doe.com", password: "secret" }
        }.to change {
          session[:user_token]
        }.from(nil).to("token")
      end

      it "redirects to the homepage" do
        response = post :create, session: { email: "john@doe.com", password: "secret" }

        expect(response).to redirect_to(user_path(user))
      end
    end

    context "when unsuccessful" do
      let(:result) { double(:result, success?: false, message: "message") }

      it "sets a flash message" do
        expect {
          post :create, session: { email: "john@doe.com", password: "secret" }
        }.to change {
          flash[:message]
        }.from(nil).to(I18n.translate("message"))
      end

      it "renders the login form" do
        response = post :create, session: { email: "john@doe.com", password: "secret" }

        expect(response).to render_template(:new)
      end
    end
  end
end
```

This controller test will have to change very little during the life of the application because all of the magic happens in the interaktor.

### Rails

Interactor provided [interactor-rails](https://github.com/collectiveidea/interactor-rails), which ensures `app/interactors` is included in your autoload paths, and provides generators for new interactors. I have no intention of maintaining generators but if someone feels strongly enough to submit a pull request to include the functionality in _this_ gem (not a separate Rails one) then I will be happy to take a look. Making sure `app/interaktors` is included in your autoload paths is something I would like to do soon.
