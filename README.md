# Ve

Yet another Elixir data validation engine library.

Main goals: light and succintly.

`Ve` is going to be used (as is) in production. PR of improvements or issues are welcome.

## Installation

The package can be installed by adding `ve` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ve, "~> 0.1"}
  ]
end
```

## Usage

Some examples for usage.

#### Strings

```elixir
"foo" |> Ve.validate([:string])       
{:ok, "foo"}

123 |> Ve.validate([:string])  
{:error, ["string_expected_got_integer"]}

"my data" |> Ve.validate([:string, pattern: ~r/data/])
{:ok, "my data"}

nil |> Ve.validate([:string, :nullable])  
{:ok, nil}

"test" |> Ve.validate([:string, :not_empty])
{:ok, "test"}

"" |> Ve.validate([:string, :not_empty])    
{:error, ["string_cannot_be_empty"]}

"  \t \t" |> Ve.validate([:string, :not_empty])
{:error, ["string_cannot_be_empty"]}

```

#### Integers

```elixir
123 |> Ve.validate([:integer])  
{:ok, 123}

123 |> Ve.validate([:integer, min: 120, max: 130]) 
{:ok, 123}
```

#### Lists

```elixir
["a"] |> Ve.validate([:list])
{:ok, ["a"]}

["a"] |> Ve.validate([:list, of: [:string]])   
{:ok, ["a"]}

[123, "a"] |> Ve.validate([:list, of: [:integer]])
{:error, ["integer_expected_got_bitstring"]}
```

#### Maps

```elixir
%{name: "foo"} |> Ve.validate([:map, fields: [name: [:string]]])
{:ok, %{name: "foo"}}

%{name: "foo"} |> Ve.validate([:map, fields: [name: [:string], surname: [:string, :optional]]])
{:ok, %{name: "foo"}}

%{name: "foo", surname: nil} |> Ve.validate([:map, fields: [name: [:string], surname: [:string, :nullable]]])
{:ok, %{name: "foo", surname: nil}}

%{name: "foo", surname: "foo"} |> Ve.validate([:map, xor_fields: [name: [:string], surname: [:string]]])
{:error, ["just_one_field_must_be_present"]}
```

#### Fixed value
56 |> Ve.validate([:integer, value: 56])
{:ok, 56}

46 |> Ve.validate([:integer, value: 56])
{:error, ["invalid_fixed_value"]}

true |> Ve.validate([:boolean, value: true])
{:ok, true}

false |> Ve.validate([:boolean, value: true])
{:error, ["invalid_fixed_value"]}

"foo" |> Ve.validate([:string, value: "foo"])
{:ok, "foo"}

"bar" |> Ve.validate([:string, value: "foo"])
{:error, ["invalid_fixed_value"]}

Other flags are available but not documented yet.