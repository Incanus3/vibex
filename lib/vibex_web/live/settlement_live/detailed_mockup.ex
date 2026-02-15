defmodule VibexWeb.SettlementLive.DetailedMockup do
  use VibexWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="card bg-base-200">
      <div class="card-body">
        <h2 class="card-title">Resource Details</h2>

        <div class="overflow-x-auto">
          <table class="table">
            <thead>
              <tr>
                <th>Resource</th>
                <th class="text-right">Amount</th>
                <th class="text-right">Storage</th>
                <th class="text-right">Fill %</th>
                <th class="text-right">Production</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <.resource_row
                :for={{resource, amount} <- @mock_data.resources}
                resource={resource}
                amount={amount}
                storage={@mock_data.storage[resource]}
                production={@mock_data.production[resource]}
              />
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  attr :resource, :atom, required: true
  attr :amount, :integer, required: true
  attr :storage, :integer, required: true
  attr :production, :integer, required: true

  def resource_row(assigns) do
    percentage = if assigns.storage > 0, do: assigns.amount / assigns.storage * 100, else: 0

    assigns =
      assigns
      |> assign(:percentage, percentage)
      |> assign(:status, get_status(percentage, assigns.production))

    ~H"""
    <tr>
      <td>
        <div class="flex items-center gap-2">
          <.icon name={resource_icon(@resource)} class={"size-5 #{color_class(@resource)}"} />
          <span class="capitalize font-medium">{@resource}</span>
        </div>
      </td>
      <td class="text-right font-mono">{@amount}</td>
      <td class="text-right font-mono">{@storage}</td>
      <td class="text-right">
        <div class="flex items-center justify-end gap-2">
          <progress
            class={"progress progress-xs w-16 #{@resource |> progress_color(@percentage)}"}
            value={@amount}
            max={@storage}
          >
          </progress>
          <span class="font-mono text-sm">{trunc(@percentage)}%</span>
        </div>
      </td>
      <td class="text-right font-mono">
        <span class={"#{@production > 0 && "text-success" || "text-base-content/50"}"}>
          +{@production}/turn
        </span>
      </td>
      <td>
        <.status_badge status={@status} />
      </td>
    </tr>
    """
  end

  attr :status, :atom, required: true

  def status_badge(assigns) do
    ~H"""
    <div class={[
      "badge badge-sm",
      @status == :critical && "badge-error",
      @status == :low && "badge-warning",
      @status == :good && "badge-success",
      @status == :full && "badge-info",
      @status == :idle && "badge-ghost"
    ]}>
      {status_text(@status)}
    </div>
    """
  end

  defp get_status(percentage, production) do
    cond do
      percentage >= 100 -> :full
      percentage >= 80 -> :good
      percentage >= 30 -> :low
      production == 0 -> :idle
      true -> :critical
    end
  end

  defp status_text(:full), do: "Full"
  defp status_text(:good), do: "Good"
  defp status_text(:low), do: "Low"
  defp status_text(:critical), do: "Critical"
  defp status_text(:idle), do: "No Production"

  defp progress_color(:gold, p) when p >= 80, do: "progress-warning"
  defp progress_color(:wood, p) when p >= 80, do: "progress-success"
  defp progress_color(:stone, p) when p >= 80, do: "progress-neutral"
  defp progress_color(:food, p) when p >= 80, do: "progress-info"
  defp progress_color(:iron, p) when p >= 80, do: "progress-secondary"
  defp progress_color(:crystal, p) when p >= 80, do: "progress-primary"
  defp progress_color(_, p) when p >= 50, do: "progress-primary"
  defp progress_color(_, _), do: "progress-error"

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
