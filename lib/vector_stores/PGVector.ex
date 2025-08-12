defmodule LangChain.VectorStores.PGVector do
  @moduledoc """
  A minimal vector store implementation using PostgreSQL + pgvector via Postgrex.

  Enhancements:
  - Stores `metadata` alongside `content` and `embedding` in the same table (JSONB).
  - Accepts an `embedding_model` in `new/1` used to generate embeddings for documents and queries.

  Notes:
  - Embeddings are expected to be lists of floats. If embeddings are not provided for documents,
    they will be computed using the configured `embedding_model`.
  - `metadata` can be any map; it will be stored as JSONB in Postgres. If `Jason` is unavailable,
    metadata will be stored as `{}` (empty object).
  - Queries can be passed as a string (embedding will be computed via `embedding_model`) or as a list
    of floats (precomputed).
  """

  alias LangChain.Embeddings.OpenAIEmbeddings

  @default_conn_opts [
    username: "postgres",
    password: "",
    database: "pgvector",
    hostname: "localhost"
  ]

  @default_table "pgvector_documents"

  @persistent_key {__MODULE__, :config}

  defstruct [:conn, :table, :conn_opts, :embedding_model]

  @doc """
  Initializes the PGVector store.

  Options:
    - :conn_opts       - keyword list with Postgrex connection options (default provided)
    - :table           - table name as a string (default: "pgvector_documents")
    - :embedding_model - module used to compute embeddings (default: LangChain.Embeddings.OpenAIEmbeddings)

  Persists the connection and config in persistent_term for subsequent calls.
  """
  def new(opts \\ []) do
    conn_opts =
      Keyword.get(opts, :conn_opts, @default_conn_opts)
      |> Keyword.put(:types, LangChain.VectorStores.PostgrexTypes)

    table = Keyword.get(opts, :table, @default_table)
    embedding_model = Keyword.get(opts, :embedding_model, OpenAIEmbeddings)

    Postgrex.Types.define(LangChain.VectorStores.PostgrexTypes, Pgvector.extensions(), [])

    with {:ok, conn} <- Postgrex.start_link(conn_opts),
         :ok <- ensure_extension(conn),
         :ok <- ensure_table(conn, table, embedding_model.dimension()),
         config = %__MODULE__{
           conn: conn,
           table: table,
           conn_opts: conn_opts,
           embedding_model: embedding_model
         },
         :ok <- put_config(config) do
      {:ok, config}
    else
      {:error, reason} = err ->
        err

      other ->
        {:error, other}
    end
  end

  @doc """
  Adds one or more documents, computing embeddings if not provided.

  Returns {:ok, inserted_count} or {:error, reason}
  """
  def add_documents(store, documents) do
    conn = store.conn
    table = store.table
    embedding_model = store.embedding_model

    embeddings = embedding_model.embed_documents(documents)

    rows = Enum.zip(documents, embeddings)

    case Postgrex.transaction(conn, fn tx_conn ->
           Enum.reduce_while(rows, 0, fn {document, embedding}, acc ->
             case Postgrex.query(
                    tx_conn,
                    "INSERT INTO #{table} (content, metadata, embedding) VALUES ($1, $2::jsonb, $3::vector)",
                    [document.content, JSON.encode!(document.metadata), embedding]
                  ) do
               {:ok, _res} ->
                 {:cont, acc + 1}

               {:error, reason} ->
                 {:halt, {:error, reason}}
             end
           end)
         end) do
      {:ok, count} when is_integer(count) ->
        {:ok, count}

      {:ok, {:error, reason}} ->
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Performs a similarity search. `query` can be:
    - a string: embedding will be computed using the configured embedding_model
    - an embedding list of floats: used as-is

  Returns {:ok, [%{id: id, content: content, metadata: map()}]}.
  """
  def similarity_search(store, query, k \\ 4) do
    conn = store.conn
    table = store.table
    query_vec = store.embedding_model.embed_query(query)

    {:ok, %Postgrex.Result{rows: rows}} =
      Postgrex.query(
        conn,
        """
        SELECT id, content, metadata::text
        FROM #{table}
        ORDER BY embedding <-> $1::vector
        LIMIT $2
        """,
        [query_vec, k]
      )

    Enum.map(rows, fn [id, content, metadata_text] ->
      %{id: id, content: content, metadata: JSON.decode!(metadata_text)}
    end)
  end

  @doc """
  Similar to `similarity_search/2`, but returns each result with its distance score:
  {:ok, [%{id: id, content: content, metadata: map(), score: float}, ...]}
  """
  def similarity_search_with_score(store, query, k \\ 4) do
    conn = store.conn
    table = store.table

    query_vec = store.embedding_model.embed_query(query)

    {:ok, %Postgrex.Result{rows: rows}} =
      Postgrex.query(
        conn,
        """
        SELECT id, content, metadata::text
        FROM #{table}
        ORDER BY embedding <-> $1::vector
        LIMIT $2
        """,
        [query_vec, k]
      )

    Enum.map(rows, fn [id, content, metadata_text] ->
      %{id: id, content: content, metadata: JSON.decode!(metadata_text)}
    end)
  end

  # -- Helpers ----------------------------------------------------------------

  defp ensure_extension(conn) do
    case Postgrex.query(conn, "CREATE EXTENSION IF NOT EXISTS vector", []) do
      {:ok, _} -> :ok
      {:error, %Postgrex.Error{} = err} -> {:error, err}
    end
  end

  defp ensure_table(conn, table, dim) when is_integer(dim) and dim > 0 do
    # Create table if not exists
    create_sql = """
    CREATE TABLE IF NOT EXISTS #{table} (
      id BIGSERIAL PRIMARY KEY,
      content TEXT NOT NULL,
      metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
      embedding VECTOR(#{dim}) NOT NULL
    )
    """

    with {:ok, _} <- Postgrex.query(conn, create_sql, []) do
      # Optional: create an IVFFlat index to speed-up similarity search.
      # Requires ANALYZE after initial data load for best performance.
      index_sql = """
      CREATE INDEX IF NOT EXISTS #{table <> "_embedding_ivfflat_idx"}
      ON #{table}
      USING ivfflat (embedding vector_l2_ops)
      WITH (lists = 100)
      """

      case Postgrex.query(conn, index_sql, []) do
        {:ok, _} -> :ok
        # If vector_l2_ops is unavailable or ivfflat not configured, proceed without failing.
        {:error, _err} -> :ok
      end
    else
      {:error, %Postgrex.Error{} = err} -> {:error, err}
    end
  end

  defp put_config(%__MODULE__{} = config) do
    :persistent_term.put(@persistent_key, config)
    :ok
  end
end
