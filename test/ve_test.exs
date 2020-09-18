defmodule VeTest do
  use ExUnit.Case
  doctest Ve

  valid_types = [
    {"string", :string, valid: "test", invalid: {51, "string_expected_got_integer"}},
    {"integer", :integer, valid: 51, invalid: {"test", "integer_expected_got_bitstring"}},
    {"atom", :atom, valid: :my_atom, invalid: {"test", "atom_expected_got_bitstring"}},
    {"list", :list, valid: [51, 52], invalid: {"test", "list_expected_got_bitstring"}},
    {"map", :map, valid: %{}, invalid: {"test", "map_expected_got_bitstring"}},
    {"tuple", :tuple, valid: {}, invalid: {"test", "tuple_expected_got_bitstring"}},
    {"boolean", :boolean, valid: true, invalid: {"test", "boolean_expected_got_bitstring"}},
    {"float", :float, valid: 1.1, invalid: {"a", "float_expected_got_bitstring"}},
    {"function", :function, valid: &Kernel.is_string/1, invalid: {51, "function_expected_got_integer"}},
    {"binary", :binary, valid: <<0, 1, 2>>, invalid: {51, "binary_expected_got_integer"}}
    # {"pid", :pid, valid: :c.pid(0, 250, 0), invalid: {51, "pid_expected_got_integer"}},
    # {"port", :port, valid: "test", invalid: {51, "string_expected_got_integer"}},
    # {"reference", :reference, valid: "test", invalid: {51, "string_expected_got_integer"}},
  ]

  Enum.each(valid_types, fn {name, type, [valid: valid_data, invalid: {invalid_data, invalid_data_message}]} ->
    test "type #{name} is valid" do
      type = unquote(type)
      data = unquote(valid_data |> Macro.escape())

      assert Ve.validate(data, [type]) == {:ok, data}
    end

    test "type #{name} is invalid" do
      type = unquote(type)
      data = unquote(invalid_data)
      data_message = unquote(invalid_data_message)

      assert Ve.validate(data, [type]) == {:error, [data_message]}
    end

    test "type #{name} is valid but nullable" do
      type = unquote(type)
      assert Ve.validate(nil, [type, :nullable]) == {:ok, nil}
    end

    test "type #{name} is nil but not nullable" do
      type = unquote(type)
      assert Ve.validate(nil, [type]) == {:error, ["cannot_be_nullable"]}
    end
  end)

  test "unknown type" do
    assert Ve.validate("some data", []) == {:error, ["unknown_type"]}
  end

  test "any type" do
    assert Ve.validate("some data", [:any]) == {:ok, "some data"}
  end

  test "multiple type 1" do
    assert Ve.validate("some data", [:any, in: ["some data", 42]]) == {:ok, "some data"}
  end

  test "multiple type 2" do
    assert Ve.validate(42, [:any, in: ["some data", 42]]) == {:ok, 42}
  end

  test "apply pattern to string" do
    assert Ve.validate("some data", [:string, pattern: ~r/data/]) == {:ok, "some data"}
  end

  test "apply pattern to invalid string" do
    assert Ve.validate("some doto", [:string, pattern: ~r/data/]) == {:error, ["pattern_not_matched"]}
  end

  test "min integer" do
    assert Ve.validate(5, [:integer, min: 4]) == {:ok, 5}
  end

  test "min integer violated" do
    assert Ve.validate(5, [:integer, min: 6]) == {:error, ["min_violation"]}
  end

  test "min integer violated with custom error message" do
    assert Ve.validate(5, [:integer, min: 6, err_msg: "value must be minimum 6"]) ==
             {:error, ["value must be minimum 6"]}
  end

  test "max integer" do
    assert Ve.validate(5, [:integer, max: 6]) == {:ok, 5}
  end

  test "max integer violated" do
    assert Ve.validate(5, [:integer, max: 4]) == {:error, ["max_violation"]}
  end

  test "missing field in map" do
    assert Ve.validate(%{}, [:map, fields: [name: [:string]]]) == {:error, ["missing_field_name"]}
  end

  test "map contains a field" do
    assert Ve.validate(%{field: "field"}, [:map, fields: [field: [:string]]]) == {:ok, %{field: "field"}}
  end

  test "map contains a field with invalid type" do
    assert Ve.validate(%{field: "field"}, [:map, fields: [field: [:integer]]]) ==
             {:error, ["integer_expected_got_bitstring"]}
  end

  test "map contains some fields with invalid type" do
    schema = [:map, fields: [name: [:string], surname: [:string]]]

    assert Ve.validate(%{name: 52, surname: 54}, schema) ==
             {:error, ["string_expected_got_integer", "string_expected_got_integer"]}
  end

  test "map contains an invalid field and a missing field" do
    schema = [:map, fields: [name: [:string], surname: [:string]]]
    assert Ve.validate(%{name: 52}, schema) == {:error, ["string_expected_got_integer", "missing_field_surname"]}
  end

  test "map contains an invalid field and an invalid list item" do
    schema = [:map, fields: [b: [:integer], a: [:list, of: [:integer, min: 0]]]]
    assert Ve.validate(%{a: [-1, 3], b: ""}, schema) == {:error, ["integer_expected_got_bitstring", "min_violation"]}
  end

  test "map contains some optional fields" do
    schema = [:map, fields: [name: [:string], surname: [:string, :optional]]]
    assert Ve.validate(%{name: "f1"}, schema) == {:ok, %{name: "f1"}}
  end

  test "map contains some nullable fields" do
    schema = [:map, fields: [name: [:string], surname: [:string, :nullable]]]
    assert Ve.validate(%{name: "f1", surname: nil}, schema) == {:ok, %{name: "f1", surname: nil}}
  end

  test "map contains invalid field type" do
    schema = [:map, fields: [name: [:string]]]
    assert Ve.validate(%{name: %{n: "n", s: "s"}}, schema) == {:error, ["string_expected_got_map"]}
  end

  test "map of xor fields" do
    schema = [:map, xor: [name: [:string], surname: [:string]]]
    assert Ve.validate(%{name: "n", other: "o"}, schema) == {:ok, %{name: "n", other: "o"}}
  end

  test "empty map of xor fields: missing at least one" do
    schema = [:map, xor: [name: [:string], surname: [:string]]]
    assert Ve.validate(%{}, schema) == {:error, ["at_lease_one_field_must_be_present"]}
    assert Ve.validate(%{other: "o"}, schema) == {:error, ["at_lease_one_field_must_be_present"]}
  end

  test "map of xor fields: more fields are present" do
    schema = [:map, xor: [name: [:string], surname: [:string]]]
    assert Ve.validate(%{name: "n", surname: "k"}, schema) == {:error, ["just_one_field_must_be_present"]}
  end

  test "list contains valid type" do
    schema = [:list, of: [:string]]
    assert Ve.validate(["a", "b"], schema) == {:ok, ["a", "b"]}
  end

  test "list contains min elements" do
    schema = [:list, of: [:string], min: 1]
    assert Ve.validate(["a"], schema) == {:ok, ["a"]}
  end

  test "list does not contains min elements" do
    schema = [:list, of: [:string], min: 1]
    assert Ve.validate([], schema) == {:error, ["min_violation"]}
  end

  test "list contains max elements" do
    schema = [:list, of: [:string], max: 1]
    assert Ve.validate(["a"], schema) == {:ok, ["a"]}
  end

  test "list does not contains max elements" do
    schema = [:list, of: [:string], max: 1]
    assert Ve.validate(["a", "b"], schema) == {:error, ["max_violation"]}
  end

  test "empty list contains valid type" do
    schema = [:list, of: [:string]]
    assert Ve.validate([], schema) == {:ok, []}
  end

  test "list contains invalid type" do
    schema = [:list, of: [:string]]
    assert Ve.validate(["a", 1], schema) == {:error, ["string_expected_got_integer"]}
  end

  test "list contains a valid map" do
    schema = [:list, of: [:map, fields: [name: [:string]]]]
    assert Ve.validate([%{name: "n"}, %{name: "k"}], schema) == {:ok, [%{name: "n"}, %{name: "k"}]}
  end

  test "list contains a invalid map field" do
    schema = [:list, of: [:map, fields: [name: [:string]]]]
    assert Ve.validate([%{name: "n"}, %{name: 1}], schema) == {:error, ["string_expected_got_integer"]}
  end

  test "string must be a fixed value" do
    assert Ve.validate("test1", [:string, value: "test1"]) == {:ok, "test1"}
  end

  test "string can be multiple value" do
    assert Ve.validate("test1", [:string, in: ["test1", "test2"]]) == {:ok, "test1"}
  end

  test "atom can be multiple value" do
    assert Ve.validate(:test1, [:atom, in: [:test1, :test2]]) == {:ok, :test1}
  end

  test "string can be multiple value but invalid" do
    assert Ve.validate("test3", [:string, in: ["test1", "test2"]]) == {:error, ["invalid_possible_value"]}
  end

  test "string can be multiple value but invalid in" do
    assert Ve.validate("test1", [:string, in: "test1"]) == {:error, ["in_should_be_a_list"]}
  end

  test "string is not a fixed value" do
    assert Ve.validate("test1", [:string, value: "test"]) == {:error, ["invalid_fixed_value"]}
  end

  test "integer must be a fixed value" do
    assert Ve.validate(56, [:integer, value: 56]) == {:ok, 56}
  end

  test "integer is not a fixed value" do
    assert Ve.validate(56, [:integer, value: 57]) == {:error, ["invalid_fixed_value"]}
  end

  test "boolean must be a fixed value" do
    assert Ve.validate(true, [:boolean, value: true]) == {:ok, true}
  end

  test "boolean is not a fixed value" do
    assert Ve.validate(true, [:boolean, value: false]) == {:error, ["invalid_fixed_value"]}
  end

  test "string is not empty" do
    assert Ve.validate("a", [:string, :not_empty]) == {:ok, "a"}
  end

  test "empty string is not empty" do
    assert Ve.validate("", [:string, :not_empty]) == {:error, ["string_cannot_be_empty"]}
  end

  test "spaces and tab string is not empty" do
    assert Ve.validate("  \t  \t", [:string, :not_empty]) == {:error, ["string_cannot_be_empty"]}
  end
end
