defmodule LangChain.Embeddings.VertexAIEmbeddings do
  require Logger

  def new(opts \\ []) do
    # Initialize the Vertex AI embeddings with options, if any
    {:ok, "Vertex AI Embeddings initialized with options: #{inspect(opts)}"}
  end

  def embedQuery(_query) do
    # do_api_request()
  end

  def get_api_key() do
    # Retrieve the API key from the application environment or configuration
    Application.get_env(:socks, :vertex_ai_api_key)
  end

  # "https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${MODEL_ID}:predict",
  def embedDocuments(documents) do
    _url = nil

    do_api_request(documents)
  end

  defp do_api_request(documents) do
    Req.new(
      url:
        "https://us-central1-aiplatform.googleapis.com/v1/projects/your-project-id/locations/us-central1/publishers/google/models/textembedding-gecko:predict",
      json:
        Jason.encode!(%{
          instances:
            documents
            |> Enum.map(fn doc ->
              %{title: doc.title, content: doc.content, task_type: "RETRIEVAL_DOCUMENT"}
            end),
          parameters: %{}
        }),
      auth: {:bearer, get_api_key()}
    )
    |> Req.post()
    |> case do
      {:ok, %Req.Response{body: data}} ->
        dbg(data)
        {:ok, data}

      {:error, %Req.TransportError{reason: :timeout} = err} ->
        {:error,
         "Request timed out. Please check your network connection or try again later. Error: #{inspect(err)}"}

      other ->
        Logger.error("Unexpected and unhandled API response! #{inspect(other)}")
        other
    end
  end
end
