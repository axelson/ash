# Getting Started

## Creating an application

For information on creating a new Elixir application, see [this guide](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html).

```shell
mix new my_app
```

For the finished example, see [this example](https://github.com/mario-mazo/my_app).

### With Phoenix

The next guide will show you how to create a new Phoenix application and copy your resources and APIs over. However, if you know that you will be building a web application and would like to start with Phoenix, you can replace the above command with:

```shell
mix phx.new my_app --no-html --no-webpack --no-gettext
```

## Add Ash

Add `ash` to your dependencies in `mix.exs`. The latest version can be found by running `mix hex.info ash`.

```elixir
# in mix.exs
def deps() do
  [
    {:ash, "~> x.x.x"}
  ]
end
```

If you want to have a more idiomatic formatting (the one used in this documentation) of your Ash resource and APIs,
you need to add Ash (and any other extensions you use) to your `.formatter.exs` otherwise the default Elixir formatter will wrap portions of the DSL in parenthesis.

```elixir
 import_deps: [
    :ash
  ]
```

Without that, instead of:

```elixir
attribute :id, :integer, allow_nil?: true
```

the Elixir formatter will change it to:

```elixir
attribute(:id, :integer, allow_nil?: true)
```

## Create an Ash API

Create an API module. This will be your primary way to interact with your Ash resources. We recommend `lib/my_app/api.ex` for simple setups. For more information on organizing resources into contexts/domains, see the "Contexts and Domains" guide.

```elixir
# lib/my_app/api.ex
defmodule MyApp.Api do
  use Ash.Api

  resources do
  end
end
```

## Create a resource

A resource is the primary entity in Ash. Your Api module ties your resources together and gives them an interface, but the vast majority of your configuration will live in resources. In your typical setup, you might have a resource per database table. For those already familiar with Ecto, a resource and an Ecto schema are very similar. In fact, all resources define an Ecto schema under the hood. This can be leveraged when you need to do things that are not yet implemented or fall outside of the scope of Ash. The current recommendation for where to put your resources is in `lib/my_app/resources/<resource_name>.ex`. Here are a few examples:

```elixir
# in lib/my_app/resources/tweet.ex
defmodule MyApp.Tweet do
  use Ash.Resource

  attributes do
    uuid_primary_key :id

    attribute :body, :string do
      allow_nil? false
      constraints max_length: 255
    end

    # Alternatively, you can use the keyword list syntax
    # You can also set functional defaults, via passing in a zero
    # argument function or an MFA
    attribute :public, :boolean, allow_nil?: false, default: false

    # This is set on create
    create_timestamp :created_at
    # This is updated on all updates
    update_timestamp :updated_at

    # `create_timestamp` above is just shorthand for:
    # attribute :created_at, :utc_datetime,
    #   writable?: false,
    #   default: &DateTime.utc_now/0
  end

end

# in lib/my_app/resources/user.ex
defmodule MyApp.User do
  use Ash.Resource

  attributes do
    attribute :email, :string,
      allow_nil?: false,
      constraints: [
        match: ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i
      ]

    uuid_primary_key :id
  end
end
```

## Add resources to your API

Alter your API in `api.ex` like so:

```elixir
resources do
  resource MyApp.User
  resource MyApp.Tweet
end
```

### Test the resources

Now you should be able to create changesets for your resources

```elixir
iex(7)> change = Ash.Changeset.new(MyApp.User, %{email: "ash.man@enguento.com"})
#Ash.Changeset<
  action_type: :create,
  attributes: %{email: "ash.man@enguento.com"},
  relationships: %{},
  errors: [],
  data: %MyApp.User{
    __meta__: #Ecto.Schema.Metadata<:built, "">,
    __metadata__: %{},
    aggregates: %{},
    calculations: %{},
    email: nil,
    id: nil
  },
  valid?: true
>
```

If you try to use an invalid email (the email regex is for demonstration purposes only)
an error will be displayed as shown:

```elixir
iex(6)> change = Ash.Changeset.new(MyApp.User, %{email: "@eng.com"})
#Ash.Changeset<
  action_type: :create,
  attributes: %{},
  relationships: %{},
  errors: [
    %Ash.Error.Changes.InvalidAttribute{
      class: :invalid,
      field: :email,
      message: {"must match the pattern %{regex}",
       [
         regex: "~r/^[\\w.!#$%&‚Äô*+\\-\\/=?\\^`{|}~]+@[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)*$/i"
       ]},
      path: [],
      stacktrace: #Stacktrace<>
    }
  ],
  data: %MyApp.User{
    __meta__: #Ecto.Schema.Metadata<:built, "">,
    __metadata__: %{},
    aggregates: %{},
    calculations: %{},
    email: nil,
    id: nil
  },
  valid?: false
>
```

## Add your data_layer

To be able to store and later on read your resources, a _data layer_ is required. For more information, see the documentation for the data layer you would like to use. The currently supported data layers are listed below:

| Storage | Datalayer | Documentation | Storage Documentation |
|---|---|---| --- |
| postgres | AshPostgres.DataLayer | [Documentation](https://hexdocs.pm/ash_postgres) | [Storage Documentation](https://www.postgresql.org/docs/) |
| ets | Ash.DataLayer.Ets | [Documentation](https://hexdocs.pm/ash/Ash.DataLayer.Ets.html) | [Storage Documentation](https://erlang.org/doc/man/ets.html) |
| mnesia | Ash.DataLayer.Mnesia | [Documentation](https://hexdocs.pm/ash/Ash.DataLayer.Mnesia.html) | [Storage Documentation](https://erlang.org/doc/man/mnesia.html) |
| csv | AshCsv.DataLayer | [Documentation](https://hexdocs.pm/ash_csv) | [Storage Documentation](https://en.wikipedia.org/wiki/Comma-separated_values) |

To add a `data_layer`, add it to the `use Ash.Resource` statement. In this case we are going to use `ETS` which is a in memory data layer good enough for testing purposes. Also we will make the ETS private so Read/Write limited
to owner process.

```elixir
  # in both lib/my_app/resources/user.ex
  # and lib/my_app/resources/tweet.ex

  use Ash.Resource, data_layer: Ash.DataLayer.Ets
```

## Add actions to enable functionality

Actions are the primary driver for adding specific interactions to your resource.
You can read the [actions](https://hexdocs.pm/ash/Ash.Resource.Dsl.html#module-actions
) section to learn how to customize the functionality.
For now we will enable all of them with default implementations by adding the
following block to your resources:

```elixir
  # in both lib/my_app/resources/user.ex
  # and lib/my_app/resources/tweet.ex

  actions do
    create :create
    read :read
    update :update
    destroy :destroy
  end
```

### Test functionality

Now you should be able to use your API to do CRUD operations on your resources.

#### Create resource

```elixir
iex(1)> user_changeset = Ash.Changeset.new(MyApp.User, %{email: "ash.man@enguento.co
m"})
#Ash.Changeset<
  action_type: :create,
  attributes: %{email: "ash.man@enguento.com"},
  relationships: %{},
  errors: [],
  data: %MyApp.User{
    __meta__: #Ecto.Schema.Metadata<:built, "">,
    __metadata__: %{},
    aggregates: %{},
    calculations: %{},
    email: nil,
    id: nil
  },
  valid?: true
>
iex(2)> MyApp.Api.create(user_changeset)
{:ok,
 %MyApp.User{
   __meta__: #Ecto.Schema.Metadata<:built, "">,
   __metadata__: %{},
   aggregates: %{},
   calculations: %{},
   email: "ash.man@enguento.com",
   id: "2642ca11-330b-4a07-83c7-b0e9ef391df6"
 }}
```

##### List and Read a resource

```elixir
iex(3)> MyApp.Api.read MyApp.User
{:ok,
 [
   %MyApp.User{
     __meta__: #Ecto.Schema.Metadata<:built, "">,
     __metadata__: %{},
     aggregates: %{},
     calculations: %{},
     email: "ash.man@enguento.com",
     id: "2642ca11-330b-4a07-83c7-b0e9ef391df6"
   }
 ]}
iex(4)> MyApp.Api.get(MyApp.User, "ash.man@enguento.com")
{:ok,
 %MyApp.User{
   __meta__: #Ecto.Schema.Metadata<:built, "">,
   __metadata__: %{},
   aggregates: %{},
   calculations: %{},
   email: "ash.man@enguento.com",
   id: "2642ca11-330b-4a07-83c7-b0e9ef391df6"
 }}
```

## Add relationships

With our resources stored in a data layer we can move on
to create relationships between them. In this case we will
specify that a `User` can have many `Tweets` - this implies that
a `Tweet` belongs to a specific `User`.

```elixir
# in lib/my_app/resources/user.ex
  relationships do
    has_many :tweets, MyApp.Tweet, destination_field: :user_id
  end

# in lib/my_app/resources/tweet.ex
  relationships do
    belongs_to :user, MyApp.User
  end
```

### Test relationships

Now we can use the new relationship to create a `Tweet` that belongs to a specific `User`:

```elixir
iex(8)> {:ok, user} = Ash.Changeset.new(MyApp.User, %{email: "ash.man@enguento.com"}) |> MyApp.Api.create()
{:ok,
 %MyApp.User{
   __meta__: #Ecto.Schema.Metadata<:built, "">,
   __metadata__: %{},
   aggregates: %{},
   calculations: %{},
   email: "ash.man@enguento.com",
   id: "0d7063f8-b07c-4d02-88b2-b671f1aa0ad9",
   tweets: #Ash.NotLoaded<:relationship>
 }}
iex(9)> MyApp.Tweet |> Ash.Changeset.new(%{body: "ashy slashy"}) |> Ash.Changeset.replace_relationship(:user, user) |> MyApp.Api.create()
{:ok,
 %MyApp.Tweet{
   __meta__: #Ecto.Schema.Metadata<:built, "">,
   __metadata__: %{},
   aggregates: %{},
   body: "ashy slashy",
   calculations: %{},
   created_at: ~U[2020-11-14 12:54:06Z],
   id: "f0b0b9d5-832c-45c9-9313-5e3fb9f1af24",
   public: false,
   updated_at: ~U[2020-11-14 12:54:06Z],
   user: %MyApp.User{
     __meta__: #Ecto.Schema.Metadata<:built, "">,
     __metadata__: %{},
     aggregates: %{},
     calculations: %{},
     email: "ash.man@enguento.com",
     id: "0d7063f8-b07c-4d02-88b2-b671f1aa0ad9",
     tweets: #Ash.NotLoaded<:relationship>
   },
   user_id: "0d7063f8-b07c-4d02-88b2-b671f1aa0ad9"
 }}
```

## Add front end extensions

Now that the Elixir API is complete, you can move on to the [next section](https://hexdocs.pm/ash/getting_started_phx.html)
to learn how to change the data_layer to PostgreSQL and expose it via a JSON API.

- `AshJsonApi` - can be used to build a spec compliant JSON:API.
- `AshPostgres.DataLayer` - can be used to persist your resources to PostgreSQL.

## See Ash documentation for the rest

- `Ash.Api` for what you can do with your resources.
- `Ash.Query` for the kinds of queries you can make.
- `Ash.Resource.Dsl` for the resource DSL documentation.
- `Ash.Api.Dsl` for the API DSL documentation.
