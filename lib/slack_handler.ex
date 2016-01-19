defmodule SlackHandler do
  use GenEvent

  @slack_channel Application.get_env(:slack, :channel)
  @user          Application.get_env(:slack, :relay_user)
  @irc_channel   Application.get_env(:irc,   :channel)

  def handle_event({:slack, [channel: chan_name, user: user_name, message: msg, slack: slack]}, state) do
    Agent.update(SlackState, fn (_state) -> slack end)

    if chan_name == @slack_channel && user_name == @user do
      IO.puts msg.text

      irc_client = Agent.get(IRCClient, &(&1))

      case irc_client do
        nil -> IO.puts "Error: irc_client was nil"
        _   -> ExIrc.Client.msg irc_client, :privmsg, @irc_channel, msg.text
      end
    else
      IO.puts "Error: #{chan_name}, #{user_name}"
    end

    {:ok, state}
  end

  def handle_event(message, state) do
    IO.puts "Didn't recognise message"
    {:ok, state}
  end
end
