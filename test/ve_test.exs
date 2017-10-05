defmodule VeTest do
  use ExUnit.Case
  doctest Ve

  valid_types = [
    {"string", :is_string, valid: "test", invalid: {51, "51_is_not_string"}},
    {"integer", :is_integer, valid: 51, invalid: {"test", "test_is_not_integer"}},
    {"atom", :is_atom, valid: :my_atom, invalid: {"test", "test_is_not_atom"}},
    {"list", :is_list, valid: [51, 52], invalid: {"test", "test_is_not_list"}},
    {"map", :is_map, valid: %{}, invalid: {"test", "test_is_not_map"}},
    {"tuple", :is_tuple, valid: {}, invalid: {"test", "test_is_not_tuple"}},
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
    assert Ve.validate("some data", [:is_string, pattern: "data"]) == {:ok, "some data"}
  end

  test "apply pattern to invalid string" do
    assert Ve.validate("some doto", [:is_string, pattern: "data"]) == {:error, ["pattern_not_matched"]}
  end

  test "apply invalid pattern to string" do
    assert Ve.validate("some data", [:is_string, pattern: "("]) == {:error, ["invalid_regex_pattern: missing )"]}
  end
end
