defmodule LangChain.VectorStores.HNSWVectorStore do
  alias LangChain.Embeddings.OpenAIEmbeddings
  defstruct [:index, :embeddings_model, :documents, :current_id]

  def new(embeddings_model \\ OpenAIEmbeddings) do
    space = :l2
    dim = 1536
    max_elements = 10000
    {:ok, index} = HNSWLib.Index.new(space, dim, max_elements)
    %__MODULE__{index: index, embeddings_model: embeddings_model, documents: %{}, current_id: 0}
  end

  def add_documents(store, documents) do
    embeddings = store.embeddings_model.embed_documents(documents)
    next_id = store.current_id + Enum.count(documents)
    ids = Enum.to_list(store.current_id..(store.current_id + Enum.count(documents) - 1))

    HNSWLib.Index.add_items(store.index, embeddings, ids: ids)

    new_documents =
      ids
      |> Enum.with_index()
      |> Enum.into(%{}, fn {id, index} -> {id, Enum.at(documents, index)} end)

    %{store | documents: Map.merge(store.documents, new_documents), current_id: next_id}
  end

  def similarity_search(store, query, k \\ 4) do
    query = store.embeddings_model.embed_query([query])
    {:ok, labels, _dists} = HNSWLib.Index.knn_query(store.index, query, k: k)

    labels
    |> Nx.to_flat_list()
    |> Enum.map(fn label -> Map.fetch!(store.documents, label) end)
  end
end
