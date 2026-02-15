defmodule VibexWeb.SettlementLive.ClassicMockup do
  use VibexWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="card bg-base-200">
        <div class="card-body">
          <h2 class="card-title">Resources</h2>
          <div class="space-y-3">
            <.resource_bar
              :for={{resource, amount} <- @mock_data.resources}
              resource={resource}
              amount={amount}
              storage={@mock_data.storage[resource]}
              production={@mock_data.production[resource]}
            />
          </div>
        </div>
      </div>

      <div class="card bg-base-200">
        <div class="card-body">
          <h2 class="card-title">Production Rates</h2>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-2">
            <.production_rate
              :for={{resource, rate} <- @mock_data.production}
              resource={resource}
              rate={rate}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :resource, :atom, required: true
  attr :amount, :integer, required: true
  attr :storage, :integer, required: true
  attr :production, :integer, required: true

  def resource_bar(assigns) do
    percentage = if assigns.storage > 0, do: assigns.amount / assigns.storage * 100, else: 0

    assigns = assign(assigns, :percentage, percentage)

    ~H"""
    <div>
      <div class="flex justify-between text-sm mb-1">
        <span class="font-medium capitalize">{@resource}</span>
        <span>{@amount} / {@storage}</span>
      </div>
      <progress
        class={"progress #{@resource |> to_color()}"}
        value={@amount}
        max={@storage}
      >
      </progress>
      <div class="text-xs text-base-content/60 mt-1">
        +{@production}/turn
      </div>
    </div>
    """
  end

  attr :resource, :atom, required: true
  attr :rate, :integer, required: true

  def production_rate(assigns) do
    ~H"""
    <div class="flex items-center gap-2 p-2 rounded bg-base-300">
      <.icon name={resource_icon(@resource)} class="size-5" />
      <div>
        <div class="text-sm capitalize">{@resource}</div>
        <div class={"text-xs #{@rate > 0 && "text-success" || "text-base-content/50"}"}>
          +{@rate}/turn
        </div>
      </div>
    </div>
    """
  end

  defp to_color(:gold), do: "progress-warning"
  defp to_color(:wood), do: "progress-success"
  defp to_color(:stone), do: "progress-neutral"
  defp to_color(:food), do: "progress-info"
  defp to_color(:iron), do: "progress-secondary"
  defp to_color(:crystal), do: "progress-primary"
  defp to_color(_), do: "progress-neutral"

  defp resource_icon(:gold), do: "hero-currency-dollar"
  defp resource_icon(:wood), do: "hero-cube"
  defp resource_icon(:stone), do: "hero-cube-transparent"
  defp resource_icon(:food), do: "hero-cake"
  defp resource_icon(:iron), do: "hero-cog"
  defp resource_icon(:crystal), do: "hero-sparkles"
  defp resource_icon(_), do: "hero-question-mark-circle"
end
