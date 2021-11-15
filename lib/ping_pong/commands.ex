defmodule PingPong.Commands do
  defmodule Report do
    use Ecto.Schema

    embedded_schema do
      field :left_id, :string
      field :right_id, :string

      embeds_many :scores, Score do
        field :left, :integer
        field :right, :integer
      end
    end
  end

  defmodule DoublesReport do
    use Ecto.Schema

    embedded_schema do
      field :left_id, :string
      field :left_id_buddy, :string
      field :right_id, :string
      field :right_id_buddy, :string

      embeds_many :scores, Score do
        field :left, :integer
        field :right, :integer
      end
    end
  end
end
