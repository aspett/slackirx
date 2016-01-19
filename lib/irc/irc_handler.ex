defmodule IrcHandler do
  def start_link(client) do
    GenServer.start_link(__MODULE__, [client])
  end

  def init([client]) do
    ExIrc.Client.add_handler client, self
    {:ok, client}
  end

  def handle_info({:connected, server, port}, _state) do
    debug "Connected to #{server}:#{port}"
    {:noreply, nil}
  end

  def handle_info(:logged_in, _state) do
    debug "Logged in to server"
    {:noreply, nil}
  end

  def handle_info(:disconnected, _state) do
    debug "Disconnected from server"
    {:noreply, nil}
  end

  def handle_info({:joined, channel}, _state) do
    debug "Joined #{channel}"
    {:noreply, nil}
  end

  def handle_info({:joined, channel, user}, _state) do
    debug "#{user} joined #{channel}"
    {:noreply, nil}
  end

  def handle_info({:topic_changed, channel, topic}, _state) do
    debug "#{channel} topic changed to #{topic}"
    {:noreply, nil}
  end

  def handle_info({:nick_changed, nick}, _state) do
    debug "We changed our nick to #{nick}"
    {:noreply, nil}
  end

  def handle_info({:nick_changed, old_nick, new_nick}, _state) do
    debug "#{old_nick} changed their nick to #{new_nick}"
    {:noreply, nil}
  end

  def handle_info({:parted, channel}, _state) do
    debug "We left #{channel}"
    {:noreply, nil}
  end

  def handle_info({:parted, channel, nick}, _state) do
    debug "#{nick} left #{channel}"
    {:noreply, nil}
  end

  def handle_info({:invited, by, channel}, _state) do
    debug "#{by} invited us to #{channel}"
    {:noreply, nil}
  end

  def handle_info({:kicked, by, channel}, _state) do
    debug "We were kicked from #{channel} by #{by}"
    {:noreply, nil}
  end

  def handle_info({:kicked, nick, by, channel}, _state) do
    debug "#{nick} was kicked from #{channel} by #{by}"
    {:noreply, nil}
  end

  def handle_info({:received, message, from}, _state) do
    debug "#{from} sent us a private message: #{message}"
    {:noreply, nil}
  end

  def handle_info({:received, message, from, channel}, state) do
    debug "#{from} sent a message to #{channel}: #{message}"

    Agent.get(SlackState, fn (slack) ->
      if !is_nil(slack) do
        SlackBot.send_to_slack(
          "#{from}: #{message}",
          SlackBot.group_chan_from_name("slackirx_actgimjawa", slack).id,
          slack
        )
      else
        debug "Error: Slack state nil"
      end
    end)
    {:noreply, nil}
  end

  def handle_info({:mentioned, message, from, channel}, _state) do
    debug "#{from} mentioned us in #{channel}: #{message}"
    {:noreply, nil}
  end

  def handle_info({:me, message, from, channel}, _state) do
    debug "* #{from} #{message} in #{channel}"
    {:noreply, nil}
  end

  # This is an example of how you can manually catch commands if ExIrc.Client doesn't send a specific message for it
  def handle_info(%IrcMessage{:nick => from, :cmd => "PRIVMSG", :args => ["testnick", msg]}, _state) do
    debug "Received a private message from #{from}: #{msg}"
    {:noreply, nil}
  end

  def handle_info(%IrcMessage{:nick => from, :cmd => "PRIVMSG", :args => [to, msg]}, _state) do
    debug "Received a message in #{to} from #{from}: #{msg}"
    {:noreply, nil}
  end

  # Catch-all for messages you don't care about
  def handle_info(msg, _state) do
    debug "Received Unrecognised IrcMessage:"
    IO.inspect msg
    {:noreply, nil}
  end

  defp debug(msg) do
    IO.puts IO.ANSI.yellow() <> msg <> IO.ANSI.reset()
  end
end
