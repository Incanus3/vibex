defmodule VibexWeb.SettlementLive.VisualMockup do
  use VibexWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div class="card bg-base-200">
        <div class="card-body">
          <h2 class="card-title">
            <.icon name="hero-building-storefront" class="size-5" /> Settlement Status
          </h2>
          <div class="flex items-center gap-4 mt-2">
            <div
              class="radial-progress text-primary"
              style={"--value: #{stage_progress(@mock_data.stage)}; --size: 5rem; --thickness: 6px;"}
            >
              <div class="text-center">
                <div class="text-lg font-bold">Stage</div>
                <div class="text-2xl font-bold">{@mock_data.stage}</div>
              </div>
            </div>
            <div class="flex-1">
              <div class="text-sm text-base-content/70">Progress to next stage</div>
              <progress class="progress progress-primary w-full" value="35" max="100"></progress>
              <div class="text-xs text-base-content/50 mt-1">35% complete</div>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-200">
        <div class="card-body">
          <h2 class="card-title">
            <.icon name="hero-chart-bar" class="size-5" /> Resource Overview
          </h2>
          <div class="grid grid-cols-3 gap-2 mt-2">
            <.visual_resource
              :for={{resource, amount} <- @mock_data.resources}
              resource={resource}
              amount={amount}
              storage={@mock_data.storage[resource]}
              production={@mock_data.production[resource]}
            />
          </div>
        </div>
      </div>

      <div class="card bg-base-200 md:col-span-2">
        <div class="card-body">
          <h2 class="card-title">
            <.icon name="hero-arrow-trending-up" class="size-5" /> Production Summary
          </h2>
          <div class="flex flex-wrap gap-4 mt-2">
            <div class="stat bg-base-300 rounded-lg p-4 flex-1 min-w-[150px]">
              <div class="stat-title">Total Production</div>
              <div class="stat-value text-success">
                +{Enum.sum(Map.values(@mock_data.production))}
              </div>
              <div class="stat-desc">per turn</div>
            </div>

            <div class="stat bg-base-300 rounded-lg p-4 flex-1 min-w-[150px]">
              <div class="stat-title">Active Resources</div>
              <div class="stat-value text-primary">
                {@mock_data.production |> Enum.count(fn {_, v} -> v > 0 end)}
              </div>
              <div class="stat-desc">of 6 producing</div>
            </div>

            <div class="stat bg-base-300 rounded-lg p-4 flex-1 min-w-[150px]">
              <div class="stat-title">Storage Used</div>
              <div class="stat-value text-info">
                {calculate_total_used(@mock_data.resources)}
              </div>
              <div class="stat-desc">of {calculate_total_storage(@mock_data.storage)} capacity</div>
            </div>
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

  def visual_resource(assigns) do
    percentage = if assigns.storage > 0, do: assigns.amount / assigns.storage * 100, else: 0
    status = get_status(percentage, assigns.production)

    assigns =
      assigns
      |> assign(:percentage, percentage)
      |> assign(:status, status)

    ~H"""
    <div class="relative p-2 rounded-lg bg-base-300">
      <div class="flex items-center justify-between mb-1">
        <.icon name={resource_icon(@resource)} class={"size-4 #{color_class(@resource)}"} />
        <.status_indicator status={@status} />
      </div>
      <div class="text-center">
        <div class="font-mono text-sm">{@amount}</div>
        <div class="text-xs text-base-content/50 capitalize">{@resource}</div>
      </div>
      <div :if={@production > 0} class="absolute -top-1 -right-1 badge badge-xs badge-success">
        +{@production}
      </div>
    </div>
    """
  end

  attr :status, :atom, required: true

  def status_indicator(assigns) do
    ~H"""
    <div class={[
      "w-2 h-2 rounded-full",
      @status == :critical && "bg-error animate-pulse",
      @status == :low && "bg-warning",
      @status == :good && "bg-success",
      @status == :full && "bg-info",
      @status == :idle && "bg-base-content/30"
    ]} />
    """
  end

  defp stage_progress(stage), do: stage * 20

  defp get_status(percentage, production) do
    cond do
      percentage >= 100 -> :full
      percentage >= 80 -> :good
      percentage >= 30 -> :low
      production == 0 -> :idle
      true -> :critical
    end
  end

  defp calculate_total_used(resources), do: Enum.sum(Map.values(resources))
  defp calculate_total_storage(storage), do: Enum.sum(Map.values(storage))

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
