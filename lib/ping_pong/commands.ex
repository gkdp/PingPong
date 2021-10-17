defmodule PingPong.Commands do

  defmodule Report do
    use Ecto.Schema

    embedded_schema do
      field :left_id, :string
      field :right_id, :string
      field :left, :integer
      field :right, :integer
    end
  end
end
