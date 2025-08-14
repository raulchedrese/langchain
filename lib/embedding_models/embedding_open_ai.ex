defmodule LangChain.EmbeddingModels.EmbeddingOpenAI do
  @moduledoc """
  EmbeddingOpenAI module provides functionality for embedding text.
  """
  alias LangChain.Config

  defstruct [:model]

  @dim 1536

  def new(model \\ "text-embedding-3-small") do
    {:ok, %__MODULE__{model: model}}
  end

  def embed_documents(embedding_model, documents) do
    Enum.map(documents, fn doc -> do_api_request(embedding_model, doc.content) end)
  end

  def embed_query(embedding_model, query) do
    do_api_request(embedding_model, query)
  end

  def dimension() do
    @dim
  end

  defp do_api_request(embedding_model, document) do
    {:ok, embeddings} =
      Req.new(
        url: "https://api.openai.com/v1/embeddings",
        method: :post,
        auth: {:bearer, Config.resolve(:openai_key, "")},
        json: %{"input" => document, "model" => embedding_model.model}
      )
      |> Req.post()
      |> case do
        {:ok, response} ->
          {:ok, response.body["data"] |> Enum.map(& &1["embedding"])}

        {:error, error} ->
          {:error, error}
      end

    Enum.at(embeddings, 0)
  end
end
