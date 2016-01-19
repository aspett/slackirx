defmodule SlackBot do
  use Slack

  def handle_connect(slack, handler) do
    Agent.update(SlackState, fn(_state) -> slack end)
    {:ok, handler}
  end

  def handle_message(message = %{type: "message"}, slack, handler) do
    group_chan = group_chan_from_id(message.channel, slack)

    unless is_nil(group_chan) do
      notify_handler(handler, group_chan, message, slack)
    end

    {:ok, handler}
  end

  def handle_message(_message, _slack, handler) do
    {:ok, handler}
  end

  def notify_handler(handler, group_chan, message, slack) do
    to_send = [
      channel: group_chan.name,
      user: slack.users[message.user].name,
      message: message,
      slack: slack
    ]

    GenEvent.notify(handler, {:slack, to_send})
  end

  def group_chan_from_id(id, slack) do
    channel = slack.channels[id]
    if is_nil(channel) do
      channel = slack.groups[id]
    end

    channel
  end

  def group_chan_from_name(name, slack) do
    groups_and_channels = Map.merge(slack.channels, slack.groups)
    Enum.find(Map.values(groups_and_channels), fn(map) -> map.name == name end)
  end

  def send_to_slack(message, channel, slack) do
    send_message(message, channel, slack)
  end
end
