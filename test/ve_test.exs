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
    {"float", :is_float, valid: 1.1, invalid: {"a", "float_expected_got_bitstring"}},
    {"function", :is_function, valid: &Kernel.is_string/1, invalid: {51, "function_expected_got_integer"}},
    {"binary", :is_binary, valid: <<0, 1, 2>>, invalid: {51, "binary_expected_got_integer"}},
    # {"pid", :is_pid, valid: :c.pid(0, 250, 0), invalid: {51, "pid_expected_got_integer"}},
    # {"port", :is_port, valid: "test", invalid: {51, "string_expected_got_integer"}},
    # {"reference", :is_reference, valid: "test", invalid: {51, "string_expected_got_integer"}},
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

  test "list contains valid type" do
    schema = [:is_list, of: [:is_string]]
    assert Ve.validate(["a", "b"], schema) == {:ok, ["a", "b"]}
  end

  test "empty list contains valid type" do
    schema = [:is_list, of: [:is_string]]
    assert Ve.validate([], schema) == {:ok, []}
  end

  test "list contains invalid type" do
    schema = [:is_list, of: [:is_string]]
    assert Ve.validate(["a", 1], schema) == {:error, ["string_expected_got_integer"]}
  end

  test "list contains a valid map" do
    schema = [:is_list, of: [:is_map, fields: [name: [:is_string]]]]
    assert Ve.validate([%{name: "n"}, %{name: "k"}], schema) == {:ok, [%{name: "n"}, %{name: "k"}]}
  end

  test "list contains a invalid map field" do
    schema = [:is_list, of: [:is_map, fields: [name: [:is_string]]]]
    assert Ve.validate([%{name: "n"}, %{name: 1}], schema) == {:error, ["string_expected_got_integer"]}
  end

  test "list contains a valid map of of xor fields" do
    schema = [:is_list, of: [:is_map, xor_fields: [name: [:is_string], surname: [:is_string]]]]
    assert Ve.validate([%{name: "n"}, %{surname: "k"}], schema) == {:ok, [%{name: "n"}, %{surname: "k"}]}
  end

  test "empty list contains a valid map of xor fields" do
    schema = [:is_list, of: [:is_map, xor_fields: [name: [:is_string], surname: [:is_string]]]]
    assert Ve.validate([], schema) == {:ok, []}
  end

  test "list contains a valid map of xor fields: more fields are present" do
    schema = [:is_list, of: [:is_map, xor_fields: [name: [:is_string], surname: [:is_string]]]]
    assert Ve.validate([%{name: "n", surname: "k"}], schema) == {:error, ["just_one_field_must_be_present"]}
  end

  test "list contains a valid map of of xor fields: missing at least one" do
    schema = [:is_list, of: [:is_map, xor_fields: [name: [:is_string], surname: [:is_string]]]]
    assert Ve.validate([%{}], schema) == {:error, ["at_lease_one_field_must_be_present"]}
  end
end
