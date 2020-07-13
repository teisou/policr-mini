defmodule PolicrMini.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias PolicrMini.Bot.{
    StartCommander,
    PingCommander,
    SyncCommander,
    SelfJoinedHandler,
    SelfLeftedHandler,
    UserJoinedHandler,
    NewChatTitleHandler,
    TextHandler,
    VerificationCallbacker
  }

  def start(_type, _args) do
    filters = [
      commanders: [StartCommander, PingCommander, SyncCommander],
      handlers: [
        SelfJoinedHandler,
        SelfLeftedHandler,
        UserJoinedHandler,
        NewChatTitleHandler,
        TextHandler
      ],
      callbackers: [VerificationCallbacker]
    ]

    children = [
      # Start the Ecto repository
      PolicrMini.Repo,
      # Start the Telemetry supervisor
      PolicrMiniWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PolicrMini.PubSub},
      # Start the Endpoint (http/https)
      PolicrMiniWeb.Endpoint
    ]

    bot_children = [
      # 图片供应服务
      PolicrMini.Bot.ImageProvider,
      # 消息清理服务
      PolicrMini.Bot.Cleaner,
      # 拉取更新消息
      PolicrMini.Bot.UpdatePoller,
      # 消费消息的动态主管
      PolicrMini.Bot.Consumer,
      # 过滤器管理器
      {PolicrMini.Bot.FilterManager, filters},
      # 任务调度服务
      PolicrMini.Bot.Scheduler
    ]

    children =
      if PolicrMini.mix_env() == :test,
        do: children,
        else: children ++ bot_children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PolicrMini.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PolicrMiniWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
