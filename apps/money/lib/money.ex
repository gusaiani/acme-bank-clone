defmodule Money do
  @moduledoc ~S"""
  `Money` represents some monetary value (stored in cents) in a given currency.

  See `Money.Ecto` for a custom type implementation that can be used in schemas.

  In order to use the `~M` sigil, import the module:

      import Money

  ## Examples

      iex> Money.new("10.00 USD")
      ~M"10.00 USD"

      iex> ~M"10.00 USD".currency
      "USD"
      iex> ~M"10.01 USD".cents
      1001

      iex> Money.add(~M"10 USD", ~M"20 USD")
      ~M"30.00 USD"

      iex> Kernel.to_string(~M"10 USD")
      "10.00 USD"

      iex> inspect(~M"10 USD")
      "~M\"10.00 USD\""

      iex> Money.parse("10 USD")
      {:ok, ~M"10 USD"}
      iex> Money.parse("10.1 USD")
      {:error, :invalid_cents}

      iex> ~M"10.001 USD"
      ** (ArgumentError) invalid_cents

  """

  defstruct cents: 0, currency: nil

  def new(str) when is_binary(str) do
    case parse(str) do
      {:ok, money} -> money
      {:error, reason} -> raise ArgumentError, "#{reason}"
    end
  end

  def parse(str) when is_binary(str) do
    [value, currency] = String.split(str, " ")

    {dollars, cents} =
      case String.split(value, ".") do
        [dollars, cents] -> {dollars, cents}
        [dollars] -> {dollars, "00"}
      end

    cond do
      String.length(cents) != 2 ->
        {:error, :invalid_cents}

      String.length(currency) != 3 ->
        {:error, :invalid_currency}

      true ->
        cents = String.to_integer(dollars) * 100 + String.to_integer(cents)
        {:ok, %Money{cents: cents, currency: currency}}
    end
  end

  def sigil_M(str, _opts) do
    new(str)
  end

  def add(%Money{cents: left_cents, currency: currency},
          %Money{cents: right_cents, currency: currency}) do
    %Money{cents: left_cents + right_cents, currency: currency}
  end

  def to_string(%Money{cents: cents, currency: currency}) do
    {dollars, cents} = {div(cents, 100), rem(cents, 100)}
    cents = :io_lib.format("~2..0B", [cents]) |> IO.iodata_to_binary
    "#{dollars}.#{cents} #{currency}"
  end
end

defimpl Inspect, for: Money do
  def inspect(money, _opts) do
    "~M\"#{money}\""
  end
end

defimpl String.Chars, for: Money do
  defdelegate to_string(data), to: Money
end
