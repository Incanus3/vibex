defmodule VibexWeb.SettlementLiveTest do
  use VibexWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Vibex.AccountsFixtures

  describe "SettlementLive Overview page" do
    test "renders settlement overview page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settlement")

      assert html =~ "Settlement Overview"
      assert html =~ "Stage 1"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/settlement")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "displays resource bars and production rates in classic mockup", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settlement")

      html = render(lv)

      for resource <- ~w(gold wood stone food iron crystal) do
        assert html =~ resource, "Expected to see #{resource} resource"
      end

      assert html =~ "500"
      assert html =~ "1000"
      assert html =~ "+5"
      assert html =~ "+10"
      assert html =~ "+8"
      assert html =~ "+12"
    end

    test "displays production rates section", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settlement")

      html = render(lv)

      assert html =~ "Production Rates"
      assert html =~ "/turn"
    end

    test "displays stage indicator", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settlement")

      html = render(lv)

      assert html =~ "Stage 1"
    end

    test "can switch between mockup styles", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settlement")

      html = render(lv)

      assert html =~ "Classic"
      assert html =~ "Dashboard"
      assert html =~ "Compact"
      assert html =~ "Detailed"
      assert html =~ "Visual"

      lv
      |> element("button[phx-value-style='dashboard']")
      |> render_click()

      html = render(lv)
      assert html =~ "btn-active"
    end

    test "switches to dashboard mockup", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settlement")

      lv
      |> element("button[phx-value-style='dashboard']")
      |> render_click()

      html = render(lv)
      assert html =~ "radial-progress"
    end

    test "switches to compact mockup", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settlement")

      lv
      |> element("button[phx-value-style='compact']")
      |> render_click()

      html = render(lv)
      assert html =~ "Stage 1"
    end

    test "switches to detailed mockup", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settlement")

      lv
      |> element("button[phx-value-style='detailed']")
      |> render_click()

      html = render(lv)
      assert html =~ "Resource Details"
      assert html =~ "Storage"
      assert html =~ "Production"
    end

    test "switches to visual mockup", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/settlement")

      lv
      |> element("button[phx-value-style='visual']")
      |> render_click()

      html = render(lv)
      assert html =~ "Settlement Status"
      assert html =~ "Production Summary"
    end
  end
end
