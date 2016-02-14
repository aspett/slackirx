defmodule Slackirx do
  use Application

  @slack_token Application.get_env(:slackirx, :slack).token
  @irc_channels [ Application.get_env(:slackirx, :irc).channel ]

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Initialize slack events
    {:ok, slack_handler_pid} = GenEvent.start_link()
    GenEvent.add_handler(slack_handler_pid, RelayHandler, [])

    # Initialize IRC
    {:ok, irc_client} = ExIrc.start_client!

    children = [
      worker(SlackBot, [@slack_token, slack_handler_pid]),
      worker(ConnectionHandler, [irc_client]),
      worker(LoginHandler, [irc_client, @irc_channels]),
      worker(IrcHandler, [irc_client]),
      worker(Agent, [fn -> nil end, [name: SlackState]], id: Agent.SlackState),
      worker(Agent, [fn -> irc_client end, [name: IRCClient]], id: Agent.IRCClient)
    ]

    opts = [strategy: :one_for_one, name: Slackirx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
