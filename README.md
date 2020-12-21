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

Some trivial examples for usage.

#### Generic constraints (valid for every data type)

```elixir
# NULLABLE
"foo" |> Ve.validate([:string, :nullable])
{:ok, "foo"}

nil |> Ve.validate([:string, :nullable])
{:ok, "foo"}

# IN a set of possible values
"foo" |> Ve.validate([:string, in: ["foo", "bar"]])
{:ok, "foo"}

"xxx" |> Ve.validate([:string, in: ["foo", "bar"]])
{:error, ["invalid_possible_value"]}

# fixed VALUE
"bar" |> Ve.validate([:string, value: "bar"])
{:ok, "bar"}

"foo" |> Ve.validate([:string, value: "bar"])
{:error, ["invalid_fixed_value"]}

true |> Ve.validate([:boolean, value: true])
{:ok, true}

false |> Ve.validate([:boolean, value: true])
{:error, ["invalid_fixed_value"]}
```

#### Any

```elixir
"foo" |> Ve.validate([:any, in: ["foo", 42]])
{:ok, "foo"}

42 |> Ve.validate([:any, in: ["some data", 42]])
{:ok, 42}
```

#### Strings

```elixir
"foo" |> Ve.validate([:string])
{:ok, "foo"}

123 |> Ve.validate([:string])
{:error, ["string_expected_got_integer"]}

"my data" |> Ve.validate([:string, pattern: ~r/data/])
{:ok, "my data"}

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

%{name: "foo", surname: "foo"} |> Ve.validate([:map, xor: [name: [:string], surname: [:string]]])
{:error, ["just_one_field_must_be_present"]}
```

#### Tuple

```elixir
{"a", 9} |> Ve.validate([:tuple, of: [[:string], [:integer, max: 10]]])
{:ok, {"a", 9}}
```
