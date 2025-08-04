defmodule LangChain.Document do
  defstruct [:content, :metadata]

  def new(content, metadata \\ %{}) do
    %__MODULE__{content: content, metadata: metadata}
  end
end
