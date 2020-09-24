# Interaktor

[![Gem Version](https://img.shields.io/gem/v/interaktor.svg)](http://rubygems.org/gems/interaktor)
[![Build Status](https://img.shields.io/travis/collectiveidea/interaktor/master.svg)](https://travis-ci.org/taylorthurlow/interaktor)

**Interaktor** is a fork of [Interaktor by collectiveidea](https://github.com/collectiveidea/interaktor). While Interaktor is still used by collectiveidea internally, communication and progress has been slow in adapting to pull requests and issues. This inactivity combined with my desire to dial back on the Interaktor's inherent permissivity led me to fork it and create Interaktor.

Fundamentally, Interaktor is the same as Interactor, but with a small DSL which is used to define attributes passed into the interaktor, such as:

- Required attributes
- Optional attributes
- Attributes required on interaktor failure
- Attributes required on interaktor success

## Getting started

Add `interaktor` to your Gemfile and `bundle install`.

```ruby
gem "interaktor", "~> 0.1"
```

## What is an interaktor?

An interaktor is a simple, single-purpose object.

Interaktors are used to encapsulate your application's [business logic](http://en.wikipedia.org/wiki/Business_logic). Each interaktor represents one thing that your application _does_.

### Attributes

#### Input attributes

Depending on its definition, an interaktor may require attributes to be passed in when it is invoked. These attributes contain everything the interaktor needs to do its work.

You may define `required` or `optional` attributes.

```ruby
class CreateUser
  include Interaktor

  required :name

  optional :email

  def call
    User.create!(
      name: name,
      email: email,
    )
  end
end

CreateUser.call(name: "Foo Bar")

```

#### Output attributes

Based on the outcome of the interaktor's work, we can require certain attributes. In the example below, we must succeed with a `user_id` attribute, and if we fail, we must provide an `error_messages` attribute.

The use of `#success!` allows you to early-return from an interaktor's work. If no `success` attribute is provided, and the `call` method finishes execution normally, then the interaktor is considered to be in a successful state.

```ruby
class CreateUser
  include Interaktor

  required :name

  success :user_id

  failure :error_messages

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

#### Dealing with sailure

`context.fail!` always throws an exception of type `Interaktor::Failure`.

Normally, however, these exceptions are not seen. In the recommended usage, the controller invokes the interaktor using the class method `.call`, then checks the `#success?` method of the context.

This works because the `call` class method swallows exceptions. When unit testing an interaktor, if calling custom business logic methods directly and bypassing `call`, be aware that `fail!` will generate such exceptions.

See _Interaktors in the controller_, below, for the recommended usage of `call` and `success?`.

### Hooks

#### Before hooks

Sometimes an interaktor needs to prepare its context before the interaktor is even run. This can be done with before hooks on the interaktor.

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

Interaktors can also perform teardown operations after the interaktor instance
is run. They are only run on success.

```ruby
after do
  context.user.reload
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

Before hooks are invoked in the order in which they were defined while after
hooks are invoked in the opposite order. Around hooks are invoked outside of any
defined before and after hooks. For example:

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

An interaktor can define multiple before/after hooks, allowing common hooks to
be extracted into interaktor concerns.

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

# All documentation below this line has not been updated to reflect the fork from Interactor.

## Kinds of interaktors

There are two kinds of interaktors built into the Interaktor library: basic
interaktors and organizers.

### Interaktors

A basic interaktor is a class that includes `Interaktor` and defines `call`.

```ruby
class AuthenticateUser
  include Interaktor

  def call
    if user = User.authenticate(context.email, context.password)
      context.user = user
      context.token = user.secret_token
    else
      context.fail!(message: "authenticate_user.failure")
    end
  end
end
```

Basic interaktors are the building blocks. They are your application's
single-purpose units of work.

### Organizers

An organizer is an important variation on the basic interaktor. Its single
purpose is to run _other_ interaktors.

```ruby
class PlaceOrder
  include Interaktor::Organizer

  organize CreateOrder, ChargeCard, SendThankYou
end
```

In the controller, you can run the `PlaceOrder` organizer just like you would
any other interaktor:

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

The organizer passes its context to the interaktors that it organizes, one at a
time and in order. Each interaktor may change that context before it's passed
along to the next interaktor.

#### Rollback

If any one of the organized interaktors fails its context, the organizer stops.
If the `ChargeCard` interaktor fails, `SendThankYou` is never called.

In addition, any interaktors that had already run are given the chance to undo
themselves, in reverse order. Simply define the `rollback` method on your
interaktors:

```ruby
class CreateOrder
  include Interaktor

  def call
    order = Order.create(order_params)

    if order.persisted?
      context.order = order
    else
      context.fail!
    end
  end

  def rollback
    context.order.destroy
  end
end
```

**NOTE:** The interaktor that fails is _not_ rolled back. Because every
interaktor should have a single purpose, there should be no need to clean up
after any failed interaktor.

## Testing interaktors

When written correctly, an interaktor is easy to test because it only _does_ one
thing. Take the following interaktor:

```ruby
class AuthenticateUser
  include Interaktor

  def call
    if user = User.authenticate(context.email, context.password)
      context.user = user
      context.token = user.secret_token
    else
      context.fail!(message: "authenticate_user.failure")
    end
  end
end
```

You can test just this interaktor's single purpose and how it affects the
context.

```ruby
describe AuthenticateUser do
  subject(:context) { AuthenticateUser.call(email: "john@example.com", password: "secret") }

  describe ".call" do
    context "when given valid credentials" do
      let(:user) { double(:user, secret_token: "token") }

      before do
        allow(User).to receive(:authenticate).with("john@example.com", "secret").and_return(user)
      end

      it "succeeds" do
        expect(context).to be_a_success
      end

      it "provides the user" do
        expect(context.user).to eq(user)
      end

      it "provides the user's secret token" do
        expect(context.token).to eq("token")
      end
    end

    context "when given invalid credentials" do
      before do
        allow(User).to receive(:authenticate).with("john@example.com", "secret").and_return(nil)
      end

      it "fails" do
        expect(context).to be_a_failure
      end

      it "provides a failure message" do
        expect(context.message).to be_present
      end
    end
  end
end
```

[We](http://collectiveidea.com) use RSpec but the same approach applies to any
testing framework.

### Isolation

You may notice that we stub `User.authenticate` in our test rather than creating
users in the database. That's because our purpose in
`spec/interaktors/authenticate_user_spec.rb` is to test just the
`AuthenticateUser` interaktor. The `User.authenticate` method is put through its
own paces in `spec/models/user_spec.rb`.

It's a good idea to define your own interfaces to your models. Doing so makes it
easy to draw a line between which responsibilities belong to the interaktor and
which to the model. The `User.authenticate` method is a good, clear line.
Imagine the interaktor otherwise:

```ruby
class AuthenticateUser
  include Interaktor

  def call
    user = User.where(email: context.email).first

    # Yuck!
    if user && BCrypt::Password.new(user.password_digest) == context.password
      context.user = user
    else
      context.fail!(message: "authenticate_user.failure")
    end
  end
end
```

It would be very difficult to test this interaktor in isolation and even if you
did, as soon as you change your ORM or your encryption algorithm (both model
concerns), your interaktors (business concerns) break.

_Draw clear lines._

### Integration

While it's important to test your interaktors in isolation, it's just as
important to write good integration or acceptance tests.

One of the pitfalls of testing in isolation is that when you stub a method, you
could be hiding the fact that the method is broken, has changed or doesn't even
exist.

When you write full-stack tests that tie all of the pieces together, you can be
sure that your application's individual pieces are working together as expected.
That becomes even more important when you add a new layer to your code like
interaktors.

**TIP:** If you track your test coverage, try for 100% coverage _before_
integrations tests. Then keep writing integration tests until you sleep well at
night.

### Controllers

One of the advantages of using interaktors is how much they simplify controllers
and their tests. Because you're testing your interaktors thoroughly in isolation
as well as in integration tests (right?), you can remove your business logic
from your controller tests.

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
      expect(AuthenticateUser).to receive(:call).once.with(email: "john@doe.com", password: "secret").and_return(context)
    end

    context "when successful" do
      let(:user) { double(:user, id: 1) }
      let(:context) { double(:context, success?: true, user: user, token: "token") }

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
      let(:context) { double(:context, success?: false, message: "message") }

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

This controller test will have to change very little during the life of the
application because all of the magic happens in the interaktor.

### Rails

[We](http://collectiveidea.com) love Rails, and we use Interaktor with Rails. We
put our interaktors in `app/interaktors` and we name them as verbs:

- `AddProductToCart`
- `AuthenticateUser`
- `PlaceOrder`
- `RegisterUser`
- `RemoveProductFromCart`

See: [Interaktor Rails](https://github.com/collectiveidea/interaktor-rails)

## Contributions

Interaktor is open source and contributions from the community are encouraged!
No contribution is too small.

See Interaktor's
[contribution guidelines](CONTRIBUTING.md) for more information.

## Thank You

A very special thank you to [Attila Domokos](https://github.com/adomokos) for
his fantastic work on [LightService](https://github.com/adomokos/light-service).
Interaktor is inspired heavily by the concepts put to code by Attila.

Interaktor was born from a desire for a slightly simplified interface. We
understand that this is a matter of personal preference, so please take a look
at LightService as well!
