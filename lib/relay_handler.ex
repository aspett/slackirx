defmodule RelayHandler do
  use GenEvent

  @slack_channel Application.get_env(:slackirx, :slack).channel
  @user          Application.get_env(:slackirx, :slack).relay_user
  @irc_channel   Application.get_env(:slackirx, :irc).channel

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

  def handle_event({:irc, {:message, message, from, channel}}, state) do
    debug "#{from} sent a message to #{channel}: #{message}"

    Agent.get(SlackState, fn (slack) ->
      if !is_nil(slack) do
        SlackBot.send_to_slack(
          "#{from}: #{message}",
          SlackBot.group_chan_from_name(Application.get_env(:slackirx, :slack).channel, slack).id,
          slack
        )
      else
        debug "Error: Slack state nil"
      end
    end)

    {:ok, state}
  end

  def handle_event({:irc, {:info, message}}) do
    Agent.get(SlackState, fn (slack) ->
      if !is_nil(slack) do
        SlackBot.send_to_slack(
          message,
          SlackBot.group_chan_from_name(Application.get_env(:slackirx, :slack).channel, slack).id,
          slack
        )
      end
    )
  end

  def handle_event(message, state) do
    IO.puts "Didn't recognise message"
    {:ok, state}
  end

  defp debug(msg) do
    IO.puts IO.ANSI.yellow() <> msg <> IO.ANSI.reset()
  end
end
