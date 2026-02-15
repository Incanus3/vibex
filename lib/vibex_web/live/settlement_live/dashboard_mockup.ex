defmodule VibexWeb.SettlementLive.DashboardMockup do
  use VibexWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
      <.resource_card
        :for={{resource, amount} <- @mock_data.resources}
        resource={resource}
        amount={amount}
        storage={@mock_data.storage[resource]}
        production={@mock_data.production[resource]}
      />
    </div>
    """
  end

  attr :resource, :atom, required: true
  attr :amount, :integer, required: true
  attr :storage, :integer, required: true
  attr :production, :integer, required: true

  def resource_card(assigns) do
    percentage = if assigns.storage > 0, do: assigns.amount / assigns.storage * 100, else: 0

    assigns = assign(assigns, :percentage, percentage)

    ~H"""
    <div class="card bg-base-200 shadow-sm">
      <div class="card-body p-4">
        <div class="flex items-center justify-between mb-2">
          <.icon name={resource_icon(@resource)} class={"size-6 #{color_class(@resource)}"} />
          <span class="badge badge-sm badge-ghost">
            Stage {@resource |> stage_indicator(@amount, @storage)}
          </span>
        </div>

        <div class="text-center">
          <div class="text-2xl font-bold">{@amount}</div>
          <div class="text-xs text-base-content/60 capitalize">{@resource}</div>
        </div>

        <div class="mt-2">
          <div
            class="radial-progress mx-auto"
            style={"--value: #{trunc(@percentage)}; --size: 3rem; --thickness: 4px;"}
          >
            <span class="text-xs">{trunc(@percentage)}%</span>
          </div>
        </div>

        <div class="text-center text-xs mt-2">
          <span class={"#{@production > 0 && "text-success" || "text-base-content/40"}"}>
            +{@production}/turn
          </span>
          <span class="text-base-content/40 ml-1">/ {@storage} max</span>
        </div>
      </div>
    </div>
    """
  end

  defp resource_icon(:gold), do: "hero-currency-dollar"
  defp resource_icon(:wood), do: "hero-cube"
  defp resource_icon(:stone), do: "hero-cube-transparent"
  defp resource_icon(:food), do: "hero-cake"
  defp resource_icon(:iron), do: "hero-cog"
  defp resource_icon(:crystal), do: "hero-sparkles"
  defp resource_icon(_), do: "hero-question-mark-circle"

  defp color_class(:gold), do: "text-warning"
  defp color_class(:wood), do: "text-success"
  defp color_class(:stone), do: "text-neutral"
  defp color_class(:food), do: "text-info"
  defp color_class(:iron), do: "text-secondary"
  defp color_class(:crystal), do: "text-primary"
  defp color_class(_), do: "text-base-content"

  defp stage_indicator(_resource, amount, storage) do
    percentage = if storage > 0, do: amount / storage * 100, else: 0

    cond do
      percentage >= 80 -> "!"
      percentage >= 50 -> "-"
      true -> "."
    end
  end
end
