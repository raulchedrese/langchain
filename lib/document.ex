defmodule LangChain.Document do
  defstruct [:title, :content, :metadata]

  def new(title, content, metadata \\ %{}) do
    %__MODULE__{title: title, content: content, metadata: metadata}
  end
end
