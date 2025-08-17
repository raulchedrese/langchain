defmodule LangChain.EmbeddingModels.EmbeddingBumblebee do
  @moduledoc """
  EmbeddingBumblebee module provides functionality for embedding text.
  """
  alias LangChain.Config

  defstruct [:model]

  @dim 1536

  def new(opts \\ []) do
    {:ok, %__MODULE__{model: Keyword.get(opts, :model, "text-embedding-3-small")}}
  end

  def embed_documents(embedding_model, documents) do
  end

  def embed_query(embedding_model, query) do
  end

  def dimension() do
    @dim
  end

  defp do_api_request(embedding_model, document) do
  end
end
