defmodule Slackirx do
  use Application

  @slack_token Application.get_env(:slack, :token)

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Initialize slack events
    {:ok, slack_handler_pid} = GenEvent.start_link()
    GenEvent.add_handler(slack_handler_pid, SlackHandler, [])

    # Initialize IRC
    {:ok, irc_client} = ExIrc.start_client!

    children = [
      worker(SlackBot, [Application.get_env(:slack, :token), slack_handler_pid]),
      worker(ConnectionHandler, [irc_client]),
      worker(LoginHandler, [irc_client, [Application.get_env(:irc, :channel)]]),
      worker(IrcHandler, [irc_client]),
      worker(Agent, [fn -> nil end, [name: SlackState]], id: Agent.SlackState),
      worker(Agent, [fn -> irc_client end, [name: IRCClient]], id: Agent.IRCClient)
    ]

    opts = [strategy: :one_for_one, name: Slackirx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
