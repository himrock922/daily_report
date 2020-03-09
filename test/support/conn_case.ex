defmodule WeReportsWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use WeReportsWeb.ConnCase, async: true`, although
  this option is not recommendded for other databases.
  """
  use ExUnit.CaseTemplate
  alias WeReports.{UserManager, UserManager.Guardian}

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      alias WeReportsWeb.Router.Helpers, as: Routes
      # The default endpoint for testing
      @endpoint WeReportsWeb.Endpoint
    end
  end

  @default_opts [
    store: :cookie,
    key: "secretkey",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt"
  ]
  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))
  @valid_user %{password: "some password", username: "some username"}

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(WeReports.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(WeReports.Repo, {:shared, self()})
    end

    {conn} = if tags[:authenticated] do
      {:ok, user} = UserManager.create_user(@valid_user)

      conn = Phoenix.ConnTest.build_conn()
      |> Plug.Session.call(@signing_opts)
      |> Plug.Conn.fetch_session
      |> Guardian.Plug.sign_in(user)
      {conn}
    else
      {Phoenix.ConnTest.build_conn()}
    end

    {:ok, conn: conn}
  end
end
