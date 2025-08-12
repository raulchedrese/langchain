defmodule LangChain.Embeddings.VertexAIEmbeddings do
  def new(opts \\ []) do
    # Initialize the Vertex AI embeddings with options, if any
    {:ok, "Vertex AI Embeddings initialized with options: #{inspect(opts)}"}
  end

  def embedQuery() do
  end

  def get_api_key() do
    # Retrieve the API key from the application environment or configuration
    Application.get_env(:socks, :vertex_ai_api_key)
  end

  # "https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${MODEL_ID}:predict",
  def embedDocuments() do
    url = nil
    req =
      Req.new(
        url:
          url,
        json:
          Jason.encode!(%{
            instances: [
              %{
                title: "Test Document",
                content: "This is a test document for embedding.",
                task_type: "RETRIEVAL_DOCUMENT"
              }
            ],
            parameters: %{}
          }),
        auth: {:bearer, get_api_key()}
      )

    req
    |> Req.post()
    |> case do
      {:ok, %Req.Response{body: data}} ->
        dbg(data)

      {:error, %Req.TransportError{reason: :timeout} = err} ->
        {:error,
         "Request timed out. Please check your network connection or try again later. Error: #{inspect(err)}"}

        # other ->
        #   Logger.error("Unexpected and unhandled API response! #{inspect(other)}")
        #   other
    end
  end
end
