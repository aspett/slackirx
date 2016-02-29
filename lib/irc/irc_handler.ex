defmodule IrcHandler do
  def start_link(client, relay_handler_pid) do
    GenServer.start_link(__MODULE__, [client, relay_handler_pid])
  end

  def init(state = [client, _relay_handler_pid]) do
    ExIrc.Client.add_handler client, self
    {:ok, state}
  end

  def handle_info({:connected, server, port}, state = [_client, handler]) do
    GenEvent.notify(handler, {:irc, {:info, "*** Connected to server"}})
    debug "Connected to #{server}:#{port}"
    {:noreply, state}
  end

  def handle_info(:logged_in, state) do
    debug "Logged in to server"
    {:noreply, state}
  end

  def handle_info(:disconnected, state = [_client, handler]) do
    GenEvent.notify(handler, {:irc, {:info, "*** Disconnected from server"}})
    debug "Disconnected from server"
    {:noreply, state}
  end

  def handle_info({:joined, channel}, state) do
    debug "Joined #{channel}"
    {:noreply, state}
  end

  def handle_info({:joined, channel, user}, state) do
    debug "#{user} joined #{channel}"
    {:noreply, state}
  end

  def handle_info({:topic_changed, channel, topic}, state) do
    debug "#{channel} topic changed to #{topic}"
    {:noreply, state}
  end

  def handle_info({:nick_changed, nick}, state) do
    debug "We changed our nick to #{nick}"
    {:noreply, state}
  end

  def handle_info({:nick_changed, old_nick, new_nick}, state) do
    debug "#{old_nick} changed their nick to #{new_nick}"
    {:noreply, state}
  end

  def handle_info({:parted, channel}, state) do
    debug "We left #{channel}"
    {:noreply, state}
  end

  def handle_info({:parted, channel, nick}, state) do
    debug "#{nick} left #{channel}"
    {:noreply, state}
  end

  def handle_info({:invited, by, channel}, state) do
    debug "#{by} invited us to #{channel}"
    {:noreply, state}
  end

  def handle_info({:kicked, by, channel}, state) do
    debug "We were kicked from #{channel} by #{by}"
    {:noreply, state}
  end

  def handle_info({:kicked, nick, by, channel}, state) do
    debug "#{nick} was kicked from #{channel} by #{by}"
    {:noreply, state}
  end

  def handle_info({:received, message, from}, state) do
    debug "#{from} sent us a private message: #{message}"
    {:noreply, state}
  end

  def handle_info({:received, message, from, channel}, state = [_client, handler]) do
    GenEvent.notify(handler, {:irc, {:message, message, from, channel}})
    {:noreply, state}
  end

  def handle_info({:mentioned, message, from, channel}, state) do
    debug "#{from} mentioned us in #{channel}: #{message}"
    {:noreply, state}
  end

  def handle_info({:me, message, from, channel}, state) do
    GenEvent.notify(handler, {:irc, {:message, "*me #{message}", from, channel}})
    debug "* #{from} #{message} in #{channel}"
    {:noreply, state}
  end

  # This is an example of how you can manually catch commands if ExIrc.Client doesn't send a specific message for it
  def handle_info(%IrcMessage{:nick => from, :cmd => "PRIVMSG", :args => ["testnick", msg]}, state) do
    debug "Received a private message from #{from}: #{msg}"
    {:noreply, state}
  end

  def handle_info(%IrcMessage{:nick => from, :cmd => "PRIVMSG", :args => [to, msg]}, state) do
    debug "Received a message in #{to} from #{from}: #{msg}"
    {:noreply, state}
  end

  # Catch-all for messages you don't care about
  def handle_info(msg, state) do
    debug "Received Unrecognised IrcMessage:"
    IO.inspect msg
    {:noreply, state}
  end

  defp debug(msg) do
    IO.puts IO.ANSI.yellow() <> msg <> IO.ANSI.reset()
  end
end
