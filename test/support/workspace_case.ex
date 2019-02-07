defmodule Olap.WorkspaceCase do
  use ExUnit.CaseTemplate

  setup do
    {:ok, config} = Olap.Application.config()
    {:ok, workspace} = Olap.Workspace.start_link([{:global, make_ref()}, config])
    {:ok, workspace: workspace}
  end
end
