defmodule LangChain.VectorStores.VectorStore do
  @type t :: __MODULE__.t()

  @callback new(embedding_model :: LangChain.EmbeddingModels.EmbeddingModel.t()) :: __MODULE__.t()
  @callback add_documents(store :: __MODULE__.t(), documents :: [LangChain.Document.t()]) ::
              __MODULE__.t()
  @callback similarity_search(
              store :: __MODULE__.t(),
              query :: String.t(),
              k :: non_neg_integer()
            ) :: [
              LangChain.Document.t()
            ]
end
