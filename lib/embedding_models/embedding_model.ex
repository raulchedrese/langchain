defmodule LangChain.EmbeddingModels.EmbeddingModel do
  @type t :: __MODULE__.t()

  @callback embed_documents(
              embedding_model :: EmbeddingModels.EmbeddingModel.t(),
              documents :: [String.t()]
            ) :: {:ok, [[float()]]} | {:error, String.t()}
  @callback embed_query(
              embedding_model :: EmbeddingModels.EmbeddingModel.t(),
              query :: String.t()
            ) :: {:ok, [float()]} | {:error, String.t()}
end
