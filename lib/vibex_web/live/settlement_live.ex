defmodule VibexWeb.SettlementLive do
  use VibexWeb, :live_view

  @mockup_styles ~w(classic dashboard compact detailed visual)a

  @mock_data %{
    resources: %{gold: 500, wood: 300, stone: 200, food: 400, iron: 0, crystal: 0},
    storage: %{gold: 1000, wood: 1000, stone: 1000, food: 1000, iron: 500, crystal: 500},
    production: %{gold: 5, wood: 10, stone: 8, food: 12, iron: 0, crystal: 0},
    stage: 1
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, mockup_style: :classic, mock_data: @mock_data)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Settlement Overview
        <:subtitle>Stage {@mock_data.stage}</:subtitle>
      </.header>

      <div class="mb-4 flex flex-wrap gap-2">
        <.mockup_button
          :for={style <- @available_styles}
          style={style}
          current={@mockup_style}
          phx-click="set_style"
          phx-value-style={style}
        />
      </div>

      <div class="mockup-container">
        <%= case @mockup_style do %>
          <% :classic -> %>
            <.live_component
              module={VibexWeb.SettlementLive.ClassicMockup}
              id="classic-mockup"
              mock_data={@mock_data}
            />
          <% :dashboard -> %>
            <.live_component
              module={VibexWeb.SettlementLive.DashboardMockup}
              id="dashboard-mockup"
              mock_data={@mock_data}
            />
          <% :compact -> %>
            <.live_component
              module={VibexWeb.SettlementLive.CompactMockup}
              id="compact-mockup"
              mock_data={@mock_data}
            />
          <% :detailed -> %>
            <.live_component
              module={VibexWeb.SettlementLive.DetailedMockup}
              id="detailed-mockup"
              mock_data={@mock_data}
            />
          <% :visual -> %>
            <.live_component
              module={VibexWeb.SettlementLive.VisualMockup}
              id="visual-mockup"
              mock_data={@mock_data}
            />
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :style, :atom, required: true
  attr :current, :atom, required: true
  attr :rest, :global

  def mockup_button(assigns) do
    ~H"""
    <button
      class={["btn btn-sm", @style == @current && "btn-active"]}
      {@rest}
    >
      {String.capitalize(Atom.to_string(@style))}
    </button>
    """
  end

  @impl true
  def handle_event("set_style", %{"style" => style}, socket) do
    {:noreply, assign(socket, mockup_style: String.to_existing_atom(style))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, available_styles: @mockup_styles)}
  end
end
