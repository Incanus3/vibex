defmodule VibexWeb.PageController do
  use VibexWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
