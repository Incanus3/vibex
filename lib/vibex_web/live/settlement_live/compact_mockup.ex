defmodule VibexWeb.SettlementLive.CompactMockup do
  use VibexWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="card bg-base-200">
      <div class="card-body p-4">
        <div class="flex flex-wrap items-center gap-4">
          <div class="badge badge-lg badge-primary">
            Stage {@mock_data.stage}
          </div>

          <div class="flex flex-wrap gap-2">
            <.compact_resource
              :for={{resource, amount} <- @mock_data.resources}
              resource={resource}
              amount={amount}
              storage={@mock_data.storage[resource]}
              production={@mock_data.production[resource]}
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

  def compact_resource(assigns) do
    percentage = if assigns.storage > 0, do: assigns.amount / assigns.storage * 100, else: 0

    assigns = assign(assigns, :percentage, percentage)

    ~H"""
    <div class="tooltip" data-tip={"#{@amount}/#{@storage} (+#{@production}/turn)"}>
      <div class="flex items-center gap-1 px-2 py-1 rounded bg-base-300">
        <.icon name={resource_icon(@resource)} class={"size-4 #{color_class(@resource)}"} />
        <span class="font-mono text-sm">{@amount}</span>
        <span class="text-xs text-base-content/50">/{@storage}</span>
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
end
