defmodule LangChain.Embeddings.OpenAIEmbeddings do
  @moduledoc """
  OpenAIEmbeddings module provides functionality for embedding text.
  """
  alias LangChain.Config

  def embed_documents(documents) do
    Nx.tensor(Enum.map(documents, fn doc -> call_openai_api(doc.content) end))
  end

  def embed_query(query) do
    Nx.tensor(call_openai_api(query))
  end

  defp call_openai_api(document) do
    {:ok, embeddings} =
      Req.new(
        url: "https://api.openai.com/v1/embeddings",
        method: :post,
        auth: {:bearer, Config.resolve(:openai_key, "")},
        json: %{"input" => document, "model" => "text-embedding-3-small"}
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
