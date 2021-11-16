defmodule PingPongWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  @doc """
  Renders a component inside the `PingPongWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal PingPongWeb.ScoreLive.FormComponent,
        id: @score.id || :new,
        action: @live_action,
        score: @score,
        return_to: Routes.score_index_path(@socket, :index) %>
  """
  def live_modal(component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(PingPongWeb.ModalComponent, modal_opts)
  end

  def humanize_list(list, fun) do
    count = length(list)

    for {item, index} <- Enum.with_index(list, 1), reduce: "" do
      acc ->
        case index do
          x when x == count ->
            acc <> fun.(item)

          x when x == count - 1 ->
            acc <> fun.(item) <> " en "

          _ ->
            acc <> fun.(item) <> ", "
        end
    end
  end
end
