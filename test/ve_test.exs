defmodule VeTest do
  use ExUnit.Case
  doctest Ve

  valid_types = [
    {"string", :is_string, valid: "test", invalid: {51, "string_expected_got_integer"}},
    {"integer", :is_integer, valid: 51, invalid: {"test", "integer_expected_got_bitstring"}},
    {"atom", :is_atom, valid: :my_atom, invalid: {"test", "atom_expected_got_bitstring"}},
    {"list", :is_list, valid: [51, 52], invalid: {"test", "list_expected_got_bitstring"}},
    {"map", :is_map, valid: %{}, invalid: {"test", "map_expected_got_bitstring"}},
    {"tuple", :is_tuple, valid: {}, invalid: {"test", "tuple_expected_got_bitstring"}},
    {"boolean", :is_boolean, valid: true, invalid: {"test", "boolean_expected_got_bitstring"}},
  ]

  Enum.each valid_types, fn {name, type, [valid: valid_data, invalid: {invalid_data, invalid_data_message}]} ->
    test "type #{name} is valid" do
      type = unquote(type)
      data = unquote(valid_data |> Macro.escape)

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
      assert Ve.validate(nil, [type, :nullable]) == {:ok, nil }
    end

    test "type #{name} is nil but not nullable" do
      type = unquote(type)
      assert Ve.validate(nil, [type]) == {:error, ["cannot_be_nullable"]}
    end
  end

  test "unknown type" do
    assert Ve.validate("some data", []) == {:error, ["unknown_type"]}
  end

  test "apply pattern to string" do
    assert Ve.validate("some data", [:is_string, pattern: ~r/data/]) == {:ok, "some data"}
  end

  test "apply pattern to invalid string" do
    assert Ve.validate("some doto", [:is_string, pattern: ~r/data/]) == {:error, ["pattern_not_matched"]}
  end

  test "min integer" do
    assert Ve.validate(5, [:is_integer, min: 4]) == {:ok, 5}
  end

  test "min integer violated" do
    assert Ve.validate(5, [:is_integer, min: 6]) == {:error, ["min_violation"]}
  end

  test "max integer" do
    assert Ve.validate(5, [:is_integer, max: 6]) == {:ok, 5}
  end

  test "max integer violated" do
    assert Ve.validate(5, [:is_integer, max: 4]) == {:error, ["max_violation"]}
  end

  test "missing field in map" do
    assert Ve.validate(%{}, [:is_map, fields: [name: [:is_string]]]) == {:error, ["missing_field_name"]}
  end

  test "map contains a field" do
    assert Ve.validate(%{field: "field"}, [:is_map, fields: [field: [:is_string]]]) == {:ok, %{field: "field"}}
  end

  test "map contains a field with invalid type" do
    assert Ve.validate(%{field: "field"}, [:is_map, fields: [field: [:is_integer]]]) == {:error, ["integer_expected_got_bitstring"]}
  end

  test "map contains some fields with invalid type" do
    schema = [:is_map, fields: [name: [:is_string], surname: [:is_string]]]
    assert Ve.validate(%{name: 52, surname: 54}, schema) == {:error, ["string_expected_got_integer", "string_expected_got_integer"]}
  end

  test "map contains an invalid field and a missing field" do
    schema = [:is_map, fields: [name: [:is_string], surname: [:is_string]]]
    assert Ve.validate(%{name: 52}, schema) == {:error, ["string_expected_got_integer", "missing_field_surname"]}
  end

  test "map contains some optional fields" do
    schema = [:is_map, fields: [name: [:is_string], surname: [:is_string, :optional]]]
    assert Ve.validate(%{name: "f1"}, schema) == {:ok, %{name: "f1"}}
  end

  test "map contains invalid field type" do
    schema = [:is_map, fields: [name: [:is_string]]]
    assert Ve.validate(%{name: %{n: "n", s: "s"}}, schema) == {:error, ["string_expected_got_map"]}
  end
end
